# 7. Managed Kubernetes и первое приложение

## Цель и подготовка

Нужны образ из занятия 6 и IAM из занятия 1. При новом занятии экспортируйте
IAC_SA_ID и обновите YC_TOKEN. Схема: kubectl → API; private worker → NAT → registry;
Pod → Managed PostgreSQL. VM-стенд должен быть удалён.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2–3 часа плюс создание: master, worker 4 CPU/8 GB/30 GB, PG 2 CPU/8 GB/20 GB,
API public IP и NAT. Бюджет считайте на весь период от apply до destroy.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

Проверьте квоты и смету. После apply откройте Managed Kubernetes: master,
node group, операции. У worker должен быть private IP без публичного.
PostgreSQL также приватный. Отдельно посмотрите три cloud service account и роли.

## В терминале

```bash
cp terraform/kubernetes/terraform.tfvars.example terraform/kubernetes/terraform.tfvars
yc managed-kubernetes list-versions
```

В редакторе задайте folder_id, свой trusted_cidrs и **поддерживаемую** версию
Kubernetes из вывода. Она фиксируется в локальном tfvars для master и worker;
устаревший номер из чужой инструкции не используйте.

```bash
export IAC_SA_ID=REPLACE_SERVICE_ACCOUNT_ID
read -rsp 'PostgreSQL password: ' TF_VAR_postgres_password
printf '\n'
export TF_VAR_postgres_password
export YC_TOKEN="$(yc iam create-token --impersonate-service-account-id "$IAC_SA_ID")"
tofu -chdir=terraform/kubernetes init
tofu -chdir=terraform/kubernetes validate
tofu -chdir=terraform/kubernetes plan
tofu -chdir=terraform/kubernetes apply
export CLUSTER_ID="$(tofu -chdir=terraform/kubernetes output -raw cluster_id)"
export KUBECONFIG="$PWD/.local/kubeconfig"
yc managed-kubernetes cluster get-credentials "$CLUSTER_ID" --external --force
kubectl config current-context
kubectl get nodes -o wide
kubectl apply -f kubernetes/base/namespace.yaml
```

Ожидается Ready. Публичный API ограничен вашим CIDR; для API через private IP
нужен VPN/bastion/маршрут, его в обязательном стенде нет.
Создайте конфигурацию и Secret (пароль не включён в командную строку):

```bash
export PGHOST="$(tofu -chdir=terraform/kubernetes output -raw postgres_host)"
export IMAGE="$(cat .local/image.txt)"
curl -fsSL https://storage.yandexcloud.net/cloud-certs/CA.pem -o .local/ca.pem
python3 tools/render.py kubernetes/base/configmap.yaml.example > .local/configmap.yaml
kubectl apply -f .local/configmap.yaml
kubectl -n notes create configmap postgres-ca --from-file=ca.pem=.local/ca.pem --dry-run=client -o yaml | kubectl apply -f -
python3 - <<'ENV'
import os
from pathlib import Path
password = os.environ['TF_VAR_postgres_password']
if '\n' in password or '\r' in password:
    raise SystemExit('Use a single-line learning password')
p = Path('.local/notes-db.env')
p.write_text('PGPASSWORD=' + password + '\n')
p.chmod(0o600)
ENV
kubectl -n notes create secret generic notes-db --from-env-file=.local/notes-db.env --dry-run=client -o yaml | kubectl apply -f -
python3 tools/render.py kubernetes/base/init-job.yaml.example > .local/init-job.yaml
kubectl -n notes delete job notes-init --ignore-not-found
kubectl apply -f .local/init-job.yaml
kubectl -n notes wait --for=condition=complete job/notes-init --timeout=120s
python3 tools/render.py kubernetes/base/deployment.yaml.example > .local/deployment.yaml
kubectl apply -f .local/deployment.yaml
kubectl apply -f kubernetes/base/service.yaml
kubectl -n notes rollout status deployment/notes --timeout=180s
kubectl -n notes port-forward service/notes 8080:80
```

Последняя команда работает до Ctrl-C. Во втором терминале:

```bash
curl -fsS http://127.0.0.1:8080/readyz
curl -fsS http://127.0.0.1:8080/notes -H 'Content-Type: application/json' -d '{"text":"hello from Kubernetes"}'
curl -fsS http://127.0.0.1:8080/notes
```

При повторении init Job сначала удаляется; схема повторяемая.
`tools/render.py` только подставляет экспортированные не-секретные значения и
останавливается при отсутствующей переменной. Он ничего не создаёт в облаке.

## В коде

Прочитайте Deployment/Service/ConfigMap/Job. Secret создаётся отдельно, а CA
монтируется read-only. Deployment управляет числом Pods, Service находит Pods
по labels, readiness исключает неготовые Pods из endpoints. Cloud IAM определяет
возможности облачных аккаунтов, Kubernetes RBAC — возможности kubectl и Pods.

## Проверка, поломка и вопросы

```bash
kubectl -n notes get pods
kubectl -n notes delete pod -l app=notes
kubectl -n notes get pods -w
```

Дождитесь нового Ready Pod и остановите watch Ctrl-C. Port-forward после удаления
Pod нужно запустить заново. Запись должна остаться в БД.
Для Pending смотрите `kubectl -n notes describe pod REPLACE_POD_NAME`;
для ImagePullBackOff — digest и роль node service account;
для 503 — Secret, CA, FQDN, SG, выполненный schema Job.
Не публикуйте содержимое Secret в логах/скриншотах.

## Очистка и продолжение

Сразу продолжайте [внешним доступом](08-exposure.md) в рамках оплаченной сессии
или выполните Kubernetes-раздел [очистки](../cleanup.md).
После удаления повторите это занятие для восстановления стенда.
