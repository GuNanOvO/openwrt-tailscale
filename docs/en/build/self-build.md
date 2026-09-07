---
title: Self-Build Firmware
description: Embed the latest tailscale from this repository in self-built OpenWrt firmware — build_feed.sh usage and alternatives
---

# Self-Build Firmware (Buildroot)

Guide to embedding this repository's tailscale into a self-built OpenWrt firmware.

## When to Use

- You compile your own OpenWrt firmware and want the latest tailscale built in
- The official packages feed stopped updating tailscale (e.g. frozen 24.10 branches still ship an old version)

## Option 1: Install the Prebuilt IPK Directly (No Compilation)

If you just want the latest version on an existing firmware, install the prebuilt ipk from this repository — the steps are identical to a standard install, see [Manual Install](/en/guide/manual-install). No buildroot needed.

> Note: after a firmware upgrade, preinstalled packages are restored to the firmware's built-in version and need to be reinstalled.

## Option 2: One-Click Script (build_feed.sh)

Automates the whole process inside your buildroot: replaces the Go toolchain, registers this repository as a feed, removes the stale official package, and selects + builds tailscale.

### One-Line Run (No Local Checkout)

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/build_scripts/build_feed.sh) /path/to/openwrt/buildroot
```

### Local Mode (Development)

```sh
./build_scripts/build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale
```

The second argument points to a local checkout of this repository, mounted via `src-link`.

### Options

| Option | Description |
|--------|-------------|
| `--no-compile` | Set up the feed and select the package only, no compilation (implies `--no-index`) |
| `--no-index` | Skip `make package/index` |
| `--go-version <ver>` | Pin the Go toolchain version (default: auto-detect latest stable) |
| `-h` / `--help` | Show full help |

Environment variables: `JOBS` (parallel jobs), `REPO_URL` (mirror URL), `GO_VERSION` (pinned Go version).

### Process

1. Resolve the Go version (auto-detected unless pinned; offline fallback 1.26.6)
2. Override the buildroot's Go with `prepare_go_for_openwrt.sh`
3. Register the `openwrt_tailscale` feed
4. Remove the official tailscale links from other feeds
5. Install this repository's package and enable `CONFIG_PACKAGE_tailscale=y`
6. Compile and verify the output

The script is idempotent: after `./scripts/feeds update -a` brings the official package back, re-run the script to restore the override.

## Manual Steps (Alternative)

For a fully manual approach, see `package/tailscale/FORK.md` in the repository.

## Maintenance

`build_feed.sh` is a community contribution (maintained by [@Potterli20](https://github.com/Potterli20), originating from [issue #142](https://github.com/GuNanOvO/openwrt-tailscale/issues/142)) and is not part of this repository's core distribution workflow. Please submit script issues via [GitHub PR](https://github.com/GuNanOvO/openwrt-tailscale/pulls).