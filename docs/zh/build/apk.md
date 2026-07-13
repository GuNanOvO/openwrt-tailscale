---
title: 构建 APK 包
description: 为 OpenWrt 25.12+ 构建 .apk 包 — 前提条件、构建过程、签名
---

# 构建 APK 包 (OpenWrt 25.12+)

构建 `.apk` 软件包的指南。

## 前提条件

- Docker
- OpenWrt 25.12 SDK 容器
- Go 工具链
- UPX 二进制
- RSA 签名密钥（用于仓库索引）

## 构建命令

```sh
./build_scripts/build_apk.sh <版本> <目标架构>
```

### 示例

```sh
./build_scripts/build_apk.sh 1.100.0 x86_64
```

## 构建过程

1. 初始化 OpenWrt feeds 并安装 `golang` 包
2. 复制优化的 `package/tailscale/` 到 SDK 中
3. 设置 Go 交叉编译工具链
4. 使用优化参数编译
5. 应用 UPX 压缩
6. 生成 `packages.adb` 索引并签名

## APK 仓库索引

与 OPKG 不同，APK 使用每个架构一个索引文件（`packages.adb`），内嵌签名。

构建脚本自动：
1. 使用 `apk mkndx` 生成索引
2. 用 RSA 密钥签名
3. 验证输出
