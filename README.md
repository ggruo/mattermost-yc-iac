# Mattermost on Yandex Cloud

Infrastructure as Code project for deploying Mattermost directly on Linux in Yandex Cloud.

The stack uses Terraform for cloud resources and Ansible for host configuration. It does not use Docker or Kubernetes.

## Architecture

- Yandex VPC network and per-zone subnets.
- Security groups with public HTTP/HTTPS, SSH only from trusted CIDRs, and PostgreSQL access only from the Mattermost VM security group.
- One Ubuntu LTS VM with a static public IP.
- Yandex Managed Service for PostgreSQL in production mode with two private hosts, automatic backups, and deletion protection.
- Cloud DNS record pointing the Mattermost FQDN to the VM public IP.
- Nginx reverse proxy with Let's Encrypt TLS.
- Mattermost installed from the official Ubuntu package repository and managed by systemd.

## Repository Layout

- `terraform/`: root Terraform configuration and local modules.
- `terraform/modules/network/`: VPC, per-zone subnets, DNS zone.
- `terraform/modules/security/`: VM and PostgreSQL security groups.
- `terraform/modules/compute/`: static public IP and Mattermost VM.
- `terraform/modules/postgresql/`: Managed PostgreSQL cluster, database, user.
- `ansible/`: playbooks, generated inventory, variables, roles.
- `docs/`: operating documentation.

## Quick Start

1. Configure Yandex Cloud credentials via environment variables:

   ```bash
   export YC_TOKEN="$(yc iam create-token --impersonate-service-account-id <service-account-id>)"
   export YC_CLOUD_ID="$(yc config get cloud-id)"
   export YC_FOLDER_ID="$(yc config get folder-id)"
   ```

2. Create local Terraform variables outside Git:

   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   chmod 600 terraform/terraform.tfvars
   ```

3. Edit `terraform/terraform.tfvars`. Do not commit real secrets.

4. Deploy infrastructure:

   ```bash
   cd terraform
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan
   terraform apply
   terraform output -json > ../ansible/inventory/terraform-output.json
   cd ..
   ```

5. Generate Ansible inventory:

   ```bash
   python3 ansible/generate_inventory.py \
     ansible/inventory/terraform-output.json \
     ansible/inventory/generated.yml
   ```

6. Create Ansible Vault file:

   ```bash
   cp ansible/group_vars/all/vault.yml.example ansible/group_vars/all/vault.yml
   ansible-vault encrypt ansible/group_vars/all/vault.yml
   ```

7. Run Ansible:

   ```bash
   cd ansible
   ansible-playbook playbooks/site.yml --ask-vault-pass
   ```

## Documentation

- [Architecture](docs/architecture.md)
- [Operations](docs/operations.md)
- [Security](docs/security.md)
