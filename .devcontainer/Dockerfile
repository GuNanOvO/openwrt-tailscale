#-------------------------------------------------------------------------------------------------------------
# Copyright (c) GuNanOvO. All rights reserved.
# Licensed under the BSD-3-Clause License.
#-------------------------------------------------------------------------------------------------------------

ARG VARIANT="ubuntu-24.04"

FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

# 安装基础工具和构建依赖
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        # 构建工具
        build-essential \
        make \
        cmake \
        autoconf \
        automake \
        pkg-config \
        # Docker CLI (用于运行 OpenWrt SDK Docker 构建)
        docker.io \
        docker-compose-v2 \
        # Shell 脚本工具
        shellcheck \
        bash-completion \
        # 网络工具
        curl \
        wget \
        ca-certificates \
        gnupg \
        jq \
        # 版本控制
        git \
        # 文本处理
        vim \
        nano \
        tree \
        gettext \
        # OpenWrt 相关
        upx-ucl \
        # 其他工具
        file \
        rsync \
        unzip \
        xz-utils \
        socat \
    # GitHub CLI (通过官方仓库安装，避免依赖 ghcr.io features)
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get -y install --no-install-recommends gh \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js (VitePress 文档开发需要)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && node --version && npm --version \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# 安装 Go (编译 Tailscale 需要)
ARG GO_VERSION="1.23.4"
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
        amd64) GO_ARCH="amd64" ;; \
        arm64) GO_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
    esac; \
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm /tmp/go.tar.gz; \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go; \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt; \
    go version

# 配置 Go 环境
ENV GOPATH="/home/vscode/go" \
    PATH="/home/vscode/go/bin:${PATH}"

# 为 vscode 用户创建 Go 目录并设置权限
RUN mkdir -p /home/vscode/go && chown -R vscode:vscode /home/vscode/go

# 配置 Docker 用户组 (使用主机的 docker.sock)
RUN groupadd -g 999 docker 2>/dev/null || true; \
    usermod -aG docker vscode || true

# 设置工作目录
WORKDIR /workspace
