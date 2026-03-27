**简体中文文档** | [English Docs](README_en.md)

![Tailscale & OpenWrt](./banner.png)

# [适用于 OpenWrt 的 Tailscale 软件源](https://gunanovo.github.io/openwrt-tailscale)

## 软件源设置

请根据你的 OpenWrt 版本选择对应的设置方式。

### OpenWrt 24.10 或更早版本（OPKG）

**1. 添加公钥**

```sh
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub && opkg-key add /tmp/key-build.pub
```

**2. 添加软件源**

```sh
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)" >> /etc/opkg/customfeeds.conf
```

或者手动编辑 `/etc/opkg/customfeeds.conf`，添加以下行（请将 `{你的设备架构}` 替换为实际架构）：

```
src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/{你的设备架构}
```

### OpenWrt 25.10 或更新版本（APK）

**1. 添加公钥**

```sh
wget -O /etc/apk/keys/gunanovo@github.io.pub https://gunanovo.github.io/openwrt-tailscale/key-build.rsa.pub
```

**2. 添加软件源**

```sh
echo "https://gunanovo.github.io/openwrt-tailscale/$(cat /etc/apk/arch)/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
```

或者手动编辑 `/etc/apk/repositories.d/customfeeds.list`，添加以下行（请将 `{你的设备架构}` 替换为实际架构）：

```
https://gunanovo.github.io/openwrt-tailscale/{你的设备架构}/packages.adb
```

---

## 安装方式

### OpenWrt 24.10 或更早版本（OPKG）

```sh
opkg update
opkg install tailscale
```

### OpenWrt 25.10 或更新版本（APK）

```sh
apk update
apk add tailscale
```

> [!NOTE]
> 安装过程中出现 `"failed log upload"` 报错属于预期现象，可放心忽略。

---

## Web UI (LuCI)

为了获得图形界面来管理 Tailscale，我们建议安装由 [@Tokisaki-Galaxy](https://github.com/Tokisaki-Galaxy) 开发并在 GitHub 上开源的 LuCI 应用：[luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)  
这提供了一个易于使用的 Web 界面，可以直接从 OpenWrt 的 LuCI 仪表板配置和管理 Tailscale。

---

## 安装后步骤

安装完成后，需要配置 Tailscale 以将设备接入 Tailscale 网络。

执行以下命令（根据你的需求调整参数）：

```sh
tailscale up \
    --accept-dns=false \
    --advertise-routes=10.0.0.0/24 \
    --advertise-exit-node
```

> [!WARNING]
> 如果你的 OpenWrt 版本为 22.03，你还需要添加 `--netfilter-mode=off` 参数；对于 OpenWrt 23+ 则**不应**包含该参数。

> [!TIP]
> 建议添加 `--hostname=your-router-name` 参数，以便在 Tailscale 网络中更容易识别该设备。

---

> 💖 如果本项目对您有帮助，欢迎点亮小星星⭐！