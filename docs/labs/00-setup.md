# 0. Подготовка и расходы

## Цель и подготовка

Нужны аккаунт Yandex Cloud, платёжный аккаунт, терминал и публичный домен.
Сначала различите Organization (пользователи/политики), Cloud (облако),
Folder (граница группировки и назначения ролей) и Resource.
Схема: пользователь → IAM → учебный folder → платные ресурсы.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2 часа. На этом этапе VM/БД не нужны. Домен — отдельная покупка.
Бюджет облака до 5 000 ₽ является целью, а не гарантией.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

1. Создайте отдельный folder `yc-course` и подключите Billing.
2. Посмотрите квоты Compute, Managed PostgreSQL, Managed Kubernetes, VPC/ALB.
   Нехватку квоты исправляйте до занятия, а не увеличением стенда наугад.
3. Billing → Budgets: уведомления на 2 500, 4 000 и 5 000 ₽ (50/80/100%).
   Получатель — ваш аккаунт. Уведомления не останавливают ресурсы.
4. Купите домен. Cloud DNS → создать публичную зону `lab.<ваш-домен>.`.
   У регистратора/в родительской DNS-зоне делегируйте `lab` через NS-записи,
   используя серверы, показанные Cloud DNS. Сохраните zone ID.
5. Откройте [калькулятор](https://yandex.cloud/ru/prices) и заполните бюджет ниже.
   Учитывайте валюту договора, тариф региона и возможные промокоды отдельно.

## В терминале

### Вариант 1: Dev Container

В репозитории есть [.devcontainer](../../.devcontainer/devcontainer.json) для Linux
amd64 и arm64 (включая Apple Silicon). На хосте нужны запущенный Docker
Desktop или Docker Engine и VS Code с расширением Dev Containers.

1. Откройте корень репозитория в VS Code.
2. Выполните **Dev Containers: Reopen in Container**. Первая сборка требует
   интернета для загрузки образа, CLI и Python-пакетов.
3. Дождитесь завершения `postCreateCommand`, откройте терминал **bash** и выполните:

   ```bash
   source .venv/bin/activate
   bash .devcontainer/check.sh
   ```

Контейнер включает Python 3.12, OpenTofu 1.10.6, Helm 3.17.3,
Ansible Core 2.18.6, PyYAML 6.0.2, зависимости приложения и pytest,
а также `yc`, `kubectl`, Docker CLI/Buildx, `dig`, `jq`, `envsubst`, SSH и `psql`.
`check.sh` выполняет локальные проверки из [validation.md](../validation.md),
отключает интеграционный тест БД и не создаёт облачные ресурсы.
Для `init` нужен доступ к реестру провайдеров.

Версии OpenTofu, Helm и kubectl задаются в `build.args` файла
`devcontainer.json`; после изменения выполните **Dev Containers: Rebuild Container**.
По умолчанию kubectl — 1.34.0. Перед работой с кластером подберите его minor-версию
под выбранный API Kubernetes: допустимое отличие — не более одной minor-версии
([правило совместимости](https://kubernetes.io/releases/version-skew-policy/#kubectl)).
`yc` устанавливается актуальным официальным установщиком; базовый образ и Docker
feature также обновляются, поэтому весь образ не зафиксирован побитово.

Docker CLI использует daemon хоста через socket — контейнер получает доступ
к управлению Docker на хосте. В Docker Desktop должен быть доступен стандартный
`/var/run/docker.sock`; для rootless Engine настройте mount socket по
[документации feature](https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker).
При ошибке соединения сначала проверьте `docker info` на хосте.

Домашний каталог `/home/vscode` хранится в отдельном Docker volume:
профиль `yc`, SSH-ключи, kubeconfig и вход в Registry сохраняются при пересборке.
Хостовые конфигурации автоматически не копируются. Linux-окружение `.venv`
хранится в другом volume и не перезаписывает `.venv` хоста.
При первом запуске выполните `yc init` и настройку ключа из общего блока ниже;
создание venv и `pip install` в контейнере уже выполнены.
При очистке после курса удалите контейнер и его volumes `yc-course-home-*`
и `yc-course-venv-*` через Docker Desktop, сверив их с mounts контейнера.
Удаление home volume уничтожает сохранённые ключи и профили; обычная пересборка
их сохраняет. Облачные ресурсы очищаются отдельно по общему ранбуку.

### Вариант 2: установка на хосте

Установите инструменты по официальным инструкциям:
[yc](https://yandex.cloud/ru/docs/cli/quickstart),
[OpenTofu](https://opentofu.org/docs/intro/install/),
[kubectl](https://kubernetes.io/docs/tasks/tools/),
[Helm](https://helm.sh/docs/intro/install/), Python 3.12 и Docker с Buildx.
Для воспроизведения локальных проверок использованы OpenTofu 1.10.6, Helm 3.17.3,
Ansible Core 2.18.6; API Kubernetes выбирается из поддерживаемых облаком версий.

### Настройка окружения и доступа

На хосте выполните весь блок; в Dev Container начните с `source .venv/bin/activate`.

```bash
bash
umask 077
mkdir -p .local
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements-dev.txt ansible-core==2.18.6 PyYAML==6.0.2
yc init
yc config set folder-id REPLACE_FOLDER_ID
yc config get folder-id
ssh-keygen -t ed25519 -f ~/.ssh/yc-course -C yc-course
```

Задайте passphrase ключа. `ssh-keygen` запускается один раз; не перезаписывайте
существующий ключ. Не помещайте private key в репозиторий.

```bash
tofu version
ansible-playbook --version
helm version --short
kubectl version --client
docker buildx version
dig NS lab.REPLACE_DOMAIN
```

Последняя команда должна показать делегированные NS. Не переходите к сертификатам,
пока публичное разрешение DNS не работает.

### Бюджет

Создайте личную копию таблицы в `.local/budget.md`, заполните ставки калькулятора:

| Группа | Что включить | Плановые часы | Ставка/час | Итого |
|---|---|---:|---:|---:|
| Ручная VM + БД | VM 2 CPU/2 GB, диск 15 GB, IP; PG 2 CPU/8 GB, SSD 20 GB | 3 | заполнить | часы × ставка |
| IaC VM + БД | Те же ресурсы | 4 | заполнить | часы × ставка |
| Kubernetes | master, worker 4 CPU/8 GB, диск 30 GB, PG, NAT, API IP | 6 | заполнить | часы × ставка |
| NLB/ALB | По отдельности, включая IP и минимальную ёмкость ALB | 1 + 2 | заполнить | часы × ставка |
| Прочее | Registry, logs, трафик, restore-кластер и PVC | заполнить | заполнить | заполнить |

Для дисков/хранилища переведите месячную ставку в нужный период по правилам тарифа.
Добавьте 25% резерва и часы ожидания создания/удаления. Если сумма больше 5 000 ₽,
сократите время жизни ресурсов и повторов; локальные упражнения делайте заранее.
Не начинайте платный шаг, пока не оценили его и остаток бюджета.
[Бюджеты](https://yandex.cloud/ru/docs/billing/operations/budgets).

## В коде

Прочитайте `.gitignore`, `AGENTS.md`, README и схему архитектуры.
State, секреты и сгенерированные файлы не должны попадать в Git.

## Проверка, поломка и вопросы

Проверка: правильный folder в `yc`, установленный набор инструментов, работающие NS.
Упражнение: переключитесь на неверный folder через `yc config set folder-id`,
увидьте другой список ресурсов, затем верните учебный ID.
Вопросы: чем folder отличается от VPC? Бюджет — запрет расходов или уведомление?

## Очистка и продолжение

Платных вычислительных ресурсов пока нет. DNS zone и домен нужны дальше.
После всего курса используйте [общую очистку](../cleanup.md).
Далее [IAM](01-iam.md).
