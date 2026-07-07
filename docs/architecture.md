# Architecture

## Components

The deployment has one public application VM and a private managed database.

- VPC and per-zone subnets isolate the project resources in Yandex Cloud.
- The Mattermost VM receives a static public IP for DNS stability.
- Nginx accepts public HTTP/HTTPS traffic and proxies to Mattermost on `127.0.0.1:8065`.
- Mattermost is installed directly on Ubuntu from the official signed package repository and runs through `mattermost.service`.
- Managed PostgreSQL is private-only, protected by security groups, automatic backups, and deletion protection.
- Cloud DNS publishes the Mattermost FQDN as an `A` record.
- Let's Encrypt certificates are issued by Certbot using the Nginx plugin.

## Network Rules

- Internet to VM: TCP 80 and 443.
- Trusted administrator CIDRs to VM: TCP 22.
- VM security group to PostgreSQL security group: TCP 6432 and 5432.
- VM outbound: open, because package installation and Let's Encrypt require internet access.
- PostgreSQL has no public IP.

## Terraform Modules

- `network`: creates `yandex_vpc_network`, `yandex_vpc_subnet`, and optionally `yandex_dns_zone`.
- `security`: creates minimal `yandex_vpc_security_group` resources for the VM and PostgreSQL.
- `compute`: creates `yandex_vpc_address` and `yandex_compute_instance`; cloud-init injects SSH access and Python prerequisites.
- `postgresql`: creates `yandex_mdb_postgresql_cluster`, `yandex_mdb_postgresql_user`, and `yandex_mdb_postgresql_database`.

## Ansible Roles

- `common`: installs base packages and configures timezone.
- `mattermost`: adds the Mattermost package repository, installs Mattermost, configures PostgreSQL, SiteURL, listen address, support email, and systemd service.
- `nginx`: installs Nginx and Certbot, obtains Let's Encrypt certificate, and configures HTTPS reverse proxy.

## Deliberate Exclusions

This v1 does not include Docker, Kubernetes, Application Load Balancer, multiple Mattermost nodes, Redis, Elasticsearch/OpenSearch, or S3-compatible file storage. Those are scaling additions, not required for the requested baseline.
