#!/bin/bash
#================================================================
# 在 Docker 中构建 Tailscale APK 包的便捷脚本
# 基于 build_scripts/build_apk.sh
#================================================================

set -e

PKG_VERSION="${1:-1.92.5}"
TARGET_ARCH="${2:-aarch64_cortex-a53}"

# OpenWrt SDK Docker 镜像版本 (APK 需要 25.x)
SDK_IMAGE="${SDK_IMAGE:-ghcr.io/openwrt/sdk:x86_64_25.12.0}"

echo "=========================================="
echo " Building Tailscale APK Package"
echo " Version: $PKG_VERSION"
echo " Arch:    $TARGET_ARCH"
echo " SDK:     $SDK_IMAGE"
echo "=========================================="

cd "$(dirname "$0")/../.."

docker run --rm \
    -v "$(pwd):/builder/tailscale" \
    -v "$(pwd)/feed_template/key-build.rsa:/builder/keys/key-build.rsa" \
    -v "$(pwd)/feed_template/key-build.rsa.pub:/builder/keys/key-build.rsa.pub" \
    -w /builder \
    "$SDK_IMAGE" \
    /builder/tailscale/build_scripts/build_apk.sh "$PKG_VERSION" "$TARGET_ARCH"

echo ""
echo "Build complete! Check bin/packages/${TARGET_ARCH}/base/ for the output."
