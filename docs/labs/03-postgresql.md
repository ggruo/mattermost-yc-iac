# 3. Приватный Managed PostgreSQL

## Цель и подготовка

Нужна VM из занятия 2 (при необходимости создайте снова).
Схема: VM → FQDN:6432 → Managed PostgreSQL. Управление сервисом через IAM
не заменяет пользователя/пароль самой SQL-базы.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2–3 часа: работающие VM и один PG host, класс s3-c2-m8, SSD 20 GB.
Окружение PRESTABLE; 7 дней backup. Это учебные настройки, не production HA.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

1. Создайте SG `manual-db`: входящий TCP 6432 только от SG `manual-vm`;
   исходящий ANY. Не добавляйте public ingress.
2. Managed PostgreSQL → создать кластер `manual-db`, PostgreSQL 17, один host,
   сеть manual-net/subnet manual-a, public access выключен, SG manual-db.
   Создайте БД и пользователя `notes`; пароль сохраните в менеджере паролей.
3. Дождитесь Running/Alive. Откройте «Подключиться»: скопируйте специальный
   master FQDN вида `c-<id>.rw.mdb.yandexcloud.net` и проверьте порт 6432.
4. Посмотрите разделы Hosts, Backups, Monitoring и Maintenance.

## В терминале

На VM по SSH:

```bash
mkdir -p ~/.postgresql
curl -fsSL https://storage.yandexcloud.net/cloud-certs/CA.pem -o ~/.postgresql/root.crt
export PGHOST=REPLACE_MASTER_FQDN
export PGPORT=6432
export PGDATABASE=notes
export PGUSER=notes
export PGSSLMODE=verify-full
export PGCONNECT_TIMEOUT=5
psql -W
```

Введите пароль по запросу psql. В SQL:

```sql
SELECT current_database(), current_user;
CREATE TABLE IF NOT EXISTS connectivity_test (message text);
INSERT INTO connectivity_test VALUES ('hello from VM');
SELECT * FROM connectivity_test;
DROP TABLE connectivity_test;
\q
```

`verify-full` проверяет CA и имя сервера. FQDN master следует за текущим мастером;
адрес отдельного host — другой способ адресации.
[Подключение](https://yandex.cloud/ru/docs/managed-postgresql/operations/connect/).

## В коде

Сравните UI с общим модулем `terraform/modules/postgresql`.
`assign_public_ip=false` отвечает за приватность, SG — за разрешённые источники,
а `owner` базы — за SQL-владельца. Это три разных настройки.

## Проверка, поломка и вопросы

Введите неверный пароль: получите ошибку аутентификации. Затем временно удалите
правило 6432: получите timeout. Верните правило. С домашнего компьютера приватная
БД не должна стать доступной только потому, что вы знаете пароль.
Вопрос: чем backup отличается от второго host и от проверки доступности?

## Очистка и продолжение

Перед IaC обязательно удалите ручной кластер в UI, затем VM и её диск/IP,
SG manual-db/manual-vm, subnet и сеть. Это завершает ручную ветку.
Далее [OpenTofu](04-iac.md); import не нужен для этого перехода.
