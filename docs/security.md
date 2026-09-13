# Доступ и секреты

**Только учебные данные:** публичный API позволяет любому посетителю читать и
добавлять заметки. Публикуйте его на время занятия, не храните персональные данные.

| Направление | Правило |
|---|---|
| Администратор → VM | TCP 22, только `trusted_cidrs` |
| Интернет → VM | TCP 80/443; 8000 слушает localhost |
| Администратор → Kubernetes API | TCP 443/6443, только `trusted_cidrs` |
| Control plane ↔ worker | Общая SG, self traffic; Pod/Service CIDR для маршрутизации |
| Cloud health checks → кластер | Предопределённый источник loadbalancer_healthchecks |
| Интернет → NLB → worker | Выделенный 30081, только при `enable_nlb=true`; public IP у worker нет |
| Интернет → ALB | TCP 80/443, health checks ALB на 30080 от специального источника |
| ALB → worker | 30080 для приложения, 30501 для служебной проверки |
| VM/worker SG → PostgreSQL | Только TCP 6432; public IP у БД нет |

NAT gateway разрешает исходящие соединения приватных узлов, но не публикует
приложение. Security Group — stateful: ответы на разрешённое соединение
пропускаются. Это не замена IAM, Kubernetes RBAC или TLS.
Источник SG у соединений Pod→БД зависит от SNAT на узле; курс использует
стандартную сеть Managed Kubernetes. При изменении CNI/ip-masq конфигурации
повторно проверьте этот путь, не открывайте БД на 0.0.0.0/0 для обхода ошибки.

Пароль передаётся в OpenTofu через `TF_VAR_postgres_password`; в Ansible — Vault;
в Kubernetes — Secret из локального файла. `sensitive=true` скрывает вывод,
**но пароль остаётся в state**. Файлы state/плана доступны только владельцу
(`umask 077`), не отправляются в Git/чат. Kubernetes Secret — base64, не шифрование.
Не печатайте его через `kubectl get secret -o yaml`.

Service account для IaC и аккаунты cluster/node/Gwin имеют разные задачи.
Kubernetes ServiceAccount приложения не нуждается в токене; automount выключен.
Gwin использует отдельный авторизованный ключ; он хранится локально и в Secret
контроллера, удаляется вместе с учебным аккаунтом при destroy.
Дальнейший шаг — workload identity federation вместо долгоживущего ключа.

В Ansible secret-bearing tasks используют `no_log`; environment-файл VM имеет
права 0600. PostgreSQL проверяется через `sslmode=verify-full` и CA Yandex.
Не отключайте проверку сертификата для исправления FQDN/сетевой ошибки.
