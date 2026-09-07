---
title: 自编译固件
description: 在自编译 OpenWrt 固件中嵌入本仓库的最新 tailscale — build_feed.sh 用法与替代方案
---

# 自编译固件 (Buildroot)

在自编译固件的 buildroot 中嵌入本仓库 tailscale 的指南。

## 适用场景

- 自行编译 OpenWrt 固件，希望固件内置最新版 tailscale
- 官方 packages feed 的 tailscale 已停止更新（例如 24.10 冻结分支仍停留在旧版本）

## 方式一：预编译 ipk 直接安装（无需编译）

如果只是想让现有固件用上最新版，直接安装本仓库预编译的 ipk 即可——步骤与标准安装完全相同，见[手动下载安装](/zh/guide/manual-install)，无需 buildroot。

> 注意：固件升级后预安装的包会被恢复为固件内置版本，需要重新安装。

## 方式二：一键脚本 build_feed.sh

在 buildroot 中自动完成：替换 Go 工具链 → 注册本仓库为 feed → 移除官方旧包 → 选中并编译。

### 一行式运行（无需本地检出）

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/build_scripts/build_feed.sh) /path/to/openwrt/buildroot
```

### 本地模式（开发调试）

```sh
./build_scripts/build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale
```

第二个参数指向本仓库的本地检出目录，以 `src-link` 方式挂载。

### 常用参数

| 参数 | 说明 |
|------|------|
| `--no-compile` | 只配置 feed 与勾选包，不编译（隐含 `--no-index`） |
| `--no-index` | 跳过 `make package/index` |
| `--go-version <版本>` | 固定 Go 工具链版本（默认自动检测最新稳定版） |
| `-h` / `--help` | 显示完整帮助 |

其他环境变量：`JOBS`（并行度）、`REPO_URL`（镜像地址）、`GO_VERSION`（固定 Go 版本）。

### 流程

1. 确定 Go 版本（未指定时自动检测，离线回退 1.26.6）
2. 用 `prepare_go_for_openwrt.sh` 覆盖 buildroot 自带 Go
3. 注册 `openwrt_tailscale` feed
4. 移除其他 feed 中的官方 tailscale 链接
5. 安装本仓库包并勾选 `CONFIG_PACKAGE_tailscale=y`
6. 编译并校验产物

脚本可重复执行：`./scripts/feeds update -a` 后官方旧包会复活，重跑一次脚本即可恢复。

## 手动步骤（备选）

如果希望完全手动操作，详见仓库内的 `package/tailscale/FORK.md`。

## 维护说明

`build_feed.sh` 为社区贡献（由 [@Potterli20](https://github.com/Potterli20) 维护，源自 [issue #142](https://github.com/GuNanOvO/openwrt-tailscale/issues/142)），不在本仓库核心分发流程内。脚本问题请通过 [GitHub PR](https://github.com/GuNanOvO/openwrt-tailscale/pulls) 提交。