# Yandex Cloud: от виртуалки до Kubernetes

Практический курс: одно приложение Cloud Notes, приватный Managed PostgreSQL,
два последовательных стенда. Первый — Linux/systemd/Nginx, второй — Managed
Kubernetes, NLB и ALB. Ориентир: 10 занятий по 2–3 часа плюс создание ресурсов.

**Начните с [занятия 0](docs/labs/00-setup.md).** Не запускайте apply до расчёта
стоимости. Цель — до 5 000 ₽ за курс; домен отдельно. Это не готовая смета и
не автоматический лимит списаний. Все данные учебные, API не имеет авторизации.

| № | Занятие | Где особенно полезен UI |
|---|---|---|
| 0 | [Подготовка и расходы](docs/labs/00-setup.md) | Folder, Billing, квоты, DNS |
| 1 | [IAM](docs/labs/01-iam.md) | Service accounts и роли |
| 2 | [Сеть и VM вручную](docs/labs/02-vm.md) | Subnet, IP, security groups |
| 3 | [Managed PostgreSQL](docs/labs/03-postgresql.md) | Подключение, метрики, backup |
| 4 | [OpenTofu и state](docs/labs/04-iac.md) | Сверка кода и ресурсов, drift |
| 5 | [Приложение на VM](docs/labs/05-app-vm.md) | DNS, далее Ansible/SSH |
| 6 | [Образ и Registry](docs/labs/06-registry.md) | Образы и digest |
| 7 | [Managed Kubernetes](docs/labs/07-kubernetes.md) | Master, node group, операции |
| 8 | [NLB, ALB и HTTPS](docs/labs/08-exposure.md) | Listener, backend, сертификат |
| 9 | [Helm и эксплуатация](docs/labs/09-operations.md) | Метрики, backup/restore |

Нужны основы Linux/SSH, IP/портов и YAML. OpenTofu использует тот же HCL-подход,
что Terraform; в курсе команды `tofu`. Подготовка инструментов — в занятии 0.
Курс не требует сохранять прежнюю инсталляцию Mattermost; она доступна в истории Git.
Не используйте старые state или inventory с новой конфигурацией.

## Устройство репозитория

- `app/`: FastAPI, PostgreSQL, Dockerfile и тесты.
- `terraform/vm/`, `terraform/kubernetes/`: отдельные корни и независимые state.
- `terraform/modules/postgresql/`: небольшой общий модуль однохостовой БД.
- `ansible/`: конфигурация VM, Vault, Nginx и systemd.
- `kubernetes/`: обычные манифесты, публикация и упражнения.
- `charts/notes/`: Helm chart того же приложения.
- `docs/labs/`: учебный маршрут; `.local/`: ваши игнорируемые файлы.

Прочитайте [архитектуру](docs/architecture.md), [безопасность](docs/security.md),
[порядок очистки](docs/cleanup.md) и [локальные проверки](docs/validation.md).
[Лист облачной приёмки](docs/acceptance.md) отделяет проверенный код от
проверки настоящего облачного развёртывания. [Дальнейшие темы](docs/next.md).

Каждое занятие заканчивается очисткой. Если следующий шаг делаете сразу,
можно сохранить ресурсы на время этой сессии; продолжение после удаления
всегда начинается с повторного развёртывания по ссылке в занятии.
