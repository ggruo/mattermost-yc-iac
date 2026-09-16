# 5. Приложение на VM: Ansible, systemd и HTTPS

## Цель и подготовка

Создайте VM-стенд по занятию 4, если он удалён. Нужны тот же пароль БД и
работающий DNS. Схема: HTTPS → Nginx → localhost:8000 → TLS → PostgreSQL.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2–3 часа, VM и PG. Получение сертификата требует доступного TCP 80 и корректного
DNS; повторные запросы сертификатов ограничены ACME rate limits.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

Cloud DNS: проверьте A-запись `vm.lab.<домен>` и public IP VM.
Если делегирование ещё не распространилось, дождитесь его до Ansible.
Compute → serial console/SSH fingerprint используйте для проверки первого подключения.

## В терминале

```bash
tofu -chdir=terraform/vm output -json > ansible/inventory/terraform-output.json
python3 ansible/generate_inventory.py ansible/inventory/terraform-output.json ansible/inventory/generated.yml
export VM_IP="$(tofu -chdir=terraform/vm output -raw vm_public_ip)"
export APP_FQDN="$(tofu -chdir=terraform/vm output -raw fqdn)"
dig +short "$APP_FQDN"
ssh -i ~/.ssh/yc-course ubuntu@"$VM_IP" 'sudo cloud-init status --wait'
```

Fingerprint первого SSH проверьте через доверенный канал консоли VM.
После пересоздания IP может совпасть со старым: сначала подтвердите новый
fingerprint, затем удалите именно старую запись `ssh-keygen -R "$VM_IP"`.
Не отключайте host_key_checking.

```bash
cp ansible/inventory/group_vars/all/vault.yml.example ansible/inventory/group_vars/all/vault.yml
```

В редакторе замените пароль в Vault тем же значением, которое передали OpenTofu.
В `ansible/inventory/group_vars/all/settings.yml` укажите свой email для Certbot.

```bash
ansible-vault encrypt ansible/inventory/group_vars/all/vault.yml
cd ansible
ansible-playbook playbooks/site.yml --private-key ~/.ssh/yc-course --ask-vault-pass
ansible-playbook playbooks/site.yml --private-key ~/.ssh/yc-course --ask-vault-pass
cd ..
curl -fsS "https://$APP_FQDN/healthz"
curl -fsS "https://$APP_FQDN/readyz"
curl -fsS "https://$APP_FQDN/notes" -H 'Content-Type: application/json' -d '{"text":"hello from VM"}'
ssh -i ~/.ssh/yc-course ubuntu@"$VM_IP" 'sudo systemctl restart notes'
curl -fsS "https://$APP_FQDN/notes"
```

Ожидаются 200 на проверки, 201 на POST; запись сохраняется после рестарта.
Второй Ansible-запуск должен закончиться без изменений. Для правки зашифрованного
файла используйте `ansible-vault edit`, а не decrypt в Git-каталоге.

## В коде

Изучите `app/notes/main.py`, `app/notes/db.py` и роли Ansible.
`python -m notes.db` создаёт таблицу отдельно и повторяемо.
`no_log` скрывает secret-bearing задачи. EnvironmentFile читает systemd;
пользователь notes не получает sudo. Handler перезапускает сервис при изменении.
Certbot использует webroot, renewal hook перезагружает Nginx после обновления.

## Проверка, поломка и вопросы

На VM выполните `sudo systemctl stop notes`; внешний запрос получит 502.
Посмотрите `sudo journalctl -u notes -n 30` и `sudo nginx -t`, затем
`sudo systemctl start notes`. Для БД сравните 503 приложения с 502 прокси.
Проверьте `sudo ss -lntp`: приложение только 127.0.0.1:8000.
Вопрос: почему restart приложения не должен удалять заметки?

Если `/healthz` возвращает 200, а `/readyz` — 503, проверьте подключение к БД
с теми же ограничениями systemd, что у `notes.service`. Ошибка
`could not open certificate file "/home/notes/.postgresql/postgresql.crt": Permission denied`
означает, что libpq ищет необязательный клиентский сертификат внутри закрытого
через `ProtectHome=true` каталога. Шаблон `database.env.j2` задаёт
`PGSSLCERT=/etc/notes/postgresql.crt`: этот файл не создаётся, поскольку используется
парольная аутентификация. После обновления шаблона повторно примените Ansible;
handler перезапустит сервис. Сохраните `ProtectHome=true`, `PGSSLMODE=verify-full`
и `PGSSLROOTCERT=/etc/notes/ca.pem`: серверный CA и клиентский сертификат имеют
разное назначение. Проверьте `/readyz` повторно — ожидается 200.

## Очистка и продолжение

Выполните VM-раздел [очистки](../cleanup.md). Ansible не хранит пользовательские
файлы: данные в Managed PostgreSQL, backup изучается в занятии 9.
Далее [образ и Registry](06-registry.md).
