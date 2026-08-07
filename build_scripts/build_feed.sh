#!/bin/bash
# Build tailscale-upx for OpenWrt using custom feed (方案 B)
# Supports both local (src-link) and remote (src-git) feed modes
#
# Usage:
#   # Local mode (recommended for development):
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale
#
#   # Remote mode (GitHub):
#   ./build_feed.sh /path/to/openwrt/buildroot
#
#   # With custom Go version:
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale 1.26.3
#
#   # Only compile, no index:
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale --no-index

set -euo pipefail

BUILDROOT="${1:-}"
TAILSCALE_SRC="${2:-}"
GO_VERSION="${3:-1.26.3}"
BUILD_INDEX="true"
FEED_NAME="tailscale-upx"
TARGET_ARCH=""

# ── Parse options ──
for arg in "$@"; do
    case "$arg" in
        --no-index) BUILD_INDEX="false" ;;
        --help|-h)
            head -20 "$0"
            exit 0
            ;;
    esac
done

if [ -z "$BUILDROOT" ] || [ ! -d "$BUILDROOT" ]; then
    echo "Error: OpenWrt buildroot directory required"
    echo "Usage: $0 /path/to/openwrt/buildroot [/path/to/openwrt-tailscale] [go_version] [--no-index]"
    exit 1
fi

cd "$BUILDROOT"

echo "=== OpenWrt Buildroot: $BUILDROOT ==="

# ── Auto-detect target arch ──
if [ -f ".config" ]; then
    TARGET_ARCH=$(grep 'CONFIG_TARGET_' .config | head -1 | sed 's/CONFIG_TARGET_//;s/=.*//' | tr '_' '-')
fi
if [ -z "$TARGET_ARCH" ]; then
    TARGET_ARCH="aarch64_cortex-a53"
    echo "Warning: Could not detect target arch, using default: $TARGET_ARCH"
fi
echo "=== Target Arch: $TARGET_ARCH ==="

# ── Step 1: Prepare Go toolchain ──
echo ""
echo "[Step 1] Preparing Go ${GO_VERSION} toolchain..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/prepare_go_for_openwrt.sh" ]; then
    bash "${SCRIPT_DIR}/prepare_go_for_openwrt.sh" "$BUILDROOT" "$GO_VERSION"
else
    bash "$(dirname "$0")/prepare_go_for_openwrt.sh" "$BUILDROOT" "$GO_VERSION" 2>/dev/null || {
        echo "Warning: prepare_go_for_openwrt.sh not found, skipping Go version override"
    }
fi

# ── Step 2: Set up custom feed ──
echo ""
echo "[Step 2] Setting up custom feed: $FEED_NAME"

# Backup feeds.conf.default if it exists
FEEDS_CONF="feeds.conf.default"
if [ -f "$FEEDS_CONF" ]; then
    cp "$FEEDS_CONF" "${FEEDS_CONF}.bak.$(date +%s)" 2>/dev/null || true
fi

# Remove old feed entry if exists
if [ -f "$FEEDS_CONF" ]; then
    sed -i "/^src-\(git\|link\) ${FEED_NAME} /d" "$FEEDS_CONF"
fi

if [ -n "$TAILSCALE_SRC" ] && [ -d "$TAILSCALE_SRC" ]; then
    echo "  Using local source: $TAILSCALE_SRC"
    echo "src-link ${FEED_NAME} ${TAILSCALE_SRC}" >> "$FEEDS_CONF"
    FEED_MODE="link"
else
    echo "  Using remote source: https://github.com/GuNanOvO/openwrt-tailscale.git"
    echo "src-git ${FEED_NAME} https://github.com/GuNanOvO/openwrt-tailscale.git" >> "$FEEDS_CONF"
    FEED_MODE="git"
fi

echo "  Feed config:"
grep "^src-" "$FEEDS_CONF" | grep "$FEED_NAME" || true

# ── Step 3: Update feeds and install golang ──
echo ""
echo "[Step 3] Updating feeds..."

# Remove old feed if present to avoid conflicts
rm -rf "feeds/${FEED_NAME}" 2>/dev/null || true
rm -rf "package/feeds/${FEED_NAME}" 2>/dev/null || true

./scripts/feeds update "$FEED_NAME"
./scripts/feeds update packages
./scripts/feeds install golang

echo "  Verifying feed contents..."
if [ -d "feeds/${FEED_NAME}/package/tailscale" ]; then
    echo "  Feed package found: feeds/${FEED_NAME}/package/tailscale/"
    ls -la "feeds/${FEED_NAME}/package/tailscale/"
else
    echo "Error: Feed package not found!"
    find feeds/ -name "Makefile" -path "*/tailscale*" 2>/dev/null || true
    exit 1
fi

# ── Step 4: Generate defconfig and select package ──
echo ""
echo "[Step 4] Selecting tailscale-upx package..."

