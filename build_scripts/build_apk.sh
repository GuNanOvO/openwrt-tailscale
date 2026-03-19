#!/bin/bash
# this script is used to build tailscale apk package openwrt
# it is expected to be run in a docker container with openwrt 25.12 sdk
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
./scripts/feeds update packages > /dev/null
./scripts/feeds install golang > /dev/null

mkdir -p /builder/package/lang
# ln -sf /builder/feeds/packages/lang/golang /builder/package/lang/golang

# remove original tailscale package
rm -rf /builder/package/tailscale
mkdir -p /builder/package/tailscale
# copy optimized tailscale package
# see https://github.com/GuNanOvO/openwrt-tailscale/tree/main/package/tailscale for details
cp -r /builder/tailscale/. /builder/package/tailscale/

# make defconfig to generate .config with default settings, which is required for go build
make defconfig > /dev/null 2>&1

# check go binary
[ -f /builder/go/bin/go ] || { echo "Error: Go binary missing"; exit 1; }

# use the pre-prepared go binary 
# avoid dependency resolution and installation during build
# which can be time-consuming and may fail due to network issues
# mkdir for go binary and link it to staging dir for go build
mkdir -p /builder/staging_dir/hostpkg/lib/go-1.26/bin
ln -sf /builder/go/bin/go /builder/staging_dir/hostpkg/lib/go-1.26/bin/go
ln -sf /builder/go/bin/gofmt /builder/staging_dir/hostpkg/lib/go-1.26/bin/gofmt
if [ -d /builder/staging_dir/hostpkg/lib/go-cross/bin ]; then
    ln -sf /builder/go/bin/go /builder/staging_dir/hostpkg/lib/go-cross/bin/go
fi

echo "Using $(/builder/go/bin/go version)"

# build tailscale package
make package/tailscale/compile -j$(nproc) V=s

# check package build result
if [ -f /builder/bin/packages/${TARGET_ARCH}/base/tailscale-${PKG_VERSION}-r1.apk ]; then
    echo "Build Success: APK Package generated at /builder/bin/packages/${TARGET_ARCH}/base/tailscale-${PKG_VERSION}-r1.apk"
    ls -lh /builder/bin/packages/${TARGET_ARCH}/base/
else
    echo "Error: No build product found at expected location"
    exit 1
fi

# change to package directory for index generation and signing
echo "Making index and signing index..."
cd /builder/bin/packages/${TARGET_ARCH}/base

# generate index for apk repository and sign it with the provided RSA key
/builder/staging_dir/host/bin/apk mkndx \
    --output packages.adb \
    --sign-key /builder/keys/key-build.rsa \
    --keys-dir /builder/keys/ \
    --allow-untrusted \
    tailscale-${PKG_VERSION}-r1.apk

# check if the index file and signature file is generated
if [ -f packages.adb ] ; then
    echo "Index Generation and Signing Success: packages.adb generated"
    ls -lh
else
    echo "Error: Package signing failed, packages.adb not found or empty"
    exit 1
fi