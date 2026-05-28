FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg apt-transport-https \
        build-essential python3 python3-pip python3-venv \
        ffmpeg git tini tmux jq \
    && rm -rf /var/lib/apt/lists/*

# Google Cloud SDK (for `gws auth setup`)
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# gws CLI (pinned Linux x86_64 binary). Bump version when needed:
# https://github.com/googleworkspace/cli/releases
ARG GWS_VERSION=v0.22.5
RUN set -eux; \
    url="https://github.com/googleworkspace/cli/releases/download/${GWS_VERSION}/google-workspace-cli-x86_64-unknown-linux-gnu.tar.gz"; \
    curl -fL -o /tmp/gws.tar.gz "$url"; \
    tar -xzf /tmp/gws.tar.gz -C /tmp; \
    mv /tmp/gws /usr/local/bin/gws; \
    chmod +x /usr/local/bin/gws; \
    rm -rf /tmp/gws.tar.gz /tmp/CHANGELOG.md /tmp/LICENSE /tmp/README.md; \
    gws --version

# Hermes Agent
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

VOLUME ["/root/.hermes", "/root/.config/gws", "/root/.config/gcloud"]

ENTRYPOINT ["tini", "--"]
CMD ["bash", "-lc", "hermes gateway"]
