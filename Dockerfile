FROM ghcr.io/renovatebot/renovate:41.43.5

USER 0
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    jq \
    python3-pip \
    pre-commit \
    curl \
    wget && \
  rm -rf /var/lib/apt/lists/*
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install mikefarah/yq (Go version) for both amd64 and arm64
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
      YQ_ARCH=amd64; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      YQ_ARCH=arm64; \
    else \
      echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}" && \
    chmod +x /usr/bin/yq

# Install helm-docs (cross-platform for amd64 and arm64) from latest release
ENV HELMDOCS_VERSION=1.14.2
RUN set -e; \
  ARCH=$(uname -m); \
  if [ "$ARCH" = "x86_64" ]; then \
    HELMDOCS_ARCH=x86_64; \
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
    HELMDOCS_ARCH=arm64; \
  else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
  fi; \
  wget -O /tmp/helm-docs.tar.gz "https://github.com/norwoodj/helm-docs/releases/download/v${HELMDOCS_VERSION}/helm-docs_${HELMDOCS_VERSION}_Linux_${HELMDOCS_ARCH}.tar.gz"; \
  tar -xzf /tmp/helm-docs.tar.gz -C /usr/local/bin helm-docs; \
  chmod +x /usr/local/bin/helm-docs; \
  rm /tmp/helm-docs.tar.gz

USER ubuntu

COPY .pre-commit-config.yaml ./
RUN mkdir /tmp/pre-commit-init && \
    cp .pre-commit-config.yaml /tmp/pre-commit-init/ && \
    cd /tmp/pre-commit-init && \
    git init && \
    pre-commit run -a && \
    rm -rf /tmp/pre-commit-init

