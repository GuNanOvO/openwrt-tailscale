---
title: OPKG 安装
description: 在 OpenWrt 24.10 或更早版本上使用 OPKG 包管理器安装 Tailscale — 分步指南
---

# OPKG 安装 (OpenWrt 24.10 或更早)

本指南适用于 **OpenWrt 24.10 或更早版本**，使用 **OPKG** 包管理器。  
如果使用新版本，请前往 [APK 安装](/zh/guide/apk-setup)。

## **第一步：** 下载并添加公钥
### 将软件源公钥添加到受信任密钥库：  
在你的 OpenWrt 设备上执行以下命令：  
```sh
wget -O /tmp/key-build.pub \
  https://gunanovo.github.io/openwrt-tailscale/key-build.pub
```
```sh
opkg-key add /tmp/key-build.pub
```
或者手动下载公钥文件并通过 opkg-key 添加。

## **第二步：** 添加软件源
### 将软件源添加到你的 OpenWrt 配置中：  
在你的 OpenWrt 设备上执行以下命令：  
```sh
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)" \
  >> /etc/opkg/customfeeds.conf
```
或者手动编辑 /etc/opkg/customfeeds.conf 文件添加以下内容：  
```
src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/{你的设备架构}
```
请注意替换 {你的设备架构} 为你的设备架构，可使用 opkg print-architecture 查看设备架构。  

## **第三步：** 安装 Tailscale
### 选择你喜欢的方式安装 Tailscale：

#### 命令行方式：
```sh
# 更新软件包列表
opkg update

# 安装tailscale
opkg install tailscale
```

#### Web 界面方式：
1. 打开 系统 → 软件包（System → Software）;
2. 点击 刷新列表（Update lists） 以刷新软件包;
3. 搜索 "tailscale" ;
4. 安装 "tailscale" ;

> [!NOTE]
> 安装过程中出现 `"failed log upload"` 报错属于正常现象，可以放心忽略。


**安装完成。** 接下来配置 Tailscale：

[安装后配置 →](/zh/guide/post-install)
