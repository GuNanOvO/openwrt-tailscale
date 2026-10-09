---
title: Install Script
description: Complete reference for the one-click install script — all CLI options, install modes, mode switching, and cron auto-update
---

# Install Script

The one-click install script is the easiest way to get Tailscale running on your OpenWrt device. It auto-detects your architecture, package manager, and handles all the setup.

::: warning Choose the Right Script
| Script | Language | Proxy | Target Users |
|--------|----------|-------|-------------|
| `install.sh` | 中文 | Built-in **third-party** GitHub proxy acceleration | **中国大陆用户专用** |
| `install_en.sh` | English | No proxy | International users |
:::

## Quick Usage

### International Users (English, no proxy)
English version, no network proxy. Please use it in a good network environment.
```sh
# International users (English, no proxy)
wget -O /usr/sbin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
```

### Mainland China Users (Chinese, with proxy)
Built-in third-party GitHub proxy acceleration to solve GitHub connectivity issues in mainland China.  
For Mainland China users only. For other regions, please use `install_en.sh`.
```sh
# Mainland China users (Chinese, with proxy)
wget -O /usr/sbin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
```
This repository provides the script **as-is**. You are responsible for deciding whether to use it. This repository is not responsible for the security of third-party proxies. You have been warned.  

### Custom Proxy
Use your own GitHub proxy. The script will only try your proxy — no fallback to built-in proxies.
```sh
# Custom proxy (replace the URL with your own proxy)
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --custom-proxy
```

The script launches an interactive menu. You can also bypass the menu with command-line arguments:

```sh
# Silent persistent install
sh install.sh --persistent-install --yes

# Binary install to USB drive
sh install.sh --bin-install /mnt/usb --yes

# Silent update
sh install.sh --update --yes
```

## Command-Line Options

### General

| Option | Description |
|--------|-------------|
| `--help` | Show help message with all options |
| `--yes` / `-y` | Skip all confirmation prompts (non-interactive mode) |

### Install Modes (mutually exclusive)

| Option | Description |
|--------|-------------|
| `--persistent-install` | Install via opkg/apk package manager (survives reboot) |
| `--temp-install` | Install to `/tmp` (volatile, lost on reboot) |
| `--bin-install [path]` | Install as binary directly. Optional: custom path |
| `--mode persistent\|temp\|binary [path]` | Unified mode selector (same as above) |

### Install Options

| Option | Description |
|--------|-------------|
| `--install-path <path>` | Custom install path for binary mode (default: `/usr/sbin`) |
| `--custom-proxy` | Use a custom GitHub proxy (install.sh only; install_en.sh has no proxy support) |

### Other Actions

| Option | Description |
|--------|-------------|
| `--uninstall` | Uninstall Tailscale (use with `--yes` for silent) |
| `--update` | Update Tailscale to latest version (auto-detects install mode) |
| `--cron-setup [interval]` | Setup automatic update cron job |
| `--cron-remove` | Remove the auto-update cron job |
| `--cron-check` | Check for update and install (called internally by cron) |

::: tip Uninstall note
If another package depends on `tailscale` in the package manager (e.g. `luci-app-tailscale-community`), the removal is refused. The script detects this and **aborts the uninstall, restoring the service**, so dependent packages are not broken; remove the dependent package first and retry.
:::

## Install Modes

### Persistent Install (`--persistent-install`)

Uses your system's package manager (`opkg` or `apk`) to install Tailscale. The package is managed by the system and survives reboots.

```sh
sh install.sh --persistent-install --yes
```

- Survives reboot, managed by system package manager
- Includes init script for auto-start
- Requires opkg/apk available and sufficient storage space
- Downloads `.ipk` (OpenWrt 24.10) or `.apk` (OpenWrt 25.12+) based on your system

### Temporary Install (`--temp-install`)

