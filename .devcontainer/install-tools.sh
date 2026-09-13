#!/usr/bin/env bash
set -euo pipefail

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64|arm64) ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"
download() { curl --fail --show-error --silent --location --retry 3 "$1" -o "$2"; }

tofu_archive="tofu_${TOFU_VERSION}_linux_${arch}.zip"
tofu_url="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}"
download "$tofu_url/$tofu_archive" "$tofu_archive"
download "$tofu_url/tofu_${TOFU_VERSION}_SHA256SUMS" tofu-checksums
awk -v file="$tofu_archive" '$2 == file { print }' tofu-checksums > tofu.sha256
test -s tofu.sha256
sha256sum --check tofu.sha256
unzip -q "$tofu_archive" tofu
install -m 0755 tofu /usr/local/bin/tofu

helm_archive="helm-v${HELM_VERSION}-linux-${arch}.tar.gz"
download "https://get.helm.sh/$helm_archive" "$helm_archive"
download "https://get.helm.sh/$helm_archive.sha256sum" helm.sha256
sha256sum --check helm.sha256
tar -xzf "$helm_archive" "linux-${arch}/helm"
install -m 0755 "linux-${arch}/helm" /usr/local/bin/helm

kubectl_url="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"
download "$kubectl_url" kubectl
download "$kubectl_url.sha256" kubectl.sha256
printf '%s  kubectl\n' "$(cat kubectl.sha256)" | sha256sum --check
install -m 0755 kubectl /usr/local/bin/kubectl

# The course does not pin yc; use the official non-interactive installer.
download https://storage.yandexcloud.net/yandexcloud-yc/install.sh yc-install.sh
bash yc-install.sh -i /opt/yc -n
tofu version
helm version --short
kubectl version --client
/opt/yc/bin/yc version
