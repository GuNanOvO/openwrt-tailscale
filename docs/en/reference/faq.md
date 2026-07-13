---
title: FAQ
description: Frequently asked questions about the smaller Tailscale packages for OpenWrt
---

# Frequently Asked Questions

New here? See the [Introduction](/en/guide/introduction) for project overview and prerequisites.

## Installation

### "failed log upload" error during installation?

This is expected and can be safely ignored. It's a non-critical log upload attempt that doesn't affect functionality.

### How do I update Tailscale?

```sh
# APK (OpenWrt 25.12+)
apk update && apk upgrade tailscale

# OPKG (OpenWrt 24.10-)
opkg update && opkg upgrade tailscale
```

## Usage

### Tailscale keeps restarting?

This might be due to OOM (out of memory). See [Memory Optimization](/en/guide/oom) for solutions.

### Can I use this with LuCI?

Yes! Install [luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community) for a graphical management interface. See [LuCI Web UI](/en/guide/luci) for details.

## Build

### Can I build packages myself?

Yes! See the [Build Guide](/en/build/) for Docker-based build instructions.

### Does UPX affect performance?

UPX decompresses the binary at startup. The decompression is very fast (milliseconds) and the binary runs at native speed afterward. The memory overhead of decompression is negligible.

## Still have questions?

- [GitHub Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) — Search or open a new issue
