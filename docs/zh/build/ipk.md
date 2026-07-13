---
title: 构建 IPK 包
description: 为 OpenWrt 24.10 构建 .ipk 包 — 前提条件、构建过程、输出
---

# 构建 IPK 包 (OpenWrt 24.10)

构建 `.ipk` 软件包的指南。

## 前提条件

- Docker
- OpenWrt 24.10 SDK 容器
- Go 工具链（由 `prepare_go_for_openwrt.sh` 准备）
- UPX 二进制

## 构建命令

```sh
./build_scripts/build_ipk.sh <版本> <目标架构>
```

### 示例

```sh
./build_scripts/build_ipk.sh 1.100.0 x86_64
```

## 构建过程

1. 初始化 OpenWrt feeds 并安装 `golang` 包
2. 复制优化的 `package/tailscale/` 到 SDK 中
3. 设置 Go 交叉编译工具链
4. 使用优化参数编译
5. 应用 UPX 压缩（mips64/riscv64/loongarch64 除外）
6. 生成包到 `bin/packages/<arch>/base/`

## 输出

- `tailscale_<版本>_<架构>.ipk` — 可安装的软件包
- 二进制使用 UPX `--best --lzma` 压缩

## 架构说明

| 架构 | UPX | 备注 |
|------|-----|------|
| x86_64, aarch64, arm, mips, mipsel, i386 | ✅ | UPX 压缩 |
| mips64, riscv64, loongarch64 | ❌ | 跳过 UPX（兼容性问题） |
