# Локальная проверка без платных ресурсов

Все команды из корня репозитория. Инструменты — занятие 0.

```bash
tofu -chdir=terraform/vm fmt -check -recursive
tofu -chdir=terraform/vm init -backend=false
tofu -chdir=terraform/vm validate
tofu -chdir=terraform/kubernetes fmt -check -recursive
tofu -chdir=terraform/kubernetes init -backend=false
tofu -chdir=terraform/kubernetes validate
tofu fmt -check -recursive terraform
```

Provider lock-файлы находятся в обоих корнях. Не коммитьте `.terraform/`.
Validate проверяет схему, а не квоты, доступность версий Kubernetes или IAM аккаунта.

```bash
source .venv/bin/activate
PYTHONPATH=app python -m pytest app/tests -q
helm lint charts/notes
helm template notes charts/notes --namespace notes > .local/helm-check.yaml
```

Четыре локальных теста не требуют БД; интеграционный пропускается без явного
`RUN_DB_TESTS=1`. Для него нужны отдельная учебная база и PGHOST/PGPORT/PGDATABASE/
PGUSER/PGPASSWORD/PGSSLMODE/PGSSLROOTCERT. Не запускайте на production.

```bash
RUN_DB_TESTS=1 PYTHONPATH=app python -m pytest app/tests -q
```

Тест создаёт таблицу идемпотентно, записывает заметку и читает через новое соединение,
после чего удаляет свою запись. Существующие заметки не очищает.

Ansible inventory с суффиксом `.example` некоторые версии не считают YAML.
Создайте временную копию, не меняя generated inventory:

```bash
mkdir -p .local
cp ansible/inventory/generated.yml.example .local/check-inventory.yml
cd ansible
ansible-playbook -i ../.local/check-inventory.yml playbooks/site.yml --syntax-check
cd ..
```

Это синтаксическая проверка; idempotence и TLS проверяются только на VM.
Cloud smoke tests — отдельный [лист](acceptance.md). Команды plan/apply намеренно
не включены в локальную проверку.

## Результаты локальной проверки при переработке

Проверено 2026-09-11 на macOS arm64 / Python 3.12:

- OpenTofu 1.10.6: оба init и validate успешны, fmt без замечаний.
- Yandex provider 0.127.0: подписанный пакет, lock-файл в каждом корне.
- Ansible Core 2.18.6: site.yml syntax-check с корректно прочитанным inventory.
- Helm 3.17.3: lint/render notes; Deployment совпадает с обычным манифестом.
- Gwin v1.10.0: chart скачан и отрендерен локально; его nodecheck использует 30501.
- 10 стандартных Kubernetes-объектов прошли kubeconform; 4 custom resources
  проверены по CRD из скачанного Gwin chart.
- pytest: 4 passed, 1 skipped (нужен PostgreSQL). Есть предупреждение устаревшего
  API anyio внутри Starlette TestClient; оно не влияет на успешность тестов.
- Локальные Markdown-ссылки и синтаксис bash-блоков проверены.

**Не проверено в облаке:** apply/destroy, идемпотентность Ansible на VM,
сертификат, реальные SQL-запросы, NLB/ALB, HPA/PVC и backup/restore.
В среде исполнения нет настроенного `yc`; платные ресурсы не создавались.
Docker daemon не запущен, поэтому сборка/запуск образа тоже не проверены.
Не отмечайте соответствующие пункты листа облачной приёмки без выполнения.
