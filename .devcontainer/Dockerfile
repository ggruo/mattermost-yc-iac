FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

ARG TOFU_VERSION=1.10.6
ARG HELM_VERSION=3.17.3
ARG KUBECTL_VERSION=1.34.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip dnsutils jq gettext-base openssh-client \
    postgresql-client rsync \
    && rm -rf /var/lib/apt/lists/*

COPY install-tools.sh /tmp/install-tools.sh
RUN bash /tmp/install-tools.sh && rm /tmp/install-tools.sh

ENV PATH="/opt/yc/bin:${PATH}"
