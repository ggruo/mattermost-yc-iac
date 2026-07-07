# Security

## Secrets

Do not commit:

- `terraform.tfvars`
- Terraform state files
- Ansible Vault files
- private SSH keys
- Yandex Cloud IAM tokens
- service account key files
- PostgreSQL passwords

Use:

- environment variables for Yandex Cloud provider credentials
- service account impersonation where possible
- `TF_VAR_postgres_password` or a local ignored `terraform.tfvars`
- Ansible Vault for `postgres_password`
- local SSH agent or private keys outside the repository

## Least Privilege

- Terraform should run as a service account with only the roles required for VPC, Compute Cloud, Cloud DNS, and Managed PostgreSQL resources.
- SSH is restricted to `trusted_ssh_cidrs`.
- PostgreSQL accepts traffic only from the Mattermost VM security group.
- PostgreSQL hosts are private-only.
- Mattermost listens on localhost behind Nginx.
- HTTPS is mandatory for end users.

## Project Checks Before Use

- No Docker or Kubernetes resources exist.
- Terraform resources are declarative and can be re-applied.
- Ansible tasks are idempotent where possible.
- Nginx public surface is limited to 80/443.
- SSH access is not open to `0.0.0.0/0` unless explicitly chosen in variables.
- Secrets and generated inventory are ignored by Git.
