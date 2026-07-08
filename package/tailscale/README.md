# Tailscale
This readme should help you with tailscale client setup.

## Self-built OpenWrt firmware note

If you are compiling this package inside a self-built OpenWrt firmware tree and the build fails because the buildroot uses an older Go version from the official packages feed, you can override it with a newer upstream Go toolchain before building.

```bash
bash build_scripts/prepare_go_for_openwrt.sh /path/to/openwrt/buildroot 1.26.3
make package/tailscale/compile -j$(nproc) V=s
```

The helper script is stored in [build_scripts/prepare_go_for_openwrt.sh](../../build_scripts/prepare_go_for_openwrt.sh).

> [!NOTE]
> By default this package will use nftables. If you wish to use iptables, the config file `/etc/config/tailscale` can be modfied, changing the line `fw_mode 'nftables'` to `fw_mode 'iptables'`. You can then run `/etc/init.d/tailscale restart` to restart tailscale using your chosen method

## First setup

First, enable and run daemon

```
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

Then you should use tailscale utility to get a login link for your device.

Run command and finish device registration with the given URL.
```
tailscale up
```

See the [OpenWrt wiki](https://openwrt.org/docs/guide-user/services/vpn/tailscale/start) for more detailed setup instructions
