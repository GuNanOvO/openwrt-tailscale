[简体中文文档](./README.md) | **English Docs**

![Tailscale & OpenWrt](./banner.png)

# [Tailscale Repository for OpenWrt](https://gunanovo.github.io/openwrt-tailscale)

## Repository Setup

Choose the setup method according to your OpenWrt version.

### OpenWrt 24.10 or earlier (OPKG)

**1. Add the public key**

```sh
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub && opkg-key add /tmp/key-build.pub
```

**2. Add the repository**

```sh
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)" >> /etc/opkg/customfeeds.conf
```

Or manually edit `/etc/opkg/customfeeds.conf` and add the following line (replace `{your device architecture}` with your actual architecture):

```
src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/{your device architecture}
```

### OpenWrt 25.10 or later (APK)

**1. Add the public key**

```sh
wget -O /etc/apk/keys/gunanovo@github.io.pub https://gunanovo.github.io/openwrt-tailscale/key-build.rsa.pub
```

**2. Add the repository**

```sh
echo "https://gunanovo.github.io/openwrt-tailscale/$(apk --print-arch)/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
```

Or manually edit `/etc/apk/repositories.d/customfeeds.list` and add the following line (replace `{your device architecture}` with your actual architecture):

```
https://gunanovo.github.io/openwrt-tailscale/{your device architecture}/packages.adb
```

---

## Installation

### OpenWrt 24.10 or earlier (OPKG)

```sh
opkg update
opkg install tailscale
```

### OpenWrt 25.10 or later (APK)

```sh
apk update
apk add tailscale
```

> [!NOTE]
> The `"failed log upload"` message that may appear during installation is expected and can be safely ignored.

---

## Web UI (LuCI)

For a graphical interface to manage Tailscale, we recommend installing the LuCI app developed by [@Tokisaki-Galaxy](https://github.com/Tokisaki-Galaxy) and open-sourced on GitHub: [luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)  
This provides an easy-to-use web interface to configure and manage Tailscale directly from the OpenWrt LuCI dashboard.

---

## Post-Installation Steps

After installation, you need to configure Tailscale to connect your device to the Tailscale network.

Run the following command (adjust parameters as needed):

```sh
tailscale up \
    --accept-dns=false \
    --advertise-routes=10.0.0.0/24 \
    --advertise-exit-node
```

> [!WARNING]
> If you are using OpenWrt 22.03, you must also add `--netfilter-mode=off`; for OpenWrt 23+ **do not** include this parameter.

> [!TIP]
> Consider adding `--hostname=your-router-name` for easier identification on your Tailscale network.

---

> 💖 If this project helps you, please consider giving it a ⭐!