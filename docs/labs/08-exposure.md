# 8. Внешний доступ: NLB, ALB и HTTPS

## Цель и подготовка

Нужен Ready Deployment из занятия 7. Сначала L4 NLB, затем L7 ALB;
одновременно держать оба не требуется. HTTPS завершается на ALB, трафик внутри
VPC до приложения идёт по HTTP.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2–3 часа: текущий Kubernetes/PG плюс сначала NLB, затем ALB с public IP.
ALB имеет собственную тарификацию ёмкости; проверьте минимальную стоимость.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

1. После Service LoadBalancer посмотрите созданный NLB и target group.
   Не редактируйте их вручную — владелец cloud controller.
2. Certificate Manager → запросить Let's Encrypt-сертификат для
   `k8s.lab.<домен>` с DNS-проверкой. Добавьте предложенные записи в Cloud DNS,
   дождитесь статуса Issued, запишите certificate ID. Это ручной ресурс курса.
3. После Gateway посмотрите ALB listener 80/443, HTTP router, backend group,
   target group и health checks. Свяжите их с Gateway/HTTPRoute/Service.
4. После появления ALB IP создайте A-запись `k8s.lab.<домен>` в Cloud DNS.
   Она ручная: Kubernetes Terraform не управляет динамическим IP ALB.

## В терминале

Если открыли новый терминал, восстановите `KUBECONFIG=$PWD/.local/kubeconfig`.
В локальном `terraform/kubernetes/terraform.tfvars` поставьте `enable_nlb=true`:

```bash
tofu -chdir=terraform/kubernetes plan
tofu -chdir=terraform/kubernetes apply
kubectl apply -f kubernetes/exposure/nlb.yaml
kubectl -n notes get service notes-public -w
```

После назначения EXTERNAL-IP остановите watch, затем:

```bash
export NLB_IP="$(kubectl -n notes get service notes-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
curl -fsS "http://$NLB_IP/readyz"
kubectl -n notes delete service notes-public --timeout=5m
```

В UI дождитесь удаления NLB и target group. Верните `enable_nlb=false` и выполните
plan/apply. Теперь установите Gwin **закреплённой версии v1.10.0**:

```bash
export GWIN_SA_ID="$(tofu -chdir=terraform/kubernetes output -raw gwin_service_account_id)"
export FOLDER_ID="$(yc config get folder-id)"
yc iam key create --service-account-id "$GWIN_SA_ID" --output .local/sa-key.json
chmod 600 .local/sa-key.json
helm upgrade --install gwin oci://cr.yandex/yc-marketplace/yandex-cloud/gwin/charts/gwin-chart --version v1.10.0 -f kubernetes/gwin-values.yaml --namespace gwin-system --create-namespace --set controller.folderId="$FOLDER_ID" --set-file controller.ycServiceAccount.secret.value=.local/sa-key.json --wait --timeout 5m
kubectl -n gwin-system rollout status deployment/gwin --timeout=180s
kubectl -n gwin-system get pods
kubectl get gatewayclass
```

Не создавайте новый авторизованный ключ при каждом повторе, если локальный ключ
ещё существует и действителен. Ключ попадает в Secret/данные Helm release;
доступ к этому namespace должен быть только у администратора.
Далее подставьте не-секретные значения:

```bash
export CERTIFICATE_ID=REPLACE_ISSUED_CERTIFICATE_ID
export APP_FQDN=k8s.lab.REPLACE_DOMAIN
export ALB_SECURITY_GROUP_ID="$(tofu -chdir=terraform/kubernetes output -raw alb_security_group_id)"
export SUBNET_ID="$(tofu -chdir=terraform/kubernetes output -raw subnet_id)"
python3 tools/render.py kubernetes/exposure/gateway.yaml.example > .local/gateway.yaml
kubectl apply -f kubernetes/exposure/nodeport.yaml
kubectl apply -f .local/gateway.yaml
kubectl -n notes get gateway notes -w
```

После появления ADDRESS и готовых условий остановите watch и создайте DNS A
в UI. Проверьте:

```bash
export ALB_IP="$(kubectl -n notes get gateway notes -o jsonpath='{.status.addresses[0].value}')"
curl --resolve "$APP_FQDN:443:$ALB_IP" -fsS "https://$APP_FQDN/readyz"
curl -I "http://$APP_FQDN/healthz"
curl -fsS "https://$APP_FQDN/notes"
```

`--resolve` проверяет TLS до распространения A-записи, сохраняя hostname/SNI.
HTTP должен перенаправляться на HTTPS. Не используйте `curl -k`.
[Установка Gwin](https://yandex.cloud/en/docs/application-load-balancer/tools/gwin/quickstart).

## В коде

Сравните `nlb.yaml`, `nodeport.yaml` и `gateway.yaml.example`.
NLB понимает TCP; Gateway задаёт listeners/TLS, HTTPRoute — host/path/redirect.
Ingress объединяет HTTP-маршруты в другой API; без контроллера оба API не создают
работающий прокси. Chart Gwin содержит контроллер/CRD, ваш chart notes — приложение.
ALB ресурсы не дублируются в Terraform.

## Проверка, поломка и вопросы

В `.local/gateway.yaml` временно замените backend port 80 на 81 и примените.
Изучите `kubectl -n notes describe httproute notes`: ищите ResolvedRefs/Accepted,
а в ALB — состояние backend. Верните 80 и примените.
Если TLS не работает: Issued, hostname, YCCertificate и роль downloader.
Если backend нездоров: NodePort, readiness, SG 30080/30501, endpoints.
Не удаляйте finalizers и не пересоздавайте весь кластер для диагностики.

## Очистка и продолжение

Для немедленного занятия 9 оставьте ALB только на эту сессию. Иначе строго
[общая очистка](../cleanup.md): Gateway/NLB → проверка исчезновения LB →
Helm/controller → кластер. Сертификат и ручная A-запись удаляются отдельно.
Далее [Helm и эксплуатация](09-operations.md).
