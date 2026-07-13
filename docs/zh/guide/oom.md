---
title: 内存优化
description: 通过 GOGC 参数调优降低 Tailscale 内存占用
---

# 内存优化

如果设备运行内存有限，Tailscale 可能占用过多内存或被 OOM Killer 杀死。可以通过调整 GOGC 参数来降低内存占用。

## 症状

以下情况你可能需要此优化：
- 设备内存有限，Tailscale 占用极高运行内存
- Tailscale 被 OOM Killer 杀死并重启
- Tailscale 异常重启

## 解决方案：调整 GOGC

1. 编辑 init 脚本：

```sh
vi /etc/init.d/tailscale
```

2. 找到以下行：

```sh
procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"
```

3. 在该行后方加上参数 `GOGC=10`：

```sh
procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode" GOGC=10
```

4. 重启 Tailscale：

```sh
/etc/init.d/tailscale restart
```

## 原理

- `GOGC=10` 告诉 Go 运行时堆增长 10% 时就触发 GC（默认 100%）
- 更频繁但更小的 GC 周期
- **权衡**：更高的 CPU 占用，更低的峰值内存
- 适用于内存有限的设备（128MB 或更少）

::: warning
`GOGC` 设置过低（< 5）可能导致性能下降。建议从 10 开始，根据需要调整。
:::
