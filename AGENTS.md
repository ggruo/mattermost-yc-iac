# Учебный проект Yandex Cloud

Цель: читаемый курс из 10 лабораторных, одно приложение на VM и Kubernetes.
- Docker разрешён для сборки/локальной проверки OCI-образа; в Kubernetes — containerd.
- VM: Linux, systemd, Nginx, Ansible. БД только Yandex Managed PostgreSQL, без public IP.
- Kubernetes, Container Registry, NLB, ALB/Gwin, DNS и Certificate Manager входят в курс.
- Не добавлять Redis, service mesh, многонодовое приложение или production HA без запроса.
- OpenTofu управляет инфраструктурой, Helm/kubectl — workload, Gwin — ALB.
- Каждый корневой Terraform-каталог имеет независимый state и versioned lock-файл.
- Не коммитить state, планы, реальные tfvars, inventory, kubeconfig, ключи и пароли.
- Secret-bearing Ansible tasks: no_log; рестарты через handlers; повторное применение идемпотентно.
- SSH/API только с trusted CIDR; PostgreSQL только от группы приложения.
- Ранбуки на русском: цель, цена, UI, терминал, код, проверки, поломка, очистка.
- Проверять fmt/init/validate, Ansible syntax, Helm lint/template и pytest.
- Не создавать платные ресурсы для локальных проверок. Облачную приёмку отмечать отдельно.