Installs Tailscale to `/tmp`. Files are **lost on reboot** — at boot the `/usr/sbin/tailscaled` wrapper triggers a **download-only** recovery (it does not start/stop the service; the init starts it).

```sh
sh install.sh --temp-install
```

- Good for testing or devices with very limited storage
- Requires sufficient **RAM** (not storage) to hold the binary
- Auto-installs dependencies: `libc`, `kmod-tun`, `ca-bundle`

### Binary Install (`--bin-install`)

Copies the Tailscale binary directly to the filesystem without using a package manager. Useful when:
- No package manager is available
- You want to install to external storage (e.g., USB drive)
- You need a custom install location

```sh
# Default path (/usr/sbin)
sh install.sh --bin-install

# Custom path (e.g., USB drive)
sh install.sh --bin-install /mnt/usb

# With explicit --install-path
sh install.sh --bin-install --install-path /opt/bin

# Unified mode selector
sh install.sh --mode binary /mnt/usb --yes
```

**Path validation:**
- Blocked system directories: `/`, `/bin`, `/boot`, `/dev`, `/etc`, `/lib`, `/proc`, `/sbin`, `/sys`, `/usr`, `/usr/bin`, `/usr/lib`, `/var`, `/rom`, `/overlay`
- Creates directory if it doesn't exist
- Checks parent directory write permissions
- Checks available space on the target partition: updates use "verify then atomic replace" and need about 1x the binary size free
- When space is short but `/tmp` is available (different filesystem), a **tight replacement** is used automatically (staged via `/tmp` with an old-program backup; do not power off during the replace)

**Symlink behavior:**
- When installing to a custom path, symlinks are created in `/usr/sbin` pointing to the actual binary location
- The init.d script is automatically modified to use the correct binary path

**Mode tracking:**
- A marker file `/usr/sbin/.tailscale_install_mode` records the install mode and path
- This allows the script to correctly detect binary installs even when the path is `/usr/sbin`

## Mode Switching

The script supports switching between any installation modes without uninstalling first. This is available in the interactive menu or via command-line:

| From | To | Menu Option |
|------|-----|-------------|
| Temp | Persistent | Switch to persistent |
| Temp | Binary | Switch to binary |
| Persistent | Temp | Switch to temp |
| Persistent | Binary | Switch to binary |
| Binary | Persistent | Switch to persistent |
| Binary | Temp | Switch to temp |

When switching modes, the script automatically:
1. Stops the running Tailscale service
2. Cleans up files from the previous mode (user config `/etc/config/tailscale` is preserved and never overwritten by defaults)
3. Installs using the new mode (the whole process is disconnect-protected)

## Disconnect Protection & Logging

Install, update and mode-switch bodies run in a **detached background session**: when operating over SSH (especially a Tailscale connection), a brief network drop or a lost connection will not interrupt the install.

- CLI and interactive-menu installs/updates/switches are all protected
- The foreground waits for the background task and prints the log tail; the full log is `/tmp/tailscale-install.log`
- On `Ctrl-C`, if the critical replacement phase is in progress, the script rolls the old program back and restores the service before exiting
- If the background task runs longer than 15 minutes you get a notice; reconnect later and check the log

## Interactive Menu

Running the script without arguments launches an interactive menu with dynamic options based on your current installation status:

- **Show device info** — Architecture, memory, storage, install status, version
- **Install** — Persistent / Temp / Binary (only shown if not installed)
- **Update** — Shown when a newer version is available
- **Uninstall** — Shown when Tailscale is installed
- **Switch mode** — Shown when Tailscale is installed (e.g., temp → persistent)
- **Cron auto-update** — Setup / view status / remove (shown when installed)
- **Clean residual files** — Shown when Tailscale files exist but installation is broken

The menu also displays:
- Available / total storage space
- Available / total memory
- Memory warnings (< 60MB: may not run, < 120MB: may be slow)
- Whether each install mode is available based on resource checks

## Cron Auto-Update

