[简体中文](README.md) | **English**  
![Tailscale & OpenWrt](./banner.png)  
# [Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale)

> [!NOTE]
> These are smaller Tailscale packages for OpenWrt, specifically designed to reduce storage usage while maintaining essential functionality.
> **Optimized:**
> - Combined `tailscale` and `tailscaled` into a single binary.
> - Built with the `--extra-small` flag to significantly reduce binary size.
> - UPX compression applied to binaries (except for mips64 architecture) to further reduce storage usage.

---

## Repository Setup

Import the public GPG key used to verify package signatures:

**Run this command on your OpenWrt device:**

```sh
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub && opkg-key add /tmp/key-build.pub
```

Add the package feed to your OpenWrt configuration:

**Edit `/etc/opkg/customfeeds.conf`:**

```sh
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale" >> /etc/opkg/customfeeds.conf
````

**Or manually add this line:**

```sh
src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale
```

---

## Installation Methods

Choose your preferred method to install Tailscale on OpenWrt:

### Web UI:

1. Navigate to **System → Software**
2. Click *Update lists* to refresh packages
3. Search for `tailscale`
4. Install the main package and any desired utilities

### Command Line:

```sh
opkg update
opkg install tailscale
```

> [!NOTE]
> The "failed log upload" message during installation is expected and can be safely ignored.

---

## Web UI (LuCI)
For a graphical interface to manage Tailscale, we recommend installing the LuCI app which build by [@Tokisaki-Galaxy](https://github.com/Tokisaki-Galaxy) and open source on GitHub: [luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)  
This provides an easy-to-use web interface to configure and manage Tailscale directly from OpenWrt's LuCI dashboard.

---

## Post-Installation Steps

After installation, you need to configure Tailscale to connect your device to the Tailscale network.

Run the following command:

```sh
tailscale up \
    --accept-dns=false \
    --advertise-routes=10.0.0.0/24 \
    --advertise-exit-node
```
> [!WARNING]
> If you're using OpenWrt == 22.03 you will also need to specify `--netfilter-mode=off`. For versions 23+ do NOT include netfilter-mode.  

---

> [!TIP]
> Consider adding `--hostname=your-router-name` for easier identification.

> [!NOTE]
> If you encounter any of the following situations:
> > 1. Your device has limited RAM, and during usage, Tailscale consumes an excessive amount of memory;  
> > 2. Or Tailscale is killed and restarted by the OOM Killer;  
> > 3. Or you’re not sure why Tailscale keeps restarting unexpectedly;  
>
> Then you may try trading higher CPU usage for lower memory usage. Here's how:  
> > 1. Edit the `/etc/init.d/tailscale` file:
> >    ```bash
> >    vi /etc/init.d/tailscale  
> >    ```
> > 2. Locate the following line:
> >    ```bash
> >    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"  
> >    ```
> > 3. Append `GOGC=10` to the end of that line so it becomes:
> >    ```bash
> >    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode" GOGC=10  
> >    ```
> >    This will make Tailscale more aggressive in memory garbage collection.

---

> 💖 If this project helps you, feel free to star⭐ it!  