# Remove any conflicting official tailscale selection
sed -i '/^CONFIG_PACKAGE_tailscale=/d' .config 2>/dev/null || true

# Select tailscale-upx
grep -q '^CONFIG_PACKAGE_tailscale-upx=' .config 2>/dev/null || {
    echo "CONFIG_PACKAGE_tailscale-upx=y" >> .config
}
sed -i 's/^CONFIG_PACKAGE_tailscale-upx=m/CONFIG_PACKAGE_tailscale-upx=y/' .config

make defconfig

# Verify selection
if grep -q '^CONFIG_PACKAGE_tailscale-upx=y' .config 2>/dev/null; then
    echo "  tailscale-upx selected in config"
else
    echo "  tailscale-upx NOT in config, trying menuconfig..."
    echo "  Please select: Network -> VPN -> tailscale-upx"
    make menuconfig
fi

# ── Step 5: Compile tailscale-upx ──
echo ""
echo "[Step 5] Compiling tailscale-upx..."

# Determine the package build path
BUILD_PKG_PATH=""
if [ -d "package/feeds/${FEED_NAME}/tailscale" ]; then
    BUILD_PKG_PATH="package/feeds/${FEED_NAME}/tailscale"
elif [ -d "feeds/${FEED_NAME}/package/tailscale" ]; then
    BUILD_PKG_PATH="package/feeds/${FEED_NAME}/tailscale"
elif [ -d "package/tailscale-upx" ]; then
    BUILD_PKG_PATH="package/tailscale-upx"
else
    echo "  Searching for build path..."
    BUILD_PKG_PATH=$(find . -maxdepth 4 -path "*/tailscale/Makefile" 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)
fi

if [ -z "$BUILD_PKG_PATH" ]; then
    echo "Error: Cannot find package build path!"
    echo "Try: make menuconfig"
    exit 1
fi

echo "  Build path: $BUILD_PKG_PATH"

# Clean previous build artifacts
make "$BUILD_PKG_PATH"/clean 2>/dev/null || true

# Compile
make "$BUILD_PKG_PATH"/compile -j$(nproc) V=s

# ── Step 6: Verify build output ──
echo ""
echo "[Step 6] Verifying build output..."

IPK_FILE=$(find bin/ -name "tailscale-upx_*.ipk" -o -name "tailscale-upx_*.apk" 2>/dev/null | head -1)
if [ -n "$IPK_FILE" ]; then
    echo "  Package generated: $IPK_FILE"
    ls -lh "$IPK_FILE"
else
    echo "Error: No package file generated!"
    echo "Checking bin/ contents..."
    find bin/ -name "tailscale*" 2>/dev/null || echo "No tailscale files in bin/"
    exit 1
fi

# ── Step 7: Generate index (optional) ──
if [ "$BUILD_INDEX" = "true" ]; then
    echo ""
    echo "[Step 7] Generating package index..."

    KEY_FILE="${BUILDROOT}/key-build"
    if [ ! -f "$KEY_FILE" ]; then
        echo "  Creating signing key..."
        make buildinfo KEY=$KEY_FILE 2>/dev/null || {
            # Generate key if not exists
            openssl ecparam -name prime256v1 -genkey -noout -out "$KEY_FILE" 2>/dev/null || true
        }
    fi

    make package/index V=s

    echo "  Index files:"
    INDEX_DIR="bin/packages/${TARGET_ARCH}/base"
    if [ -d "$INDEX_DIR" ]; then
        ls -lh "$INDEX_DIR"/Packages* 2>/dev/null || echo "  No Packages files found"
    fi

    # Verify index contains tailscale-upx
    if [ -f "${INDEX_DIR}/Packages" ]; then
        if grep -q "^Package: tailscale-upx" "${INDEX_DIR}/Packages"; then
            echo "  tailscale-upx found in Packages index!"
        else
            echo "  Warning: tailscale-upx not found in Packages index"
        fi
    fi
else
    echo ""
    echo "[Step 7] Skipped index generation (--no-index)"
fi

# ── Done ──
echo ""
echo "================================================"
echo " tailscale-upx build completed!"
echo "================================================"
echo ""
echo "Package: $IPK_FILE"
echo ""
echo "To install on device:"
if echo "$IPK_FILE" | grep -q "\.ipk$"; then
    echo "  opkg install $IPK_FILE"
elif echo "$IPK_FILE" | grep -q "\.apk$"; then
    echo "  apk add --allow-untrusted $IPK_FILE"
fi
echo ""
echo "Or copy to device and use:"
echo "  opkg install tailscale-upx  # if using custom feed repo"
echo ""
echo "To start tailscale on device:"
echo "  /etc/init.d/tailscale enable"
echo "  /etc/init.d/tailscale start"
echo "  tailscale up"
