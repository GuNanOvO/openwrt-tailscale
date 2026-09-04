#!/bin/bash
# Build this repository's tailscale package inside an OpenWrt buildroot via a custom feed.
# The package keeps the official name `tailscale`, so the buildroot's stale official
# tailscale (e.g. from a frozen openwrt/packages branch) is replaced instead of duplicated.
#
# Usage:
#   # Remote mode (GitHub feed, recommended for firmware builds):
#   ./build_feed.sh /path/to/openwrt/buildroot
#
#   # Local mode (development, points the feed at a local checkout):
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale
#
#   # With a specific Go version:
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale 1.26.6
#
#   # Only compile, no index:
#   ./build_feed.sh /path/to/openwrt/buildroot --no-index
#
#   # One-line online usage (no local checkout needed):
#   bash <(curl -fsSL https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/build_scripts/build_feed.sh) /path/to/openwrt/buildroot
#
# The script is idempotent: re-running it after `./scripts/feeds update -a` re-removes
# the official tailscale and rebuilds this repository's version, so the override
# survives feed refreshes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BUILDROOT="${1:-}"
TAILSCALE_SRC="${2:-}"
GO_VERSION="${3:-1.26.6}"
BUILD_INDEX="true"
FEED_NAME="openwrt_tailscale"
REPO_URL="https://github.com/GuNanOvO/openwrt-tailscale.git"
REPO_OWNER="GuNanOvO"
REPO_NAME="openwrt-tailscale"
TARGET_ARCH=""

# -- Parse options --
for arg in "$@"; do
    case "$arg" in
        --no-index) BUILD_INDEX="false" ;;
        --help|-h)
            head -30 "$0"
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

# -- Step 1: Prepare Go toolchain --
# Override the buildroot's Go with a recent upstream release, otherwise newer
# Tailscale sources fail with "go.mod requires go >= ...".
echo ""
echo "[Step 1] Preparing Go ${GO_VERSION} toolchain..."
if [ -f "${SCRIPT_DIR}/prepare_go_for_openwrt.sh" ]; then
    bash "${SCRIPT_DIR}/prepare_go_for_openwrt.sh" "$BUILDROOT" "$GO_VERSION"
else
    # Fallback for curl|bash execution: the companion script is not on disk
    # (SCRIPT_DIR resolves to /dev/fd), download it into a temp dir instead.
    echo "  Companion script not found locally, downloading it..."
    PREPARE_TMP="$(mktemp -d)"
    trap 'rm -rf "$PREPARE_TMP"' EXIT
    curl -fsSL "https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/build_scripts/prepare_go_for_openwrt.sh" -o "$PREPARE_TMP/prepare_go_for_openwrt.sh"
    bash "$PREPARE_TMP/prepare_go_for_openwrt.sh" "$BUILDROOT" "$GO_VERSION"
fi

# -- Step 2: Set up custom feed --
echo ""
echo "[Step 2] Setting up custom feed: $FEED_NAME"

FEEDS_CONF="feeds.conf.default"
if [ -f "$FEEDS_CONF" ]; then
    cp "$FEEDS_CONF" "${FEEDS_CONF}.bak.$(date +%s)" 2>/dev/null || true
fi

# Remove any previous entry of our feed so re-runs stay clean
if [ -f "$FEEDS_CONF" ]; then
    sed -i "/^src-\(git\|link\) ${FEED_NAME} /d" "$FEEDS_CONF"
fi

if [ -n "$TAILSCALE_SRC" ] && [ -d "$TAILSCALE_SRC" ]; then
    echo "  Using local source: $TAILSCALE_SRC"
    echo "src-link ${FEED_NAME} ${TAILSCALE_SRC}" >> "$FEEDS_CONF"
else
    echo "  Using remote source: ${REPO_URL}"
    echo "src-git ${FEED_NAME} ${REPO_URL}" >> "$FEEDS_CONF"
fi

grep "^src-" "$FEEDS_CONF" | grep "$FEED_NAME" || true

# -- Step 3: Update the feed and install the package --
echo ""
echo "[Step 3] Updating feeds..."

