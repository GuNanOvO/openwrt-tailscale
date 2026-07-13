---
title: Build APK Packages
description: Build .apk packages for OpenWrt 25.12+ — prerequisites, process, and signing
---

# Build APK Packages (OpenWrt 25.12+)

Guide to building `.apk` packages.

## Prerequisites

- Docker
- OpenWrt 25.12 SDK container
- Go toolchain
- UPX binary
- RSA signing key (for repository index)

## Build Command

```sh
./build_scripts/build_apk.sh <version> <target_arch>
```

### Example

```sh
./build_scripts/build_apk.sh 1.100.0 x86_64
```

## Build Process

1. Initialize OpenWrt feeds and install `golang` package
2. Copy optimized `package/tailscale/` into the SDK
3. Set up Go cross-compilation toolchain
4. Build with optimized tags
5. Apply UPX compression
6. Generate `packages.adb` index with signature

## APK Repository Index

Unlike OPKG, APK uses a single index file (`packages.adb`) per architecture with embedded signatures.

The build script automatically:
1. Generates the index with `apk mkndx`
2. Signs it with the RSA key
3. Validates the output
