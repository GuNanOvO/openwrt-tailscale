---
name: Quesiton
about: Ask for usage guidance, build assistance, firmware integration advice, or development
  help.
title: "[HELP]"
labels: question
assignees: GuNanOvO

---

# Question / Help Request / 问题咨询与使用帮助

## Before Submitting / 提交前请确认

### This Repository Maintains

本仓库维护：

* Tailscale binary packages
* OpenWrt package repository
* Package build and release process

即：

* Tailscale 二进制软件包
* OpenWrt 软件源
* 软件包构建与发布

---

### LuCI Interface Issues Belong Elsewhere

以下问题请前往 LuCI 仓库：

* LuCI 页面打不开
* LuCI 页面显示异常
* 配置页面问题
* Web UI 问题
* 按钮点击无效

Repository:

https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community/issues

---

## Checklist / 提交前检查

* [ ] I have read the README.
* [ ] I searched existing Issues before creating this one.
* [ ] My question is related to this repository.
* [ ] My question is NOT about the LuCI web interface.

---

# Question Category / 问题分类

Please select one or more:

请选择适用项：

* [ ] Installation / 安装问题
* [ ] Package Repository / 软件源问题
* [ ] Upgrade / 更新问题
* [ ] Build & Compile / 编译问题
* [ ] Firmware Integration / 固件集成
* [ ] OpenWrt SDK / SDK 相关
* [ ] OpenWrt Buildroot / Buildroot 相关
* [ ] Package Development / 软件包开发
* [ ] Other / 其他

---

# Environment / 环境信息

OpenWrt Distribution:

```text
OpenWrt / ImmortalWrt / FriendlyWrt / Others
```

Version:

```text
23.05 / 24.10 / SNAPSHOT / ...
```

Target Architecture:

```text
x86_64
aarch64
arm_cortex-a53
mipsel_24kc
riscv64
...
```

---

# What Are You Trying To Do? / 你想实现什么？

Describe your goal.

请描述你的目标。

Example:

例如：

* Integrate Tailscale into a custom firmware build
* Build the package from source
* Update Tailscale to the latest version
* Use a custom package feed

---

# What Have You Tried? / 你已经尝试过什么？

Please describe the steps you have already taken.

请描述已经尝试过的方法。

---

# Relevant Logs or Commands / 相关日志或命令

If applicable, provide logs, commands, screenshots, or configuration files.

如果有相关日志、命令、截图或配置文件，请附上。

Example:

```bash
go version
```

```bash
make package/tailscale/compile V=s
```

```bash
tailscale version
```

---

# Additional Information / 补充信息

Add any additional context here.

补充任何可能有帮助的信息。

---

# Expected Outcome / 希望获得什么帮助？

Please describe what kind of help you need.

请描述你希望获得什么帮助。

Examples:

例如：

* Documentation guidance
* Build instructions
* Troubleshooting assistance
* Package integration advice
* Best practice recommendations
