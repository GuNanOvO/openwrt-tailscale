---
title: 手动下载安装
description: 先下载 Tailscale 软件包文件，再手动安装到 OpenWrt 设备
---

# 手动下载安装

想先下载软件包文件？按以下步骤操作。


## **第一步：** 查看设备架构。

需要准确查看设备架构，以便下载准确的架构的软件包。
::: code-group
```sh [OpenWrt 25.12+ (APK)]
cat /etc/apk/arch
```

```sh [OpenWrt 24.10- (OPKG)]
opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1
```
:::


## **第二步：** 下载软件包。
前往 [软件包](/zh/packages) 页面

- OpenWrt 24.10 或更早请下载 `.ipk` 文件
- OpenWrt 25.12 或更新请下载 `.apk` 文件

在 [软件包](/zh/packages) 页面按架构展开文件列表，再点击文件名即可直接下载。下载后将文件传输到 OpenWrt 设备（如通过 SCP、U盘、Web 上传）。


## **第三步：** 安装下载的文件。

`.ipk` 文件（OPKG）：

```sh
opkg install tailscale_*.ipk
```

`.apk` 文件（APK）：

```sh
apk add --allow-untrusted tailscale_*.apk
```


**安装完成。** 接下来配置 Tailscale：

[安装后配置 →](/zh/guide/post-install)