rm -rf "feeds/${FEED_NAME}" 2>/dev/null || true
./scripts/feeds update "$FEED_NAME"
# -a is required: bare `feeds install -p <feed>` only marks the feed as
# preferred and installs nothing (silently), which leaves no symlink under
# package/feeds/<feed>/. See scripts/feeds install() in OpenWrt 24.10.
./scripts/feeds install -a -p "$FEED_NAME"

PKG_LINK="package/feeds/${FEED_NAME}/tailscale"
if [ ! -d "$PKG_LINK" ]; then
    echo "Error: Feed package not found at ${PKG_LINK}"
    find package/feeds/ -maxdepth 3 -name "Makefile" -path "*tailscale*" 2>/dev/null || true
    exit 1
fi
echo "  Package installed at: ${PKG_LINK}"

# -- Step 4: Remove the official tailscale from other feeds --
# The official packages feed (often frozen on release branches like 24.10) ships an
# old tailscale. Keeping its link around makes the build resolve the wrong Makefile.
# This runs on every invocation so it also covers re-runs after `feeds update -a`.
echo ""
echo "[Step 4] Removing official tailscale from other feeds..."
if [ -d package/feeds/packages/tailscale ]; then
    rm -rf package/feeds/packages/tailscale
    echo "  Removed package/feeds/packages/tailscale"
else
    echo "  No package/feeds/packages/tailscale found, nothing to do"
fi

# -- Step 5: Select the package in .config --
echo ""
echo "[Step 5] Selecting tailscale package..."

sed -i '/^CONFIG_PACKAGE_tailscale=/d' .config 2>/dev/null || true
echo "CONFIG_PACKAGE_tailscale=y" >> .config
make defconfig > /dev/null 2>&1

if grep -q '^CONFIG_PACKAGE_tailscale=y' .config 2>/dev/null; then
    echo "  tailscale selected in config"
else
    echo "  tailscale NOT in config, run: make menuconfig"
    exit 1
fi

# -- Step 6: Compile --
echo ""
echo "[Step 6] Compiling tailscale..."

make "$PKG_LINK"/clean 2>/dev/null || true
make "$PKG_LINK"/compile -j$(nproc) V=s

# -- Step 7: Verify build output --
echo ""
echo "[Step 7] Verifying build output..."

IPK_FILE=$(find bin/ -name "tailscale_*.ipk" -o -name "tailscale_*.apk" 2>/dev/null | head -1)
if [ -n "$IPK_FILE" ]; then
    echo "  Package generated: $IPK_FILE"
    ls -lh "$IPK_FILE"
else
    echo "Error: No package file generated!"
    find bin/ -name "tailscale*" 2>/dev/null || echo "  No tailscale files in bin/"
    exit 1
fi

# -- Step 8: Generate index (optional) --
if [ "$BUILD_INDEX" = "true" ]; then
    echo ""
    echo "[Step 8] Generating package index..."

    make package/index V=s || echo "  Warning: package index generation failed (not fatal)"

    INDEX_DIR="bin/packages/${TARGET_ARCH}/base"
    if [ -z "$TARGET_ARCH" ]; then
        INDEX_DIR=$(find bin/packages -name Packages 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)
    fi
    if [ -n "$INDEX_DIR" ] && [ -f "$INDEX_DIR/Packages" ]; then
        if grep -q "^Package: tailscale$" "$INDEX_DIR/Packages"; then
            echo "  tailscale found in Packages index"
        else
            echo "  Warning: tailscale not found in Packages index"
        fi
    fi
else
    echo ""
    echo "[Step 8] Skipped index generation (--no-index)"
fi

# -- Done --
echo ""
echo "================================================"
echo " tailscale build completed!"
echo "================================================"
echo ""
echo "Package: $IPK_FILE"
echo ""
if echo "$IPK_FILE" | grep -q "\.ipk$"; then
    echo "To install on device:  opkg install $IPK_FILE"
elif echo "$IPK_FILE" | grep -q "\.apk$"; then
    echo "To install on device:  apk add --allow-untrusted $IPK_FILE"
fi
echo ""
echo "To build the full firmware with tailscale embedded:"
echo "  make -j$(nproc) V=s"
