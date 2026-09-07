---
title: 常见问题
description: 关于精简版 Tailscale 软件包的常见问题解答
---

# 常见问题

第一次接触？先看[项目简介](/zh/guide/introduction)了解项目概况和前置要求。

## 安装

### 安装时出现 "failed log upload" 错误？

这是正常现象，可以忽略。不影响功能。

### 如何更新 Tailscale？

```sh
# APK（OpenWrt 25.12+）
apk update && apk upgrade tailscale

# OPKG（OpenWrt 24.10-）
opkg update && opkg upgrade tailscale
```

## 使用

### Tailscale 不断重启？

可能是内存不足（OOM）导致的。参见[内存优化](/zh/guide/oom)。

### 可以和 LuCI 一起用吗？

可以！安装 [luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community) 获取图形化管理界面。详见 [LuCI 管理界面](/zh/guide/luci)。

## 构建

### 如何将最新版 Tailscale 编入自编译固件？

如果你自己编译 OpenWrt 固件，且官方 `packages` feed 只提供旧版 tailscale，有两种方式：

1. **预编译 ipk 直接安装**（无需编译）：下载对应架构的 ipk 后 `opkg install`
2. **一键脚本 `build_feed.sh`**：自动替换 Go 工具链、注册 feed、移除官方旧包并编译

详细步骤见[自编译固件](/zh/build/self-build)。

### UPX 影响性能吗？

UPX 在启动时解压二进制。解压非常快（毫秒级），之后以原生速度运行。内存开销可以忽略。

## 还有问题？

- [GitHub Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) — 搜索或提交新问题
