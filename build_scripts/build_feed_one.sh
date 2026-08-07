#!/bin/bash
# ──────────────────────────────────────────────────────────────────
# 一键编译 tailscale-upx (方案 B: 自定义 Feed)
# Usage:
#   bash build_feed_one.sh /path/to/openwrt/buildroot [/path/to/repo]
# ──────────────────────────────────────────────────────────────────
set -e

BUILDDIR="${1:-}"
REPO="${2:-/home/potter-lgy/openwrt-tailscale}"
FEED="tailscale-upx"
GO_VER="1.26.3"

[ -z "$BUILDDIR" ] && { echo "用法: $0 <OpenWrt编译根目录> [本地仓库路径]"; exit 1; }
[ -d "$BUILDDIR" ] || { echo "错误: $BUILDDIR 不存在"; exit 1; }

cd "$BUILDDIR"
echo "==> OpenWrt 根目录: $BUILDDIR"

# 1. 安装 golang feed
echo "==> [1/6] 安装 golang 依赖..."
./scripts/feeds update packages > /dev/null 2>&1
./scripts/feeds install golang > /dev/null 2>&1

# 2. 准备 Go 工具链
echo "==> [2/6] 准备 Go $GO_VER 工具链..."
GO_DIR="staging_dir/hostpkg/go"
ARCH=$(uname -m | grep -q "aarch64\|arm64" && echo "arm64" || echo "amd64")
GO_ARCHIVE="go${GO_VER}.linux-${ARCH}.tar.gz"
if [ ! -f "dl/go-toolchain/${GO_ARCHIVE}" ]; then
    mkdir -p dl/go-toolchain
    echo "  下载 Go $GO_VER ..."
    curl -fsSL -o "dl/go-toolchain/${GO_ARCHIVE}" "https://go.dev/dl/${GO_ARCHIVE}"
fi
rm -rf "$GO_DIR" && mkdir -p "$GO_DIR"
tar -C "$GO_DIR" --strip-components=1 -xzf "dl/go-toolchain/${GO_ARCHIVE}"
mkdir -p staging_dir/hostpkg/bin staging_dir/hostpkg/lib/go-cross/bin
ln -sf "$GO_DIR/bin/go" staging_dir/hostpkg/bin/go
ln -sf "$GO_DIR/bin/gofmt" staging_dir/hostpkg/bin/gofmt
ln -sf "$GO_DIR/bin/go" staging_dir/hostpkg/lib/go-cross/bin/go
"$GO_DIR/bin/go" version

# 3. 添加自定义 Feed
echo "==> [3/6] 配置自定义 Feed: $FEED ..."
CONF="feeds.conf.default"
[ -f "$CONF" ] && cp "$CONF" "${CONF}.bak"
grep -v "^src-" "$CONF" > "${CONF}.tmp" 2>/dev/null || true
if [ -d "$REPO/package/tailscale" ]; then
    echo "src-link $FEED $REPO" >> "${CONF}.tmp"
    echo "  模式: 本地链接 -> $REPO"
else
    echo "src-git $FEED https://github.com/GuNanOvO/openwrt-tailscale.git" >> "${CONF}.tmp"
    echo "  模式: 远程 Git"
fi
mv "${CONF}.tmp" "$CONF"

# 4. 更新 Feed 并安装
echo "==> [4/6] 更新 Feed ..."
./scripts/feeds update "$FEED"
./scripts/feeds install -p "$FEED" 2>/dev/null || true
./scripts/feeds install golang

# 验证包存在
PKG_PATH="feeds/$FEED/package/tailscale"
[ -d "$PKG_PATH" ] || PKG_PATH=$(find feeds/ -maxdepth 3 -name "Makefile" -path "*/tailscale/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
[ -z "$PKG_PATH" ] && { echo "错误: 找不到 tailscale-upx 包"; exit 1; }
echo "  包路径: $PKG_PATH"

# 5. 配置并编译
echo "==> [5/6] 编译 tailscale-upx ..."
echo "CONFIG_PACKAGE_tailscale-upx=y" >> .config
make defconfig > /dev/null 2>&1

# 确定编译路径
BUILD_TARGET=""
[ -d "package/feeds/$FEED/tailscale" ] && BUILD_TARGET="package/feeds/$FEED/tailscale"
[ -z "$BUILD_TARGET" ] && [ -d "feeds/$FEED/package/tailscale" ] && BUILD_TARGET="feeds/$FEED/package/tailscale"
[ -z "$BUILD_TARGET" ] && BUILD_TARGET="package/tailscale-upx"

make "$BUILD_TARGET/compile" -j$(nproc) V=s

# 6. 生成索引
echo "==> [6/6] 生成包索引 ..."
make package/index V=s

# 7. 验证产物
echo ""
echo "=== 编译结果 ==="
find bin/ -name "tailscale-upx*" 2>/dev/null
echo ""
echo "完成!"
echo "安装命令: opkg install tailscale-upx"