The script can set up a cron job to automatically check for and install Tailscale updates.

### Interval Formats

| Format | Example | Behavior |
|--------|---------|----------|
| `daily` | `daily` | Every day at 04:00 |
| `hourly` | `hourly` | Every hour |
| `weekly` | `weekly` | Every Sunday at 04:00 |
| `monthly` | `monthly` | Every 1st at 04:00 |
| Minutes | `30` | Every 30 minutes |
| Minutes (suffix) | `30min` | Every 30 minutes |
| Hours (suffix) | `6h` | Every 6 hours (`0 */6`) |
| Specific time | `05:00` | Every day at 05:00 |
| Specific time | `22:30` | Every day at 22:30 |

### Safety Protection

The auto-update includes a safety check: **it skips the update if Tailscale has active peers connected**. This prevents service disruption when your network is actively in use.

The cron job auto-detects your current install mode (persistent / temp / binary) and uses the matching update method.

### Examples

```sh
# Every day at 4am (default)
sh install.sh --cron-setup daily

# Every 30 minutes
sh install.sh --cron-setup 30

# Every day at 05:00
sh install.sh --cron-setup 05:00

# Every hour
sh install.sh --cron-setup hourly

# Remove cron job
sh install.sh --cron-remove
```

### Files

| File | Purpose |
|------|---------|
| `/usr/sbin/tailscale-update-check` | Generated cron script |
| `/usr/sbin/tailscale-install.sh` | Installer snapshot (cron only executes trusted `/usr/sbin` paths) |
| `/var/log/tailscale-update.log` | Update log |
| `/etc/crontabs/root` | Cron entry (tagged with `# tailscale-auto-update`) |

## Proxy Support

### Built-in Proxies (install.sh)

The Chinese script (`install.sh`) automatically tries multiple GitHub proxies in order:

1. `https://ghfast.top/`
2. `https://gh-proxy.org/`
3. `https://cdn.jsdelivr.net/gh/`
4. `https://raw.githubusercontent.com/` (direct)

The script tests each proxy and uses the first one that responds. If all fail, the script exits.

### Custom Proxy

Use `--custom-proxy` to provide your own proxy URL. **When using a custom proxy, the script only tries that proxy** — no fallback to built-in proxies. If your custom proxy is unavailable, the script exits.

### DNS Optimization

On startup, the script may prompt to change your system DNS to `223.5.5.5` and `119.29.29.29` for faster domain resolution. This is optional and only offered in interactive mode.

## Security & Integrity

- **SHA256 verification**: All downloaded files (packages and binaries) are verified with SHA256 checksums
- **Download retry**: Failed downloads are retried up to 3 times
- **Path validation**: Binary install blocks system-critical directories and only allows letters/digits/`._-` in the path
- **Config protection**: Updates/switches/boot recovery never overwrite an existing `/etc/config/tailscale`
- **Cron hardening**: The cron job only executes trusted `/usr/sbin` paths and never world-writable dirs (`/tmp`, `/mnt`)
- **Architecture check**: Unsupported architectures are rejected before installation

## Complete Examples

```sh
# Interactive mode (menu-based)
sh install.sh

# Silent persistent install
sh install.sh --persistent-install --yes

# Binary install to USB drive, no confirmations
sh install.sh --bin-install /mnt/usb --yes

# Unified mode selector
sh install.sh --mode binary /mnt/usb --yes

# Silent update (auto-restarts service)
sh install.sh --update --yes

# Silent uninstall
sh install.sh --uninstall --yes

# Setup daily auto-update at 5:00 AM
sh install.sh --cron-setup 05:00

# Remove auto-update cron
sh install.sh --cron-remove
```

## Next Steps

- [Post-Installation Configuration](/en/guide/post-install) — Configure Tailscale after installation
- [FAQ](/en/reference/faq) — Common questions and solutions
- [Browse Packages](/en/packages) — All available architectures
