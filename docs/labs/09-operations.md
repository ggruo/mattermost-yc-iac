# 9. Helm, диагностика, HPA, PVC и восстановление

## Цель и подготовка

Нужен стенд занятия 7; для внешней проверки также занятие 8.
Если всё удалено, сначала повторите их. Схема: Helm → Deployment;
Monitoring/логи → диагностика; backup → отдельный восстановленный кластер.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

3 часа плюс восстановление. Дополнительно временный PVC-диск и второй PG
кластер на время restore. Рассчитайте их отдельно и удалите сразу после проверки.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

1. Monitoring: откройте CPU/RAM worker и соединения/ресурсы PostgreSQL,
   сравните спокойное состояние и короткую нагрузку.
2. Cloud Logging → создать log group `notes-access` с хранением 1 день.
   Для создания оператору нужна `logging.editor`, для чтения — `logging.reader`.
   Запишите ID: ниже включаем access logs через Gwin, не правкой ALB вручную.
3. PostgreSQL → исходный кластер → Backups: создайте backup через CLI ниже,
   дождитесь его появления. Restore выполните в **новый** кластер `notes-restore`,
   один host, та же сеть/subnet и SG БД, public access выключен.
   Исходный кластер не удалять до проверки восстановленных данных.

## В терминале

Сначала перенесите управление Deployment и ClusterIP Service в Helm. ConfigMap,
Secret, CA и Job остаются внешними; ALB NodePort/Gateway не меняются.
В этом учебном переходе допустим короткий перерыв доступности:

```bash
export IMAGE="$(cat .local/image.txt)"
printf 'image: "%s"\n' "$IMAGE" > .local/notes-values.yaml
helm lint charts/notes -f .local/notes-values.yaml
helm template notes charts/notes -n notes -f .local/notes-values.yaml > .local/helm-rendered.yaml
kubectl -n notes delete deployment notes
kubectl -n notes delete service notes
helm upgrade --install notes charts/notes -n notes -f .local/notes-values.yaml --wait --timeout 3m
helm upgrade notes charts/notes -n notes -f .local/notes-values.yaml --set replicas=2 --wait
helm history notes -n notes
helm rollback notes 1 -n notes --wait
kubectl -n notes get pods
```

После этого **не применяйте** старые base/deployment и base/service: ими управляет
Helm. Upgrade меняет replicas для понятной демонстрации, rollback возвращает 1.

### HPA

```bash
kubectl top nodes
kubectl -n notes top pods
kubectl apply -f kubernetes/exercises/hpa.yaml
kubectl -n notes get hpa -w
```

Если Metrics API недоступен, проверьте metrics-server в kube-system и его события;
без метрик упражнение не может считаться выполненным. Остановите watch.
Создайте короткую нагрузку из отдельного Pod (удалите после 1–2 минут):

```bash
kubectl -n notes run load --image=busybox:1.37.0 --restart=Never -- sh -c 'while true; do wget -q -O /dev/null http://notes/healthz; done'
kubectl -n notes get hpa
kubectl -n notes top pods
kubectl -n notes delete pod load
kubectl -n notes delete -f kubernetes/exercises/hpa.yaml
kubectl -n notes scale deployment notes --replicas=1
```

HPA ориентируется на CPU относительно requests. Один цикл может не пересечь порог:
это нормальное наблюдение, а не обещание обязательного масштабирования. Для
демонстрации в локальной копии hpa.yaml временно снизьте порог до 5%, повторите
нагрузку и дождитесь метрик. HPA масштабирует Pods, не число worker VM.
Во время упражнения не выполняйте Helm upgrade, задающий replicas.

### PVC

```bash
kubectl get storageclass yc-network-hdd -o yaml
kubectl apply -f kubernetes/exercises/pvc.yaml
kubectl -n notes wait --for=condition=Ready pod/scratch --timeout=180s
kubectl -n notes exec scratch -- sh -c 'echo persistent > /data/proof'
kubectl -n notes delete pod scratch
kubectl apply -f kubernetes/exercises/pvc.yaml
kubectl -n notes wait --for=condition=Ready pod/scratch --timeout=180s
kubectl -n notes exec scratch -- cat /data/proof
kubectl -n notes delete -f kubernetes/exercises/pvc.yaml
kubectl get pv
```

Ожидается `persistent`. Проверяйте reclaimPolicy и реальное удаление диска в UI.
Это отдельный опыт: приложение notes хранит данные в managed БД, не в PVC.

### Cloud Logging

При работающем ALB из занятия 8:

```bash
export LOG_GROUP_ID=REPLACE_LOG_GROUP_ID
kubectl -n notes annotate gateway notes "gwin.yandex.cloud/logs.logGroupID=$LOG_GROUP_ID" 'gwin.yandex.cloud/logs.disable=false' --overwrite
curl -fsS "https://$APP_FQDN/healthz"
```

Подождите доставку логов, откройте Cloud Logging → notes-access и найдите запрос
по времени, hostname/path и HTTP-коду. Сравните access log ALB с
`kubectl -n notes logs deployment/notes`: они описывают разные участки запроса.
`logging.writer` уже назначена Gwin через IaC. Если заново рендерите Gateway,
добавьте эти аннотации и в локальный YAML, чтобы не потерять настройку.
После удаления ALB удалите log group в UI.
[Аннотации Gateway](https://yandex.cloud/en/docs/application-load-balancer/gwin-ref/gateway).

### Backup и restore

Создайте заметку-маркер через HTTPS либо port-forward из занятия 7.
Запомните её id и текст. Затем:

```bash
export DB_ID="$(tofu -chdir=terraform/kubernetes output -raw postgres_cluster_id)"
yc managed-postgresql cluster backup "$DB_ID"
```

Дождитесь backup в UI и восстановите отдельный кластер, как описано выше.
Проверяйте его **из существующего Pod**, не меняя конфигурацию рабочего приложения:

```bash
export RESTORED_HOST=REPLACE_RESTORED_MASTER_FQDN
kubectl -n notes exec deployment/notes -- env PGHOST="$RESTORED_HOST" python -c 'from notes import db; c=db.connect(); print(c.execute("SELECT id, text FROM notes ORDER BY id DESC LIMIT 5").fetchall()); c.close()'
```

Пароль исходной БД уже в окружении Pod, в команду он не попадает. Убедитесь,
что маркер присутствует, удалите restore-кластер в UI. Это проверка восстановления,
а не просто факт существования backup.

### Диагностика

```bash
kubectl -n notes get endpoints notes
kubectl -n notes describe deployment notes
kubectl -n notes logs deployment/notes --tail=30
kubectl -n notes get events --sort-by=.metadata.creationTimestamp
```

Для ошибки БД временно задайте несуществующего пользователя:

```bash
kubectl -n notes set env deployment/notes PGUSER=wrong-user
kubectl -n notes get pods
```

Новый Pod не станет Ready. Старый Pod может продолжить работу благодаря rolling
update — внешний 503 не гарантирован. Изучите probes/logs, затем восстановите
Helm-конфигурацию:

```bash
kubectl -n notes set env deployment/notes PGUSER-
helm upgrade notes charts/notes -n notes -f .local/notes-values.yaml --wait
```

Отдельно отработайте неправильный Secret. Правильный пароль остаётся в
`.local/notes-db.env`; не перезаписывайте этот файл:

```bash
printf 'PGPASSWORD=deliberately-wrong\n' > .local/wrong-db.env
kubectl -n notes create secret generic notes-db --from-env-file=.local/wrong-db.env --dry-run=client -o yaml | kubectl apply -f -
kubectl -n notes rollout restart deployment/notes
kubectl -n notes get pods
kubectl -n notes describe deployment notes
```

После наблюдения верните Secret и перезапустите Pods, чтобы перечитать env:

```bash
kubectl -n notes create secret generic notes-db --from-env-file=.local/notes-db.env --dry-run=client -o yaml | kubectl apply -f -
kubectl -n notes rollout restart deployment/notes
kubectl -n notes rollout status deployment/notes --timeout=180s
```

Удаление SG-правила 6432 в UI даёт сетевой timeout. Изучите readiness, затем
восстановите правило через `tofu -chdir=terraform/kubernetes plan` и `apply`.

## В коде

Chart содержит только Deployment/Service и values image/replicas/resources.
Сравните `helm template` с base-манифестами: probes и mounts должны совпадать.
Secret/CA не включены в chart и не теряются при смене релиза.
HPA и PVC — отдельные упражнения, не обязательные production-компоненты.

## Проверка, поломка и вопросы

Итоговое задание: с чистого folder повторить стенд по ранбукам, объяснить каждый
переход HTTPS→ALB→Service→Pod→БД, найти одну внесённую ошибку и восстановить backup.
Заполните [лист приёмки](../acceptance.md): проверки, результат, время и расходы.
Объясните отличие readiness/liveness, backup/HA, Service/Ingress/Gateway, IAM/RBAC.

## Очистка и продолжение

Выполните **все** разделы [очистки](../cleanup.md), включая restore-кластер,
PVC, Registry, сертификат, DNS A-запись и ключ Gwin. Проверьте Billing после
обновления начислений. Дальше — [необязательные темы](../next.md).
