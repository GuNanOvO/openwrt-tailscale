#!/bin/bash
# this script is used to build tailscale ipk package for openwrt
# it is expected to be run in a docker container with openwrt 24.10 sdk
# it is designed for https://github.com/GuNanOvO/openwrt-tailscale project only
# and may not work properly in other environments
# author: GuNanOvO <gunanovo@gmail.com>
# repo: https://github.com/GuNanOvO/openwrt-tailscale
# date: 2026/2/26

PKG_VERSION="$1"
TARGET_ARCH="$2"
echo "Arch: $TARGET_ARCH, Version: $PKG_VERSION"

set -e
cd /builder

# initialize feeds and install golang
echo "Initializing feeds and installing golang package..."
./scripts/feeds update packages > /dev/null
./scripts/feeds install golang > /dev/null

mkdir -p /builder/package/lang
# ln -sf /builder/feeds/packages/lang/golang /builder/package/lang/golang

# Prefer adding this repository as an OpenWrt feed (src-git) so it can be used by feeds system
# This avoids copying into package/ and makes it work like a standard feeds package.
FEED_NAME="openwrt_tailscale"
FEED_URL="https://github.com/Potterli20/openwrt-tailscale.git"
FEEDS_CONF_DEFAULT="feeds.conf.default"

# remove any local package/tailscale to avoid conflicts with the feed-provided package
rm -rf /builder/package/tailscale || true

# add the feed if it's not already present
if [ -f "$FEEDS_CONF_DEFAULT" ]; then
    if ! grep -q "^src-git ${FEED_NAME}\b" "$FEEDS_CONF_DEFAULT" 2>/dev/null; then
        echo "Adding custom feed to $FEEDS_CONF_DEFAULT: src-git ${FEED_NAME} ${FEED_URL}"
        echo "src-git ${FEED_NAME} ${FEED_URL}" >> "$FEEDS_CONF_DEFAULT"
    else
        echo "Feed ${FEED_NAME} already present in $FEEDS_CONF_DEFAULT"
    fi
else
    echo "Creating $FEEDS_CONF_DEFAULT and adding ${FEED_NAME}"
    echo "src-git ${FEED_NAME} ${FEED_URL}" > "$FEEDS_CONF_DEFAULT"
fi

# update and install feeds (prefer updating the new feed first)
./scripts/feeds update ${FEED_NAME} || ./scripts/feeds update -a
./scripts/feeds install -a

# make defconfig to generate .config with default settings, which is required for go build
make defconfig > /dev/null 2>&1

# check go binary
[ -f /builder/go/bin/go ] || { echo "Error: Go binary missing"; exit 1; }

# use the pre-prepared go binary 
# avoid dependency resolution and installation during build
# which can be time-consuming and may fail due to network issues
# mkdir for go binary and link it to staging dir for go build
mkdir -p /builder/staging_dir/hostpkg/bin
ln -sf /builder/go/bin/go /builder/staging_dir/hostpkg/bin/go
ln -sf /builder/go/bin/gofmt /builder/staging_dir/hostpkg/bin/gofmt
if [ -d /builder/staging_dir/hostpkg/lib/go-cross/bin ]; then
    ln -sf /builder/go/bin/go /builder/staging_dir/hostpkg/lib/go-cross/bin/go
fi

echo "Using $(/builder/go/bin/go version)"

# build tailscale package
echo "Building Tailscale IPK package..."
make package/tailscale/compile -j$(nproc) V=s

# check package build result
if [ -f /builder/bin/packages/${TARGET_ARCH}/base/tailscale-upx_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk ]; then
    echo "Build Success: IPK Package generated at /builder/bin/packages/${TARGET_ARCH}/base/tailscale-upx_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk"
    ls -lh /builder/bin/packages/${TARGET_ARCH}/base/
else
    echo "Error: No build product found at expected location"
    echo "Build Failed"
    exit 1
fi

# rename the generated ipk package to standard format: tailscale-upx-${PKG_VERSION}-r1.ipk
echo "Renaming generated IPK package to standard format..."
mv /builder/bin/packages/${TARGET_ARCH}/base/tailscale-upx_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk /builder/bin/packages/${TARGET_ARCH}/base/tailscale-upx-${PKG_VERSION}-r1.ipk
ls -lh /builder/bin/packages/${TARGET_ARCH}/base/tailscale-upx-${PKG_VERSION}-r1.ipk

# remove leftover/older tailscale packages so index generation won't pick the wrong package
PKG_DIR="/builder/bin/packages/${TARGET_ARCH}/base"
echo "Cleaning old tailscale packages in $PKG_DIR..."
if [ -d "$PKG_DIR" ]; then
    # remove any tailscale_*.ipk or tailscale-*.ipk except the freshly generated tailscale-upx package
    find "$PKG_DIR" -maxdepth 1 -type f \( -name 'tailscale_*.ipk' -o -name 'tailscale-*.ipk' \) \
        ! -name "tailscale-upx-${PKG_VERSION}-r1.ipk" \
        ! -name "tailscale-upx_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk" -print -exec rm -f {} \;
fi

cp /builder/keys/key-build.sec ./key-build
make package/index -j$(nproc) V=s

cd /builder/bin/packages/${TARGET_ARCH}/base
# Sign the Packages file using usign with the provided private key
# /builder/staging_dir/host/bin/usign -S -m Packages -s /builder/keys/key-build.sec

# check if the index file and signature file is generated
if [ -f Packages ] && [ -s Packages.gz ] && [ -f Packages.sig ]; then
    echo "Index Generation and Signing Success: Packages, Packages.gz, and Packages.sig generated"
    ls -lh
else
    echo "Error: Package signing failed, Packages.sig not found or empty"
    exit 1
fi
