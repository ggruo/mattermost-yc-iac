# Очистка: выполнять после каждого занятия

Все команды ниже — из корня репозитория, профиль `yc` должен указывать на
**учебный folder**. Сначала `yc config get folder-id`. Не удаляйте ресурсы
других проектов. Имена `manual-*` и `notes-*` помогают найти учебные объекты.

## VM

```bash
tofu -chdir=terraform/vm plan -destroy
tofu -chdir=terraform/vm destroy
```

Подтвердите именно VM-стенд. Удаляются VM, отдельный IP, boot disk, БД, A-запись,
SG и сеть. Пароль переменной потребуется снова; не удаляйте state до destroy.
DNS zone создана вручную и остаётся для следующих лабораторных.

## Kubernetes: порядок важен

Если кластер уже удалён, не выполняйте kubectl по другому контексту:
сразу переходите к проверке оставшихся ресурсов в UI.
Иначе проверьте `kubectl config current-context` и выполните:

```bash
kubectl -n notes delete httproute notes notes-redirect --ignore-not-found
kubectl -n notes delete gateway notes --ignore-not-found --timeout=5m
kubectl -n notes delete service notes-public --ignore-not-found --timeout=5m
```

**До удаления контроллера и кластера** откройте ALB и NLB в UI: учебные
балансировщики и их дочерние target/backend groups должны исчезнуть.
При зависшем удалении смотрите `kubectl -n gwin-system get pods` и логи
контроллера; не снимайте finalizers принудительно. Исправьте IAM/работу Gwin
и дождитесь удаления. Факт удаления Gateway ещё не заменяет проверку UI.

```bash
kubectl -n notes delete -f kubernetes/exercises/pvc.yaml --ignore-not-found
kubectl get pv
helm list -A
```

Убедитесь, что диск упражнения удалён согласно reclaimPolicy StorageClass.
Если релизы существуют, удалите `helm uninstall notes -n notes` и затем
`helm uninstall gwin -n gwin-system`. При отсутствии релиза этот шаг пропустите.

```bash
kubectl delete namespace notes --ignore-not-found
tofu -chdir=terraform/kubernetes plan -destroy
tofu -chdir=terraform/kubernetes destroy
```

## Ручные ресурсы и остатки

В UI учебного folder проверьте Compute (VM, диски, snapshots, образы), VPC (IP,
NAT gateway), PostgreSQL (включая restore-кластер), ALB/NLB и Registry.
Восстановленный кластер удаляется отдельно: его нет в исходном state.
После последнего занятия удалите образы Registry и пустой registry, сертификат,
ручные DNS-записи, ненужные log groups и тестовые service accounts/ключи.
DNS zone можно оставить, если хотите сохранить делегирование домена; иначе
удалите делегирование у регистратора и затем зону. Закройте бюджетные уведомления
только после проверки биллинга: начисления могут отображаться с задержкой.

Локальные секреты удаляйте после завершения всех destroy и отзыва ключей:
удалите конкретные файлы `.local/notes-db.env`, `.local/sa-key.json`,
`.local/kubeconfig`, Vault и реальные tfvars, если они больше не нужны.
`unset TF_VAR_postgres_password YC_TOKEN` убирает секреты из текущего shell.
Не заменяйте очистку простым выключением VM/кластера: диски/IP/LB могут остаться платными.
