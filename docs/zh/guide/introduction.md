---
title: 项目简介
description: 本项目是什么、为什么使用、开始前需要准备什么
---

# 项目简介

第一次接触本项目？从这里开始。本页说明项目用途和安装前的准备工作。

## 本项目是什么？

这是一个社区维护的软件源，为 OpenWrt 设备提供**更小的 Tailscale 软件包**。

> [Tailscale](https://tailscale.com/) 是一个零配置 VPN，能将你的设备安全地连接到一个私有网络（称为 "tailnet"）。它基于 WireGuard，无需端口转发即可穿透 NAT 和防火墙。

OpenWrt 官方软件源的 Tailscale 软件包体积较大。本项目使用**完全相同的 Tailscale 源码**重新构建，仅做体积优化：

- 将 `tailscale` + `tailscaled` 合并为单一二进制文件
- 通过编译参数裁剪可选功能（AWS、Kubernetes、Taildrop 等）
- 使用 [UPX](https://upx.github.io/) 压缩（`--best --lzma`）

**效果：** 二进制体积减小 30–60%，功能不变。非常适合闪存空间有限的路由器。

::: tip 无功能性修改
源码直接取自 [Tailscale 官方仓库](https://github.com/tailscale/tailscale)，未做任何修改。仅添加了编译参数和 UPX 压缩。
详见 [安全声明](/zh/reference/security)。
:::

## 使用安全吗？

安全。整个构建过程：

- **开源化** — 所有脚本和工作流均在 GitHub 公开
- **自动化** — 软件包由 GitHub Actions 构建，无人工上传
- **可审计** — 每次构建日志都公开可查
- **可复现** — 你可以按照[构建指南](/zh/build/)自行构建

详见 [安全声明](/zh/reference/security)。

## 前置要求

安装前，请确认你的设备满足以下条件：

| 要求 | 最低 | 说明 |
|------|------|------|
| OpenWrt 版本 | 22.03 或更高 | 可能不支持 21.02 |
| 存储空间 | 剩余 < 8 MB | UPX 压缩后体积很小 |
| 运行内存 | 建议 256 MB | 内存较低的设备可能需要[内存优化](/zh/guide/oom) |
| 内核模块 | `kmod-tun`、`ca-bundle` | 通常已预装 |
| 网络 | 能访问 GitHub 或镜像站 | 用于下载软件包 |

::: warning 低内存设备
如果你的设备运行内存低于 256 MB，Tailscale 可能被 OOM Killer 杀死。
请参考[内存优化](/zh/guide/oom)，以更高的 CPU 占用换取更低的内存占用。
:::

## 软件包类型

OpenWrt 从 25.12 版本开始更换了包管理器，你需要选择正确的软件包类型：

| OpenWrt 版本 | 包管理器 | 软件包类型 |
|-------------|---------|-----------|
| 25.12 或更高 | APK | `.apk` |
| 24.10 或更早 | OPKG | `.ipk` |

不知道自己的版本？[快速开始](/zh/guide/quick-start)会教你如何查看。

## 下一步

- [快速开始](/zh/guide/quick-start) — 选择安装方式
- [常见问题](/zh/reference/faq) — 解答常见疑问
- [支持的架构](/zh/reference/architectures) — 查看你的设备是否受支持
