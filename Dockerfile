# GitHub's actions-runner image plus what jobs written for GitHub-hosted
# runners expect and the base image lacks: build tools, Go, common CLI tools, a
# PostgreSQL client matching current servers, a UTF-8 locale and /run/lock.
ARG RUNNER_VERSION=2.338.2
FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION}

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG POSTGRES_MAJOR=18
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release \
 && install -d /usr/share/postgresql-common/pgdg \
 && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
 && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential pkg-config libssl-dev git git-lfs wget jq \
      zip unzip xz-utils zstd bzip2 rsync file tzdata locales \
      openssh-client netcat-openbsd dnsutils iputils-ping sqlite3 python3 python3-venv python3-pip \
      "postgresql-client-${POSTGRES_MAJOR}" \
      # What Playwright's Chromium loads, and a virtual display for headed runs.
      libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libatspi2.0-0t64 \
      libcairo2 libcups2t64 libdbus-1-3 libdrm2 libgbm1 libglib2.0-0t64 \
      libnspr4 libnss3 libpango-1.0-0 libx11-6 libxcb1 libxcomposite1 \
      libxdamage1 libxext6 libxfixes3 libxkbcommon0 libxrandr2 \
      libfontconfig1 libfreetype6 fonts-liberation fonts-noto-color-emoji xvfb \
 && rm -rf /var/lib/apt/lists/* \
 # Go, as hosted runners have it (mise's go: backend and others build with it):
 # the current release, since the image is rebuilt weekly.
 && go=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1) \
 && curl -fsSL "https://go.dev/dl/$go.linux-amd64.tar.gz" | tar -C /usr/local -xz \
 && ln -s /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/bin/ \
 # /var/lock points at /run/lock, which a booted Ubuntu creates and a
 # container does not.
 && install -d -m 1777 /run/lock

# Docker Compose, as hosted runners have it (the base image has only buildx).
ARG COMPOSE_VERSION=5.8.0
RUN curl -fsSL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose \
 && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

USER runner

# Rust, as hosted runners have it: rustup and the current stable toolchain
# with rustfmt and clippy, in the runner's home (the image is rebuilt weekly,
# so stable stays current; jobs pinning another toolchain still get it from
# rustup).
RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable \
          --component rustfmt,clippy
ENV PATH=/home/runner/.cargo/bin:$PATH
