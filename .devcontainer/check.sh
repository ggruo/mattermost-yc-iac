#!/usr/bin/env bash
# Local checks only: no cloud authentication or paid resources required.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
mkdir -p .local
source .venv/bin/activate
python --version
yc version
tofu version
ansible-playbook --version
helm version --short
kubectl version --client
docker buildx version
docker info > /dev/null

tofu fmt -check -recursive terraform
for root in terraform/vm terraform/kubernetes; do
  tofu -chdir="$root" init -backend=false -lockfile=readonly
  tofu -chdir="$root" validate
done
env -u RUN_DB_TESTS PYTHONPATH=app python -m pytest app/tests -q
helm lint charts/notes
helm template notes charts/notes --namespace notes > .local/helm-check.yaml
inventory="$(mktemp "$PWD/.local/check-inventory.XXXXXX.yml")"
trap 'rm -f "$inventory"' EXIT
cp ansible/inventory/generated.yml.example "$inventory"
cd ansible
ansible-playbook -i "$inventory" playbooks/site.yml --syntax-check
