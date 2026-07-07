# Agent Instructions

This repository deploys Mattermost on Yandex Cloud with Terraform/OpenTofu and Ansible.

## Core Rules

- Do not use Docker.
- Do not use Kubernetes.
- Mattermost must run directly on Linux through `systemd`.
- Nginx is the only reverse proxy.
- PostgreSQL must be Yandex Managed PostgreSQL, not a local database on the VM.
- Keep infrastructure and host configuration idempotent.
- Do not commit secrets, generated inventory, Terraform state, private keys, or real `.tfvars` files.

## Repository Layout

- `terraform/`: cloud infrastructure.
- `terraform/modules/network/`: VPC, per-zone subnets, Cloud DNS.
- `terraform/modules/security/`: security groups.
- `terraform/modules/compute/`: VM, static public IP, cloud-init.
- `terraform/modules/postgresql/`: Managed PostgreSQL cluster, database, user.
- `ansible/`: host configuration and operational playbooks.
- `ansible/roles/common/`: base OS setup.
- `ansible/roles/mattermost/`: Mattermost package install, config, service.
- `ansible/roles/nginx/`: Nginx, Certbot, HTTPS reverse proxy.
- `docs/`: architecture, operations, security documentation.

## Terraform/OpenTofu Guidance

- Prefer `tofu` commands in this environment because Terraform may not be installed.
- Keep `.terraform.lock.hcl` versioned for reproducible provider resolution.
- Do not edit `.terraform/` or generated state files manually.
- Use variables for region, zones, CIDRs, VM sizing, PostgreSQL sizing, DNS, SSH CIDRs, and credentials.
- Keep PostgreSQL private-only and protected by security groups.
- Preserve deletion protection and automatic backups for production PostgreSQL.
- If adding modules, declare the `yandex-cloud/yandex` provider source in each module.

Recommended checks:

```bash
cd terraform
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
```

## Ansible Guidance

- Roles must remain idempotent.
- Avoid shell commands when a built-in Ansible module can express the task cleanly.
- Use handlers for service restarts.
- Do not print database passwords or connection strings; use `no_log: true` around secret-bearing tasks.
- Keep Mattermost bound to `127.0.0.1:8065`; expose it only through Nginx.
- Store real `postgres_password` in Ansible Vault, not in plain YAML.

Recommended checks:

```bash
cd ansible
ansible-playbook -i inventory/generated.yml.example playbooks/site.yml --syntax-check
ansible-playbook -i inventory/generated.yml.example playbooks/backup-files.yml --syntax-check
```

If Ansible does not parse `generated.yml.example` as YAML inventory in the local version, copy it to a temporary `.yml` file for syntax checks.

## Secrets And Generated Files

Never commit:

- `terraform/terraform.tfvars`
- Terraform state files
- `ansible/group_vars/all/vault.yml`
- `ansible/inventory/generated.yml`
- private SSH keys
- Yandex Cloud IAM tokens or service account key files

Allowed examples:

- `terraform/terraform.tfvars.example`
- `ansible/group_vars/all/vault.yml.example`
- `ansible/inventory/generated.yml.example`

## Implementation Style

- Keep changes small and aligned with the existing module/role boundaries.
- Update docs when behavior, variables, security rules, backup flow, or deployment steps change.
- Before adding a component, verify it is required by the requested architecture.
- Do not introduce load balancers, object storage, Redis, OpenSearch, multi-node Mattermost, or other scaling components unless explicitly requested.

## Deployment Flow

Expected operator flow:

```bash
cd terraform
tofu init
tofu plan
tofu apply
tofu output -json > ../ansible/inventory/terraform-output.json
cd ..
python3 ansible/generate_inventory.py \
  ansible/inventory/terraform-output.json \
  ansible/inventory/generated.yml
cd ansible
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Final Review Checklist

- No Docker or Kubernetes usage.
- SSH is restricted to trusted CIDRs.
- Public ingress is limited to HTTP/HTTPS and trusted SSH.
- PostgreSQL ingress is limited to the Mattermost VM security group.
- Mattermost service is managed by `systemd`.
- Nginx terminates HTTPS and proxies to localhost.
- Terraform/OpenTofu validation passes.
- Ansible syntax checks pass.
- Documentation reflects the implemented behavior.
