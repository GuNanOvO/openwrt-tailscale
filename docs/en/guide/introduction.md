---
title: Introduction
description: What is this project, why use it, and what do you need before starting
---

# Introduction

New to this project? Start here. This page explains what the project does and what you need before installing.

## What Is This Project?

This is a community-maintained feed that provides **smaller Tailscale packages** for OpenWrt routers and devices.

[Tailscale](https://tailscale.com/) is a zero-config VPN that lets you securely connect your devices into a private network (a "tailnet"). It is built on WireGuard and works through NAT and firewalls without port forwarding.

The official OpenWrt Tailscale package can be large. This project rebuilds the **exact same Tailscale source code** with size optimizations:

- Merges `tailscale` + `tailscaled` into a single binary
- Strips optional features (AWS, Kubernetes, Taildrop, etc.) via build tags
- Applies [UPX](https://upx.github.io/) compression (`--best --lzma`)

**Result:** 30–60% smaller binary, same functionality. Ideal for routers with limited flash storage.

::: tip No Functional Changes
The source code is taken directly from the [official Tailscale repository](https://github.com/tailscale/tailscale) with no modifications. Only compiler flags and UPX compression are added. See the [Security Statement](/en/reference/security) for details.
:::

## Is This Safe to Use?

Yes. The entire build process is:

- **Open-source** — all scripts and workflows are public on GitHub
- **Automated** — packages are built by GitHub Actions, no manual uploads
- **Auditable** — every build log is publicly available
- **Reproducible** — you can build the packages yourself using the [Build Guide](/en/build/)

See the [Security Statement](/en/reference/security) for full details.

## Prerequisites

Before installing, make sure your device meets these requirements:

| Requirement | Minimum | Notes |
|-------------|---------|-------|
| OpenWrt version | 22.03 or later | 21.02 is not supported |
| Storage space | < 8 MB free | UPX-compressed binary is small |
| RAM | 256 MB recommended | Devices with less RAM may need [memory optimization](/en/guide/oom) |
| Kernel modules | `kmod-tun`, `ca-bundle` | Usually pre-installed |
| Network | Access to GitHub or a mirror | Needed to download packages |

::: warning Low-RAM Devices
If your device has less than 256 MB RAM, Tailscale may be killed by the OOM Killer. See [Memory Optimization](/en/guide/oom) for a fix that trades CPU for lower memory usage.
:::

## Package Types

OpenWrt changed its package manager starting from version 25.12. You need to pick the right package type:

| OpenWrt Version | Package Manager | Package Type |
|----------------|----------------|-------------|
| 25.12 or later | APK | `.apk` |
| 24.10 or earlier | OPKG | `.ipk` |

Not sure which version you have? The [Quick Start](/en/guide/quick-start) guide shows you how to check.

## Next Steps

- [Quick Start](/en/guide/quick-start) — Choose your installation method
- [FAQ](/en/reference/faq) — Common questions answered
- [Supported Architectures](/en/reference/architectures) — Check if your device is supported
