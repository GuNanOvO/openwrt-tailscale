---
title: Post-Installation Configuration
description: Configure Tailscale after installation — connect to network, enable auto-start, manage updates
---

# Post-Installation Configuration

After installing Tailscale, you need to connect your device to your Tailscale network.

## Basic Setup

**Simple usage:**
```sh
# Log in to the Tailscale network
tailscale up
```

**Example usage:**
```sh
# Log in to the Tailscale network with custom hostname, no Tailscale DNS, advertise subnet routes, act as exit node
tailscale up \
  --accept-dns=false \
  --advertise-routes=10.0.0.0/24 \
  --advertise-exit-node
```

**More configuration options:** See the [OpenWrt official docs](https://openwrt.org/docs/guide-user/services/vpn/tailscale/start) or [Tailscale official docs](https://tailscale.com/docs)

::: warning OpenWrt 22.03 Users
Add `--netfilter-mode=off` to your `tailscale up` command. For OpenWrt 23+, do **not** include this flag.
:::

## Common Configuration Options

| Flag | Description |
|------|-------------|
| `--hostname=NAME` | Set a custom hostname |
| `--accept-dns=false` | Don't use Tailscale DNS |
| `--advertise-routes=x.x.x.x/xx` | Advertise subnet routes |
| `--advertise-exit-node` | Act as exit node |
| `--accept-routes` | Accept routes advertised by other devices |
| `--netfilter-mode=off` | Disable netfilter (required for OpenWrt 22.03) |

## Enable Auto-Start

```sh
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

## Check Status

```sh
/etc/init.d/tailscale status
tailscale status
tailscale ip
```

## Update Tailscale

```sh
# APK
apk update && apk upgrade tailscale

# OPKG
opkg update && opkg upgrade tailscale
```

## Uninstall

```sh
/etc/init.d/tailscale stop
/etc/init.d/tailscale disable
# For APK package manager
apk del tailscale
# For OPKG package manager
opkg remove tailscale
rm -rf /etc/tailscale /var/lib/tailscale
```

## Next Steps

- [LuCI Web UI](/en/guide/luci) — Graphical management interface
- [Memory Optimization](/en/guide/oom) — Reduce memory usage
- [FAQ](/en/reference/faq) — Common questions
