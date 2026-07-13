---
title: 支持的架构
description: 精简版 Tailscale 软件源支持的所有 OpenWrt 架构
---

# 支持的架构

本仓库使用 OpenWrt 官方 SDK 为 **33 个 OpenWrt 目标**构建软件包。

- IPK 构建使用 OpenWrt SDK **24.10.4**
- APK 构建使用 OpenWrt SDK **25.12.0**

## 所有支持的架构

| 架构 | IPK (24.10) | APK (25.12) | UPX |
|------|:-----------:|:-----------:|:---:|
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

## 说明

- **`mips_4kec`**：OpenWrt 25.12 中已移除，仅提供 IPK。
- **`riscv64_riscv64`**：OpenWrt 25.12 中重命名为 `riscv64_generic`，仅提供 IPK。
- **`riscv64_generic`**：OpenWrt 25.12 新增目标，仅提供 APK。

## UPX 压缩

`mips64*`、`riscv64*` 和 `loongarch64*` 架构因兼容性问题不使用 UPX 压缩。其他架构均使用 UPX 压缩以减小二进制体积。

浏览所有软件包请访问[软件包页面](/zh/packages)。
