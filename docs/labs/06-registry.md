# 6. OCI-образ и Container Registry

## Цель и подготовка

VM больше не нужна. Docker используется для сборки и локального запуска;
Kubernetes позже запускает этот образ через containerd.
Схема: source → Docker build → registry → worker pull.

Команды выполняйте из корня репозитория в **bash** (на macOS сначала `bash`).
`REPLACE_*` — значение, которое нужно заменить; не выполняйте его буквально.
`export` действует только в текущем терминале. Секреты не вставляйте в команды.

## Время и стоимость

2 часа, только хранение образа и возможный трафик Registry. Не поднимайте БД
для проверки liveness; её отсутствие здесь намеренное.
Перед созданием внесите оценку в [таблицу бюджета](00-setup.md#бюджет).

## В UI

Container Registry → создать registry `course` в учебном folder.
Сохраните ID. У личного пользователя должны быть роли из занятия 1.
После push посмотрите tag, digest и размер образа. Digest определяет содержимое;
перезаписываемый tag не гарантирует неизменность.

## В терминале

```bash
export REGISTRY_ID=REPLACE_REGISTRY_ID
export IMAGE_TAG="cr.yandex/$REGISTRY_ID/notes:1.0.0"
yc container registry configure-docker
docker buildx build --platform linux/amd64 -t "$IMAGE_TAG" --load app
docker run --rm -d --name notes-local -p 127.0.0.1:8000:8000 "$IMAGE_TAG"
curl -fsS http://127.0.0.1:8000/healthz
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8000/readyz
docker stop notes-local
docker push "$IMAGE_TAG"
docker buildx imagetools inspect "$IMAGE_TAG"
```

На Apple Silicon `--platform linux/amd64` нужен для x86 worker Yandex Cloud.
Health должен быть 200, readiness без БД — 503. Из вывода inspect скопируйте
Digest и сохраните полную ссылку в `.local/image.txt`:

```bash
export IMAGE="cr.yandex/$REGISTRY_ID/notes@sha256:REPLACE_DIGEST"
printf '%s\n' "$IMAGE" > .local/image.txt
```

Это не секрет. В последующих занятиях используется digest, а не latest.

## В коде

Прочитайте Dockerfile и `.dockerignore`: в build context попадают только
приложение и requirements. Пароль, CA, tfvars и весь репозиторий в образ не копируются.
Базовый образ и Python-зависимости закреплены; обновлять их нужно сознательно
с повторной проверкой. Приложение работает непривилегированным UID 10001.

## Проверка, поломка и вопросы

Запустите образ с несуществующим tag: отличите image-not-found от ошибки
процесса приложения. Верните правильный digest.
Объясните разницу build/push/pull, tag/digest и локального ARM/x86 окружения.

## Очистка и продолжение

Остановите локальный контейнер. Registry с одним образом можно сохранить для
следующего занятия: это небольшой, но не нулевой расход хранения. Если хотите
полную очистку, удалите образ и registry в UI; перед занятием 7 повторите создание
и push. После всего курса Registry удаляется отдельно от Terraform.
