---
title: OPKG Installation
description: Install Tailscale on OpenWrt 24.10 or earlier using the OPKG package manager — step by step
---

# OPKG Installation (OpenWrt 24.10 or earlier)

This guide is for **OpenWrt 24.10 or earlier**, which uses the **OPKG** package manager.  
If you have a newer version, go to [APK Installation](/en/guide/apk-setup).

## **Step 1:** Download and add the public key
### Add the repository public key to the trusted keyring:  
Run the following commands on your OpenWrt device:  
```sh
wget -O /tmp/key-build.pub \
  https://gunanovo.github.io/openwrt-tailscale/key-build.pub
```
```sh
opkg-key add /tmp/key-build.pub
```
Or manually download the public key file and add it via opkg-key.

## **Step 2:** Add the repository
### Add the repository to your OpenWrt configuration:  
Run the following command on your OpenWrt device:  
```sh
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)" \
  >> /etc/opkg/customfeeds.conf
```
Or manually edit /etc/opkg/customfeeds.conf and add the following:  
```
src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/{your-device-architecture}
```
Replace {your-device-architecture} with your device architecture. Use opkg print-architecture to find it.  

## **Step 3:** Install Tailscale
### Choose your preferred method to install Tailscale:

#### Command line:
```sh
# Update package lists
opkg update

# Install tailscale
opkg install tailscale
```

#### Web UI:
1. Go to System → Software;
2. Click Update lists to refresh packages;
3. Search for "tailscale";
4. Install "tailscale";

> [!NOTE]
> The `"failed log upload"` message during installation is expected and can be safely ignored.


**Done.** Now configure Tailscale:

[Post-Installation Configuration →](/en/guide/post-install)
