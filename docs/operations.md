# Operations

## Deployment Flow

Run Terraform first, then Ansible:

```bash
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output -json > ../ansible/inventory/terraform-output.json
cd ..
python3 ansible/generate_inventory.py ansible/inventory/terraform-output.json ansible/inventory/generated.yml
cd ansible
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Configuration Ownership

Terraform owns cloud infrastructure:

- project and environment names
- Yandex Cloud zones
- subnet CIDRs
- trusted SSH CIDRs
- SSH public key path
- VM sizing and image family
- DNS zone and Mattermost FQDN
- PostgreSQL version, host class, disk, database, user, backup retention

Ansible owns host configuration:

- Mattermost package version
- Mattermost SiteURL and support email
- PostgreSQL connection settings from Terraform outputs
- Nginx reverse proxy settings
- Let's Encrypt contact email
- Mattermost local backup directory

## Mattermost Updates

To update Mattermost without recreating infrastructure:

1. Confirm PostgreSQL backups are healthy.
2. Run the file backup playbook:

   ```bash
   cd ansible
   ansible-playbook playbooks/backup-files.yml --ask-vault-pass
   ```

3. Set `mattermost_version` in `ansible/group_vars/all/main.yml` if pinning a specific package version is required. Leave it empty to install the repository candidate.
4. Run:

   ```bash
   ansible-playbook playbooks/site.yml --ask-vault-pass
   ```

Terraform is not required for application package updates.

## Backups

PostgreSQL:

- Managed PostgreSQL automatic backups are enabled by Terraform.
- Backup retention is controlled by `postgres_backup_retain_period_days`.
- `deletion_protection` is enabled for the cluster.
- Create or verify a manual backup before major Mattermost or PostgreSQL upgrades.

Mattermost files:

- Local files live under `/opt/mattermost`, especially `config`, `data`, `plugins`, and `client/plugins`.
- Use `ansible/playbooks/backup-files.yml` before upgrades.
- For production retention, copy resulting archives from `/var/backups/mattermost` to Yandex Object Storage or another external backup target.

## Restore Outline

1. Restore or recreate infrastructure with Terraform.
2. Restore PostgreSQL using Managed PostgreSQL backup restore procedures.
3. Restore Mattermost file archive into `/opt/mattermost`.
4. Fix ownership with `chown -R mattermost:mattermost /opt/mattermost`.
5. Re-run `ansible-playbook playbooks/site.yml`.
