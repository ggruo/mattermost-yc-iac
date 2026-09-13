# 1. IAM и service accounts

## Цель и подготовка

Завершите занятие 0. Схема: личный пользователь → impersonation → service account
IaC → ресурсы folder. Аутентификация отвечает «кто», авторизация — «что разрешено».

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2 часа, вычислительные ресурсы не создаём.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

1. IAM → Service accounts: создайте `course-iac`.
2. Назначьте ему в учебном folder роли `compute.editor`, `vpc.admin`,
   `managed-postgresql.editor`, `dns.editor`, `iam.serviceAccounts.user`.
   Это учебные роли по сервисам, а не общий `admin`; некоторые разрешения шире
   отдельных действий, production IAM требует дальнейшего сужения.
3. Личному пользователю на этом service account назначьте
   `iam.serviceAccounts.tokenCreator` для impersonation.
4. Для Kubernetes-стенда позже добавьте IaC-аккаунту `k8s.editor`,
   `iam.serviceAccounts.admin`, `resource-manager.admin`: код создаёт аккаунты
   cluster/node/Gwin и назначения ролей folder. Последняя роль даёт широкое
   управление доступом — допустима здесь только в отдельном учебном folder.
   Личному оператору kubectl нужны `k8s.cluster-api.cluster-admin` и
   `k8s.clusters.viewer` в учебном folder.
5. Registry push выполняется личным оператором с
   `container-registry.images.pusher`; создание registry требует
   `container-registry.editor`. DNS/Certificate Manager в UI также выполняет
   личный пользователь с соответствующими editor-ролями.

## В терминале

```bash
export YC_FOLDER_ID="$(yc config get folder-id)"
export YC_CLOUD_ID="$(yc config get cloud-id)"
export IAC_SA_ID=REPLACE_SERVICE_ACCOUNT_ID
export YC_TOKEN="$(yc iam create-token --impersonate-service-account-id "$IAC_SA_ID")"
yc compute instance list --impersonate-service-account-id "$IAC_SA_ID"
```

`YC_TOKEN` использует provider OpenTofu; это краткоживущий токен. После истечения
повторите команду выдачи. Не печатайте токен и не сохраняйте его в tfvars.
Личный профиль `yc` оставьте личным: kubeconfig использует его для получения токена.

## В коде

В `terraform/kubernetes/iam.tf` сравните три служебных аккаунта.
Cluster создаёт инфраструктуру, node скачивает образы, Gwin управляет ALB.
Это не Kubernetes ServiceAccount/RBAC: они действуют внутри API Kubernetes.

## Проверка, поломка и вопросы

В UI временно снимите `compute.editor` у `course-iac`, повторите список VM,
дождитесь распространения IAM. Получите PermissionDenied и верните роль.
Если доступ сохранился, проверьте унаследованные роли cloud/organization.
Чем истёкший токен отличается от отсутствующей роли? Почему node не нужен alb.editor?

## Очистка и продолжение

Верните нужную роль. Bootstrap-аккаунт оставьте до завершения курса;
после всех destroy удалите его и назначения ролей. Далее [VM](02-vm.md).
