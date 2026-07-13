---
title: APK Installation
description: Install Tailscale on OpenWrt 25.12+ using the APK package manager — step by step
---

# APK Installation (OpenWrt 25.12+)

This guide is for **OpenWrt 25.12 or later**, which uses the **APK** package manager.  
If you have an older version, go to [OPKG Installation](/en/guide/opkg-setup).

## **Step 1:** Download the public key
### Add the repository public key to the trusted keyring:  
Run the following command on your OpenWrt device:  
```sh
wget -O /etc/apk/keys/gunanovo@github.io.pub \
  https://gunanovo.github.io/openwrt-tailscale/key-build.rsa.pub
```
Or manually download the public key file to /etc/apk/keys/ on your OpenWrt device.

## **Step 2:** Add the repository
### Add the repository to your OpenWrt configuration:  
Run the following command on your OpenWrt device:  
```sh
echo "https://gunanovo.github.io/openwrt-tailscale/$(cat /etc/apk/arch)/packages.adb" \
  >> /etc/apk/repositories.d/customfeeds.list
```
Or manually edit /etc/apk/repositories.d/customfeeds.list and add the following:  
```
https://gunanovo.github.io/openwrt-tailscale/{your-device-architecture}/packages.adb
```
Replace {your-device-architecture} with your device architecture. Use cat /etc/apk/arch to find it.  

## **Step 3:** Install Tailscale
### Choose your preferred method to install Tailscale:

#### Command line:
```sh
# Update package lists
apk update

# Install tailscale
apk add tailscale
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
