# 4. OpenTofu, plan, state и drift

## Цель и подготовка

Ручные ресурсы удалены. Нужны IAM из занятия 1, DNS zone из занятия 0,
SSH public key. Схема: HCL + state → provider → Yandex API.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2–3 часа: новый VM-стенд и однохостовый PostgreSQL; не держите ручной стенд рядом.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

Перед apply посмотрите пустой учебный folder и проверьте актуальный расчёт.
После apply найдите созданные `notes-vm*`, сравните размеры, IP, SG и БД с кодом.

## В терминале

```bash
umask 077
cp terraform/vm/terraform.tfvars.example terraform/vm/terraform.tfvars
```

Откройте копию в редакторе: замените folder_id, trusted_cidrs своим публичным
IP/32, путь public key, fqdn `vm.lab.<домен>` и существующий dns_zone_id.
Пароль БД задайте безопасным вводом в bash. Используйте одну строку без
табуляции и других управляющих символов:

```bash
export IAC_SA_ID=REPLACE_SERVICE_ACCOUNT_ID
read -rsp 'PostgreSQL password: ' TF_VAR_postgres_password
printf '\n'
export TF_VAR_postgres_password
export YC_TOKEN="$(yc iam create-token --impersonate-service-account-id "$IAC_SA_ID")"
tofu -chdir=terraform/vm init
tofu -chdir=terraform/vm fmt -check
tofu -chdir=terraform/vm validate
tofu -chdir=terraform/vm plan
tofu -chdir=terraform/vm apply
tofu -chdir=terraform/vm output
tofu -chdir=terraform/vm plan
```

`-chdir` задаёт корень и его state. Последний plan должен показать No changes.
`apply` просит подтверждение после просмотра изменений; не используйте auto-approve.
Если вызов прерван, сначала изучите состояние операции в UI и следующий plan,
а не удаляйте state и не создавайте дубликаты.

## В коде

Проследите цепочку ссылок: network.id → subnet → VM и PostgreSQL.
`variable` — вход, `output` — результат, `resource` — управляемый объект,
`data` — чтение существующего образа. State связывает адрес ресурса с cloud ID.
`.terraform.lock.hcl` фиксирует provider; его нужно хранить в Git.
`sensitive` не шифрует state.

### Необязательное упражнение import

Это отдельная пустая VPC, не сеть работающего стенда. В UI создайте сеть
`manual-import` без subnet и скопируйте ID. В терминале:

```bash
mkdir -p .local/import-demo
```

Создайте `.local/import-demo/main.tf` в редакторе:

```hcl
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.127.0"
    }
  }
}
provider "yandex" {}
resource "yandex_vpc_network" "demo" {
  name = "manual-import"
}
```

Provider получает YC_TOKEN/YC_FOLDER_ID из окружения занятия 1; восстановите их,
если открыли новый терминал. Импорт связывает ID с адресом, не генерирует HCL:

```bash
export YC_FOLDER_ID="$(yc config get folder-id)"
tofu -chdir=.local/import-demo init
tofu -chdir=.local/import-demo import yandex_vpc_network.demo REPLACE_NETWORK_ID
tofu -chdir=.local/import-demo plan
tofu -chdir=.local/import-demo destroy
```

Если план показывает изменение, сравните параметры UI с HCL до применения.
Не импортируйте одну сеть одновременно в два state. Пустая сеть после этого
удалена; файлы демонстрации можно удалить из `.local/import-demo`.

## Проверка, поломка и вопросы

В UI измените описание VM. Выполните plan и прочитайте diff. Если свойство
не задано в HCL, сначала явно добавьте `description = "Learning VM"` в resource
и примените; повторное изменение через UI теперь должно обнаруживаться.
Верните состояние apply. Не используйте ignore_changes для сокрытия упражнения.
Вопрос: почему удаление файла state не удаляет VM?

## Очистка и продолжение

Сразу переходите к [приложению](05-app-vm.md) либо выполните VM-раздел
[очистки](../cleanup.md). Для продолжения после удаления повторите init/apply;
сохраните локальные tfvars и пароль до завершения destroy.
