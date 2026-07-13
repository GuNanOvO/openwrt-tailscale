---
title: Manual Package Installation
description: Download the Tailscale package file and install it manually on your OpenWrt device
---

# Manual Package Installation

Prefer to download the package file first? Follow these steps.


## **Step 1:** Find your device architecture.

You need to find your exact device architecture to download the correct package.
::: code-group
```sh [OpenWrt 25.12+ (APK)]
cat /etc/apk/arch
```

```sh [OpenWrt 24.10- (OPKG)]
opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1
```
:::


## **Step 2:** Download the package.

Go to the [Packages](/en/packages) page

- OpenWrt 24.10 or earlier → download `.ipk` file
- OpenWrt 25.12 or later → download `.apk` file

Expand the file list by architecture on the [Packages](/en/packages) page, then click the file name to download directly. Transfer the file to your OpenWrt device (e.g., via SCP, USB, or web upload).


## **Step 3:** Install the downloaded file.

For `.ipk` (OPKG):

```sh
opkg install tailscale_*.ipk
```

For `.apk` (APK):

```sh
apk add --allow-untrusted tailscale_*.apk
```


**Done.** Now configure Tailscale:

[Post-Installation Configuration →](/en/guide/post-install)
