---
title: 安装脚本
description: 一键安装脚本完整参考 — 所有 CLI 选项、安装模式、模式切换、Cron 自动更新
---

# 安装脚本

一键安装脚本是在 OpenWrt 设备上运行 Tailscale 最简单的方式。脚本会自动检测设备架构、包管理器并处理所有设置。

::: warning 请选择正确的脚本
| 脚本 | 语言 | 代理 | 适用用户 |
|------|------|------|---------|
| `install.sh` | 中文 | 内置 **第三方** GitHub 代理加速 | **中国大陆用户专用** |
| `install_en.sh` | English | 无代理 | 非中国大陆用户 |
:::

## 快速使用
### 中国大陆用户（中文版，带代理）
内置第三方 GitHub 代理加速，解决国内无法直连 GitHub 的问题。  
For Mainland China users only. For other regions, please use `install_en.sh`.
```sh
# 中国大陆用户（中文版，带代理）
wget -O /usr/sbin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
```
本仓库脚本**按原样**提供，请自行决定是否使用，本仓库不为三方代理安全性负责。你已被警告。  

### 非中国大陆用户（英文版，无代理）
英文版本，不带有任何网络代理，请在网络环境良好的情况下使用。
```sh
# 非中国大陆用户（英文版，无代理）
wget -O /usr/sbin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
```

### 自定义代理
使用你自己的 GitHub 代理。脚本只会尝试该代理 — 不会回退到内置代理。
```sh
# 自定义代理（将 URL 替换为你自己的代理）
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --custom-proxy
```

脚本会启动交互式菜单。也可以通过命令行参数跳过菜单：

```sh
# 静默持久安装
sh install.sh --persistent-install --yes

# 二进制安装到 U 盘
sh install.sh --bin-install /mnt/usb --yes

# 静默更新
sh install.sh --update --yes
```

## 命令行选项

### 通用选项

| 选项 | 说明 |
|------|------|
| `--help` | 显示帮助信息，列出所有选项 |
| `--yes` / `-y` | 跳过所有确认提示（免交互模式） |

### 安装模式（互斥）

| 选项 | 说明 |
|------|------|
| `--persistent-install` | 通过 opkg/apk 包管理器安装（重启后保留） |
| `--temp-install` | 安装到 `/tmp`（易失，重启后丢失） |
| `--bin-install [路径]` | 直接二进制复制安装，可选自定义路径 |
| `--mode persistent\|temp\|binary [路径]` | 统一模式选择器（同上） |

### 安装选项

| 选项 | 说明 |
|------|------|
| `--install-path <路径>` | 二进制模式的自定义安装路径（默认：`/usr/sbin`） |
| `--custom-proxy` | 使用自定义 GitHub 代理（不会回退到内置代理） |

### 其他操作

| 选项 | 说明 |
|------|------|
| `--uninstall` | 卸载 Tailscale（配合 `--yes` 静默执行） |
| `--update` | 更新到最新版本（自动检测安装模式） |
| `--cron-setup [间隔]` | 设置自动更新定时任务 |
| `--cron-remove` | 移除自动更新定时任务 |
| `--cron-check` | 检查并安装更新（由 cron 内部调用） |

## 安装模式详解

### 持久安装（`--persistent-install`）

使用系统的包管理器（`opkg` 或 `apk`）安装 Tailscale。由系统管理，重启后保留。

```sh
sh install.sh --persistent-install --yes
```

- 重启后保留，由系统包管理器管理
- 包含自启动 init 脚本
- 需要 opkg/apk 可用且有足够存储空间
- 根据系统下载 `.ipk`（OpenWrt 24.10）或 `.apk`（OpenWrt 25.12+）

### 临时安装（`--temp-install`）

安装到 `/tmp` 目录。文件**重启后丢失** — `/usr/sbin` 下的包装脚本会在下次运行时自动重新下载二进制（当 `/tmp/tailscaled` 不存在时）。

```sh
sh install.sh --temp-install
```

- 适用于测试或存储极其有限的设备
- 需要足够的**内存**（而非存储）来存放二进制
- 自动安装依赖：`libc`、`kmod-tun`、`ca-bundle`

### 二进制安装（`--bin-install`）

直接复制二进制文件到文件系统，不经过包管理器。适用场景：
- 没有包管理器可用
- 需要安装到外部存储（如 U 盘）
- 需要自定义安装位置

```sh
# 默认路径（/usr/sbin）
sh install.sh --bin-install

# 自定义路径（如 U 盘）
sh install.sh --bin-install /mnt/usb

# 使用 --install-path 指定
sh install.sh --bin-install --install-path /opt/bin

# 统一模式选择器
sh install.sh --mode binary /mnt/usb --yes
```

**路径校验：**
- 被屏蔽的系统关键目录：`/`、`/bin`、`/boot`、`/dev`、`/etc`、`/lib`、`/proc`、`/sbin`、`/sys`、`/usr`、`/usr/bin`、`/usr/lib`、`/var`、`/rom`、`/overlay`
- 目录不存在时自动创建
- 检查父目录写权限
- 检查目标分区可用空间

**符号链接行为：**
- 安装到自定义路径时，会在 `/usr/sbin` 创建指向实际二进制位置的符号链接
- init.d 脚本会自动修改为使用正确的二进制路径

