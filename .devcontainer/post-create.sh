#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
mkdir -p .local

# A dedicated volume keeps Linux packages separate from the host's .venv.
sudo chown "$(id -u):$(id -g)" .venv
python3.12 -m venv .venv
.venv/bin/python -m pip install -r app/requirements-dev.txt \
  ansible-core==2.18.6 PyYAML==6.0.2

mkdir -p "$HOME/.ssh" "$HOME/.kube" "$HOME/.config/yandex-cloud" "$HOME/.docker"
chmod 700 "$HOME/.ssh" "$HOME/.kube" "$HOME/.config/yandex-cloud" "$HOME/.docker"
echo 'Готово. Выполните source .venv/bin/activate, затем yc init по лабораторной 0.'
