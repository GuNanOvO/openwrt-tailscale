---
title: APK 安装
description: 在 OpenWrt 25.12+ 上使用 APK 包管理器安装 Tailscale — 分步指南
---

# APK 安装 (OpenWrt 25.12+)

本指南适用于 **OpenWrt 25.12 或更新版本**，使用 **APK** 包管理器。  
如果使用旧版本，请前往 [OPKG 安装](/zh/guide/opkg-setup)。

## **第一步：** 下载公钥
### 添加软件源公钥到受信任密钥库：  
在你的 OpenWrt 设备上执行以下命令：  
```sh
wget -O /etc/apk/keys/gunanovo@github.io.pub \
  https://gunanovo.github.io/openwrt-tailscale/key-build.rsa.pub
```
或者手动下载公钥文件到你的OpenWrt设备的 /etc/apk/keys/ 目录下。

## **第二步：** 添加软件源
### 将软件源添加到你的 OpenWrt 配置中：  
在你的 OpenWrt 设备上执行以下命令：  
```sh
echo "https://gunanovo.github.io/openwrt-tailscale/$(cat /etc/apk/arch)/packages.adb" \
  >> /etc/apk/repositories.d/customfeeds.list
```
或者手动编辑 /etc/apk/repositories.d/customfeeds.list 文件添加以下内容：  
```
https://gunanovo.github.io/openwrt-tailscale/{你的设备架构}/packages.adb
```
请注意替换 {你的设备架构} 为你的设备架构，可使用 cat /etc/apk/arch 查看设备架构。  

## **第三步：** 安装 Tailscale
### 选择你喜欢的方式安装 Tailscale：

#### 命令行方式：
```sh
# 更新软件包列表
apk update

# 安装tailscale
apk add tailscale
```

#### Web 界面方式：
1. 打开 系统 → 软件包（System → Software）;
2. 点击 更新列表（Update lists） 以刷新软件包;
3. 搜索 "tailscale" ;
4. 安装 "tailscale" ;

> [!NOTE]
> 安装过程中出现 `"failed log upload"` 报错属于正常现象，可以放心忽略。


**安装完成。** 接下来配置 Tailscale：

[安装后配置 →](/zh/guide/post-install)
