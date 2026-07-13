---
title: Memory Optimization
description: Reduce Tailscale memory usage with GOGC tuning for low-RAM devices
---

# Memory Optimization

If your device has limited RAM, Tailscale may consume excessive memory or get killed by the OOM Killer. You can reduce memory usage by adjusting the GOGC parameter.

## Symptoms

You might need this optimization if:
- Your device has limited RAM and Tailscale consumes too much memory
- Tailscale is killed and restarted by the OOM Killer
- Tailscale keeps restarting unexpectedly

## Solution: Adjust GOGC

1. Edit the init script:

```sh
vi /etc/init.d/tailscale
```

2. Find this line:

```sh
procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"
```

3. Append `GOGC=10` to the end of that line:

```sh
procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode" GOGC=10
```

4. Restart Tailscale:

```sh
/etc/init.d/tailscale restart
```

## How It Works

- `GOGC=10` tells the Go runtime to trigger GC when heap grows by 10% (default is 100%)
- More frequent but smaller GC cycles
- **Trade-off**: Higher CPU usage, lower peak memory
- Suitable for devices with limited RAM (128MB or less)

::: warning
Setting GOGC too low (< 5) may cause performance degradation. Start with 10 and adjust as needed.
:::
