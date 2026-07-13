---
title: 安装后配置
description: 安装 Tailscale 后的配置 — 连接网络、启用自启、管理更新
---

# 安装后配置

安装完成后，需要将设备接入 Tailscale 网络。

## 基本设置

**简单使用：**
```sh
# 登录到 tailscale 网络
tailscale up 
```

**示例用法：**
```sh
# 登录到 tailscale 网络，自定义主机名、不使用 Tailscale DNS、通告子网路由、充当出口节点
tailscale up \
  --accept-dns=false \
  --advertise-routes=10.0.0.0/24 \
  --advertise-exit-node
```

**更多配置用法**： 请查看 [OpenWrt 官方文档](https://openwrt.org/docs/guide-user/services/vpn/tailscale/start) 或 [Tailscale 官方文档](https://tailscale.com/docs)

::: warning OpenWrt 22.03 用户
添加 `--netfilter-mode=off` 参数。OpenWrt 23+ 则**不要**包含此参数。
:::

## 常用配置选项

| 选项 | 说明 |
|------|------|
| `--hostname=名称` | 设置自定义主机名 |
| `--accept-dns=false` | 不使用 Tailscale DNS |
| `--advertise-routes=x.x.x.x/xx` | 通告子网路由 |
| `--advertise-exit-node` | 充当出口节点 |
| `--accept-routes` | 接受其他设备通告的路由 |
| `--netfilter-mode=off` | 禁用 netfilter（OpenWrt 22.03 必需） |

## 启用开机自启

```sh
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

## 检查状态

```sh
/etc/init.d/tailscale status
tailscale status
tailscale ip
```

## 更新 Tailscale

```sh
# APK
apk update && apk upgrade tailscale

# OPKG
opkg update && opkg upgrade tailscale
```

## 卸载

```sh
/etc/init.d/tailscale stop
/etc/init.d/tailscale disable
# 对于 apk 包管理器
apk del tailscale  
# 对于opkg包管理器
opkg remove tailscale
rm -rf /etc/tailscale /var/lib/tailscale
```

## 下一步

- [LuCI 管理界面](/zh/guide/luci) — 图形化管理界面
- [内存优化](/zh/guide/oom) — 降低内存占用
- [常见问题](/zh/reference/faq) — 解答常见疑问
