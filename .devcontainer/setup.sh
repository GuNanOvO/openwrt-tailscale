#!/bin/bash
#================================================================
# Dev Container 初始化脚本
# 在 postCreateCommand 之后运行
#================================================================

set -e

echo "=== OpenWrt Tailscale Dev Container Setup ==="

# 确保 Go 工具可用
go version
docker --version

# 安装一些 Go 工具（可选）
if command -v go &> /dev/null; then
    echo "Installing Go tools..."
    go install golang.org/x/tools/cmd/goimports@latest 2>/dev/null || true
fi

# 创建便捷命令别名
cat >> ~/.bashrc << 'EOF'

# ---- OpenWrt Tailscale Aliases ----
alias build-ipk='bash .devcontainer/scripts/build-ipk.sh'
alias build-apk='bash .devcontainer/scripts/build-apk.sh'
alias lsd='ls -lah'
alias tree='tree -C'
EOF

# 确保构建脚本可执行
chmod +x .devcontainer/scripts/*.sh

echo ""
echo "=== Setup Complete! ==="
echo "Available commands:"
echo "  build-ipk <version> <arch>  - Build IPK package"
echo "  build-apk <version> <arch>  - Build APK package"
echo ""
echo "Example:"
echo "  build-ipk 1.92.5 aarch64_cortex-a53"
