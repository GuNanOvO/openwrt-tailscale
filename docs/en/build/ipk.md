---
title: Build IPK Packages
description: Build .ipk packages for OpenWrt 24.10 and earlier — prerequisites, process, and output
---

# Build IPK Packages (OpenWrt 24.10)

Guide to building `.ipk` packages.

## Prerequisites

- Docker
- OpenWrt 24.10 SDK container
- Go toolchain (prepared by `prepare_go_for_openwrt.sh`)
- UPX binary

## Build Command

```sh
./build_scripts/build_ipk.sh <version> <target_arch>
```

### Example

```sh
./build_scripts/build_ipk.sh 1.100.0 x86_64
```

## Build Process

1. Initialize OpenWrt feeds and install `golang` package
2. Copy optimized `package/tailscale/` into the SDK
3. Set up Go cross-compilation toolchain
4. Build with optimized tags
5. Apply UPX compression (except mips64/riscv64/loongarch64)
6. Generate package in `bin/packages/<arch>/base/`

## Output

- `tailscale_<version>_<arch>.ipk` — Installable package
- The binary is compressed with UPX `--best --lzma`

## Architecture Notes

| Architecture | UPX | Notes |
|-------------|-----|-------|
| x86_64, aarch64, arm, mips, mipsel, i386 | ✅ | UPX compressed |
| mips64, riscv64, loongarch64 | ❌ | UPX skipped (compatibility) |
