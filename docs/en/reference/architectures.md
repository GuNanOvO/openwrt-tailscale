---
title: Supported Architectures
description: All OpenWrt architectures supported by the smaller Tailscale package feed
---

# Supported Architectures

This repository builds packages for **33 OpenWrt targets** using the official OpenWrt SDK.

- IPK builds use OpenWrt SDK **24.10.4**
- APK builds use OpenWrt SDK **25.12.0**

## All Supported Architectures

| Architecture | IPK (24.10) | APK (25.12) | UPX |
|-------------|:-----------:|:-----------:|:---:|
| `x86_64` | ✅ | ✅ | ✅ |
| `i386_pentium-mmx` | ✅ | ✅ | ✅ |
| `i386_pentium4` | ✅ | ✅ | ✅ |
| `aarch64_cortex-a53` | ✅ | ✅ | ✅ |
| `aarch64_cortex-a72` | ✅ | ✅ | ✅ |
| `aarch64_cortex-a76` | ✅ | ✅ | ✅ |
| `aarch64_generic` | ✅ | ✅ | ✅ |
| `arm_cortex-a7` | ✅ | ✅ | ✅ |
| `arm_cortex-a7_neon-vfpv4` | ✅ | ✅ | ✅ |
| `arm_cortex-a7_vfpv4` | ✅ | ✅ | ✅ |
| `arm_cortex-a8_vfpv3` | ✅ | ✅ | ✅ |
| `arm_cortex-a9` | ✅ | ✅ | ✅ |
| `arm_cortex-a9_neon` | ✅ | ✅ | ✅ |
| `arm_cortex-a9_vfpv3-d16` | ✅ | ✅ | ✅ |
| `arm_cortex-a15_neon-vfpv4` | ✅ | ✅ | ✅ |
| `arm_cortex-a5_vfpv4` | ✅ | ✅ | ✅ |
| `arm_arm1176jzf-s_vfp` | ✅ | ✅ | ✅ |
| `arm_arm926ej-s` | ✅ | ✅ | ✅ |
| `arm_fa526` | ✅ | ✅ | ✅ |
| `arm_xscale` | ✅ | ✅ | ✅ |
| `mips_24kc` | ✅ | ✅ | ✅ |
| `mips_mips32` | ✅ | ✅ | ✅ |
| `mipsel_24kc` | ✅ | ✅ | ✅ |
| `mipsel_24kc_24kf` | ✅ | ✅ | ✅ |
| `mipsel_74kc` | ✅ | ✅ | ✅ |
| `mipsel_mips32` | ✅ | ✅ | ✅ |
| `mips64_mips64r2` | ✅ | ✅ | — |
| `mips64_octeonplus` | ✅ | ✅ | — |
| `mips64el_mips64r2` | ✅ | ✅ | — |
| `mips_4kec` | ✅ | — | ✅ |
| `riscv64_riscv64` | ✅ | — | — |
| `riscv64_generic` | — | ✅ | — |
| `loongarch64_generic` | ✅ | ✅ | — |

## Notes

- **`mips_4kec`**: Removed in OpenWrt 25.12, IPK only.
- **`riscv64_riscv64`**: Renamed to `riscv64_generic` in OpenWrt 25.12, IPK only.
- **`riscv64_generic`**: New target in OpenWrt 25.12, APK only.

## UPX Compression

UPX compression is disabled on `mips64*`, `riscv64*`, and `loongarch64*` due to compatibility issues. All other architectures are UPX-compressed to reduce binary size.

## Browse All Packages

See the [Packages page](/en/packages) for a complete, searchable listing with file sizes and SHA256 checksums.
