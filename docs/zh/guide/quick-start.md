---
title: 快速开始
description: 选择安装方式 — 找到在 OpenWrt 上安装 Tailscale 的正确方法
---

# 快速开始

第一次接触？先看 [项目简介](/zh/guide/introduction) ，了解项目用途和前置要求。

本页帮你选择最快的安装路径。


## 安装方式

### 方式 A：使用包管理器安装

最推荐方式。添加软件源后，由系统包管理器安装，持久化安装于设备上。  
在设备上运行命令（通过 SSH 或 LuCI 终端）快速查看你的包管理器：
```sh
# 此行如果有输出，说明是 APK 包管理器
apk --version

# 此行如果有输出，说明是 OPKG 包管理器
opkg --version
```
现在可以根据设备包管理器选择安装方式：  
APK 包管理器：请详见 [APK 安装](/zh/guide/apk-setup)  
OPKG 包管理器：请详见 [OPKG 安装](/zh/guide/opkg-setup)  

### 方式 B：一键安装脚本安装

使用自动安装脚本，自动检测架构和包管理器。  
请详见 [一键式脚本安装](/zh/guide/install-script)

### 方式 C：下载软件包自行安装

根据设备包管理器，自行下载对应的 `.ipk` 或 `.apk` 文件，再手动安装。  
适用于离线设备或自定义场景。

在设备上运行命令（通过 SSH 或 LuCI 终端）快速查看你的包管理器：
```sh
# 此行如果有输出，说明是 APK 包管理器
apk --version
# 此行如果有输出，说明是 OPKG 包管理器
opkg --version
```

请详见 [手动下载安装](/zh/guide/manual-install)


## 第三步：安装完成后

安装完成后，需要将设备接入 Tailscale 网络：  
请详见 [安装后配置](/zh/guide/post-install)


## 需要帮助？

- **有疑问？** 查看 [常见问题](/zh/reference/faq)
- **遇到问题？** 查看 [常见问题](/zh/reference/faq)
- **内存不足？** 查看 [内存优化](/zh/guide/oom)
