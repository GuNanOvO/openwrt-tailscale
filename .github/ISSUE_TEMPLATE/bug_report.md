---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: GuNanOvO

---

# Bug Report / 问题反馈

## Before Submitting / 提交前请确认

Please first determine which repository your issue belongs to:

请先确认你的问题属于哪个仓库：

### This repository (openwrt-tailscale)

Use this repository if your issue is related to:

以下问题请提交到本仓库：

* Tailscale binary package installation
* Tailscale package update failure
* Package repository issues
* Missing package for a specific architecture
* Binary startup failure
* Package dependency issues
* APK/IPK package issues

例如：

* 软件源无法安装
* 找不到对应架构的软件包
* APK/IPK 安装失败
* tailscaled 无法启动
* 软件包依赖异常

---

### LuCI Repository (luci-app-tailscale-community)

Use the LuCI repository if your issue is related to:

以下问题请提交到 LuCI 仓库：

* LuCI web interface
* LuCI page display issues
* Login page issues
* Configuration page issues
* Button/function not working in LuCI
* Frontend UI problems

例如：

* LuCI 页面打不开
* LuCI 页面显示异常
* LuCI 配置无法保存
* 按钮点击无效
* Web UI 问题

Repository / 仓库：

https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community

---

### If You Created Issues in Both Repositories

If you have already opened an issue in the LuCI repository, please provide the link here:

如果你同时在 LuCI 仓库提交了 Issue，请提供链接：

Issue Link:

```
https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community/issues/xxx
```

---

# Issue Type / 问题类型

Please select one:

请选择一项：

* [ ] Package installation issue / 软件包安装问题
* [ ] Package update issue / 软件包更新问题
* [ ] Binary execution issue / 二进制运行问题
* [ ] Package dependency issue / 软件包依赖问题
* [ ] Architecture-specific issue / 特定架构问题
* [ ] Build/Compile issue / 编译问题
* [ ] Repository issue / 软件源问题
* [ ] Other / 其他

---

# OpenWrt Information / OpenWrt 信息

OpenWrt Distribution:

```
OpenWrt / ImmortalWrt / FriendlyWrt / Others
```

Version:

```
23.05 / 24.10 / SNAPSHOT / ...
```

Target Architecture:

```
x86_64
aarch64
arm_cortex-a7
mipsel_24kc
riscv64
...
```

Kernel Version:

```
uname -r
```

---

# Tailscale Information / Tailscale 信息

Installed Package Version:

已安装软件包版本：

```sh
tailscale version
```

or

```sh
opkg list-installed | grep tailscale
```

or

```sh
apk info | grep tailscale
```

---

# Describe the Bug / 问题描述

A clear and concise description of the issue.

请清晰描述问题。

---

# Reproduction Steps / 复现步骤

1.
2.
3.
4.

---

# Expected Behavior / 预期行为

Describe what you expected to happen.

描述你预期发生的情况。

---

# Logs / 日志

For startup issues:

启动问题请提供：

```sh
logread | grep tailscale
```

For service status:

服务状态：

```sh
/etc/init.d/tailscale status
```

For package information:

软件包信息：

```sh
tailscaled --version
```

For compile issues:

编译问题请提供完整编译日志，至少包含报错前后 50 行内容。

---

# Screenshots / 截图

If applicable, add screenshots.

如有截图请附上。

---

# Additional Information / 其他信息

Add any additional context here.

补充任何可能有帮助的信息。

## Checklist

- [ ] This issue is related to the Tailscale binary package / 我确认问题与 Tailscale 二进制软件包有关 
- [ ] This issue is NOT related to the LuCI web interface / 我确认问题不是 LuCI Web 界面问题
- [ ] I have read the README / 我已经阅读 README
