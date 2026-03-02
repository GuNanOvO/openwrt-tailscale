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
if [ -f /builder/bin/packages/${TARGET_ARCH}/base/tailscale_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk ]; then
    echo "Build Success: IPK Package generated at /builder/bin/packages/${TARGET_ARCH}/base/tailscale_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk"
    ls -lh /builder/bin/packages/${TARGET_ARCH}/base/
else
    echo "Error: No build product found at expected location"
    echo "Build Failed"
    exit 1
fi

# rename the generated ipk package to standard format: tailscale_${PKG_VERSION}_${TARGET_ARCH}.ipk
echo "Renaming generated IPK package to standard format..."
mv /builder/bin/packages/${TARGET_ARCH}/base/tailscale_${PKG_VERSION}-r1_${TARGET_ARCH}.ipk /builder/bin/packages/${TARGET_ARCH}/base/tailscale_${PKG_VERSION}_${TARGET_ARCH}.ipk
ls -lh /builder/bin/packages/${TARGET_ARCH}/base/tailscale_${PKG_VERSION}_${TARGET_ARCH}.ipk

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