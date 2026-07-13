---
title: Quick Start
description: Choose your installation method — find the right way to install Tailscale on your OpenWrt device
---

# Quick Start

New here? See the [Introduction](/en/guide/introduction) to learn what this project is and check prerequisites.

This page helps you pick the fastest installation path.


## Installation Methods

### Option A: Install via package manager

Most recommended. Add the repository, then install via the system package manager. Persists across reboots.  
Run these commands on your device (via SSH or LuCI terminal) to check your package manager:
```sh
# This line outputs if you have APK
apk --version

# This line outputs if you have OPKG
opkg --version
```
Now choose your installation method based on your package manager:  
APK: See [APK Install](/en/guide/apk-setup)  
OPKG: See [OPKG Install](/en/guide/opkg-setup)  

### Option B: One-click install script

Use the automated install script. It auto-detects your architecture and package manager.  
See [One-Click Script Install](/en/guide/install-script)

### Option C: Download package and install manually

Download the `.ipk` or `.apk` file yourself, then install manually.  
Good for offline devices or custom setups.

Run these commands on your device (via SSH or LuCI terminal) to check your package manager:
```sh
# This line outputs if you have APK
apk --version

# This line outputs if you have OPKG
opkg --version
```

See [Manual Install](/en/guide/manual-install)


## Step 3: After Installation

Once Tailscale is installed, you need to connect it to your Tailscale network:  
See [Post-Installation Configuration](/en/guide/post-install)


## Need Help?

- **Questions?** See the [FAQ](/en/reference/faq)
- **Something broken?** See the [FAQ](/en/reference/faq)
- **Low RAM?** See [Memory Optimization](/en/guide/oom)
