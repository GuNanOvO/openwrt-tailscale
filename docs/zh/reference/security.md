---
title: 安全声明
description: Tailscale 软件源的安全性和可信性说明 — 开源、可审计、无人工上传
---

# 安全声明

## 可信性

本 feed 中的所有软件包通过 GitHub Actions 自动化构建，过程完全开源、可审计、可复现。

- **源代码**来自 [Tailscale 官方仓库](https://github.com/tailscale/tailscale)，未做任何功能性修改。
- 仅添加**编译参数**，并在大部分架构上使用 [UPX](https://upx.github.io/) 压缩以减小包体积。
- 构建脚本、工作流、编译参数、日志**全部公开**，位于仓库的 `.github/workflows` 和 [Actions 历史](https://github.com/GuNanOvO/openwrt-tailscale/actions) 中。
- **无人工上传、无动态后端**，所有产物由 CI 自动生成并部署到 [GitHub Pages](https://pages.github.com/)。

## 用户验证建议

1. **审查仓库代码**，查看 [Actions 脚本与构建日志](https://github.com/GuNanOvO/openwrt-tailscale/actions)
2. **自行构建**，按照[构建指南](/zh/build/)中的说明验证可复现性
3. **校验 SHA256**，下载后校验（可在[软件包页面](/zh/packages)查看）

## 免责声明

本 feed **按原样**提供，不附带任何明示或暗示的担保。使用前请自行审查源代码与构建过程，并自行承担风险。

建议始终保持关注仓库更新，并优先从官方或可信渠道获取软件包。
