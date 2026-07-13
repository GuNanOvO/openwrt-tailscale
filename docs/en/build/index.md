---
title: Build Overview
description: How to build smaller Tailscale packages for OpenWrt — build system, scripts, and CI/CD pipeline
---

# Build Overview

This section covers how to build the smaller Tailscale packages yourself.

## Build System

The build system uses:

- **OpenWrt SDK** (24.10 for IPK, 25.12 for APK)
- **Docker containers** for reproducible builds
- **Go toolchain** for cross-compilation
- **UPX** for binary compression

## Build Scripts

| Script | Purpose |
|--------|---------|
| `build_scripts/build_ipk.sh` | Build IPK packages (OpenWrt 24.10) |
| `build_scripts/build_apk.sh` | Build APK packages (OpenWrt 25.12+) |
| `build_scripts/prepare_go_for_openwrt.sh` | Prepare Go toolchain for OpenWrt SDK |

## CI/CD Pipeline

All builds are automated via GitHub Actions:

1. **Prepare**: Download latest UPX and Go
2. **Build Matrix**: Cross-compile for all architectures
3. **Deploy**: Publish to feed branch (GitHub Pages) + GitHub Release

## Next Steps

- [Build IPK Packages](/en/build/ipk)
- [Build APK Packages](/en/build/apk)