**模式标记：**
- 标记文件 `/usr/sbin/.tailscale_install_mode` 记录安装模式和路径
- 即便二进制安装路径是 `/usr/sbin`，脚本也能正确识别为二进制安装

## 模式切换

脚本支持在任意安装模式之间切换，无需先卸载。可在交互菜单或命令行中使用：

| 从 | 到 | 菜单选项 |
|----|-----|---------|
| 临时 | 持久 | 切换到持久安装 |
| 临时 | 二进制 | 切换到二进制安装 |
| 持久 | 临时 | 切换到临时安装 |
| 持久 | 二进制 | 切换到二进制安装 |
| 二进制 | 持久 | 切换到持久安装 |
| 二进制 | 临时 | 切换到临时安装 |

切换模式时，脚本会自动：
1. 停止正在运行的 Tailscale 服务
2. 清理上一个模式的文件
3. 使用新模式安装

## 交互菜单

不带参数运行脚本会启动交互式菜单，选项会根据当前安装状态动态显示：

- **显示设备信息** — 架构、内存、存储、安装状态、版本
- **安装** — 持久 / 临时 / 二进制（仅在未安装时显示）
- **更新** — 有新版本时显示
- **卸载** — 已安装 Tailscale 时显示
- **切换模式** — 已安装 Tailscale 时显示（如临时 → 持久）
- **Cron 自动更新** — 设置 / 查看状态 / 移除（已安装时显示）
- **清理残留文件** — 当 Tailscale 文件存在但安装损坏时显示

菜单还会显示：
- 可用 / 总存储空间
- 可用 / 总内存
- 内存警告（< 60MB：可能无法运行，< 120MB：可能运行缓慢）
- 基于资源检查判断每种安装模式是否可用

## Cron 自动更新

脚本可以设置一个 cron 定时任务，自动检查并安装 Tailscale 更新。

### 间隔格式

| 格式 | 示例 | 行为 |
|------|------|------|
| 预设名称 | `daily` | 每天 04:00 检查 |
| 预设名称 | `hourly` | 每小时检查 |
| 预设名称 | `weekly` | 每周日 04:00 检查 |
| 预设名称 | `monthly` | 每月 1 号 04:00 检查 |
| 分钟数 | `30` | 每 30 分钟检查 |
| 指定时间 | `05:00` | 每天 05:00 检查 |
| 指定时间 | `22:30` | 每天 22:30 检查 |

### 安全保护

自动更新包含安全检查：**当 Tailscale 有活跃的节点连接时，会跳过更新**，防止网络正在使用时中断服务。

cron 任务会自动检测当前安装模式（持久 / 临时 / 二进制），并使用对应的更新方法。

### 示例

```sh
# 每天凌晨 4 点检查（默认）
sh install.sh --cron-setup daily

# 每 30 分钟检查
sh install.sh --cron-setup 30

# 每天 05:00 检查
sh install.sh --cron-setup 05:00

# 每小时检查
sh install.sh --cron-setup hourly

# 移除定时任务
sh install.sh --cron-remove
```

### 相关文件

| 文件 | 用途 |
|------|------|
| `/usr/sbin/tailscale-update-check` | 生成的 cron 脚本 |
| `/var/log/tailscale-update.log` | 更新日志 |
| `/etc/crontabs/root` | cron 条目（带 `# tailscale-auto-update` 标记） |

## 代理支持

### 内置代理（install.sh）

中文脚本（`install.sh`）会按顺序自动尝试多个 GitHub 代理：

1. `https://ghfast.top/`
2. `https://gh-proxy.org/`
3. `https://cdn.jsdelivr.net/gh/`
4. `https://raw.githubusercontent.com/`（直连）

脚本会测试每个代理并使用第一个可用的。如果全部失败，脚本退出。

### 自定义代理

使用 `--custom-proxy` 提供你自己的代理 URL。**使用自定义代理时，脚本只会尝试该代理** — 不会回退到内置代理。如果自定义代理不可用，脚本退出。

### DNS 优化

启动时，脚本可能会提示将系统 DNS 修改为 `223.5.5.5` 和 `119.29.29.29` 以加快域名解析。此步骤可选，仅在交互模式下提供。

## 安全与完整性

- **SHA256 校验**：所有下载的文件（包和二进制）都会通过 SHA256 校验和验证
- **下载重试**：失败的下载最多重试 3 次
- **路径校验**：二进制安装屏蔽系统关键目录
- **架构检查**：不受支持的架构会在安装前被拒绝

## 完整示例

```sh
# 交互模式（菜单引导）
sh install.sh

# 静默持久安装
sh install.sh --persistent-install --yes

# 二进制安装到 U 盘，无确认
sh install.sh --bin-install /mnt/usb --yes

# 统一模式选择器
sh install.sh --mode binary /mnt/usb --yes

# 静默更新（自动重启服务）
sh install.sh --update --yes

# 静默卸载
sh install.sh --uninstall --yes

# 设置每天 5:00 自动更新
sh install.sh --cron-setup 05:00

# 移除自动更新 cron
sh install.sh --cron-remove
```

## 下一步

- [安装后配置](/zh/guide/post-install) — 安装 Tailscale 后的配置
- [常见问题](/zh/reference/faq) — 常见问题与解决方案
- [浏览软件包](/zh/packages) — 所有可用架构
