---
title: 构建概览
description: 自行构建精简版 Tailscale 软件包 — 构建系统、脚本、CI/CD 流水线
---

# 构建概览

本部分介绍如何自行构建精简版 Tailscale 软件包。

## 构建系统

使用以下工具链：

- **OpenWrt SDK**（24.10 用于 IPK，25.12 用于 APK）
- **Docker 容器**用于可复现构建
- **Go 工具链**用于交叉编译
- **UPX**用于二进制压缩

## 构建脚本

| 脚本 | 用途 |
|------|------|
| `build_scripts/build_ipk.sh` | 构建 IPK 包 (OpenWrt 24.10) |
| `build_scripts/build_apk.sh` | 构建 APK 包 (OpenWrt 25.12+) |
| `build_scripts/prepare_go_for_openwrt.sh` | 为 OpenWrt SDK 准备 Go 工具链 |

## CI/CD 流水线

所有构建通过 GitHub Actions 自动化：

1. **准备**：下载最新 UPX 和 Go
2. **构建矩阵**：为所有架构交叉编译
3. **部署**：发布到 feed 分支（GitHub Pages）+ GitHub Release

## 下一步

- [构建 IPK 包](/zh/build/ipk)
- [构建 APK 包](/zh/build/apk)
