**简体中文** | [English](README_en.md)  
![Tailscale & OpenWrt](./banner.png)  
# [Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale)

> [!NOTE]
> 这是为 OpenWrt 精简定制的 Tailscale 软件包，旨在在保持核心功能的同时，尽可能降低存储占用。
> **优化内容：**
> * 将 `tailscale` 和 `tailscaled` 合并为一个单一的可执行文件。
> * 使用 `--extra-small` 编译标志以显著减小二进制文件体积。
> * 使用 UPX 对二进制文件进行压缩（mips64 架构除外），进一步降低存储占用。

---

## 软件源设置

导入用于验证软件包签名的 GPG 公钥：

**在你的 OpenWrt 设备上执行以下命令：**

```sh
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub && opkg-key add /tmp/key-build.pub
```

将软件源添加到你的 OpenWrt 配置中：

**编辑 `/etc/opkg/customfeeds.conf` 文件：**

```sh
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale" >> /etc/opkg/customfeeds.conf
```

**或者手动添加以下内容：**

```sh
src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale
```

---

## 安装方式

请选择你喜欢的方式安装 Tailscale：

### Web 界面方式：

1. 打开 **系统 → 软件包（System → Software）**
2. 点击 *更新列表（Update lists）* 以刷新软件包
3. 搜索 `tailscale`
4. 安装主软件包及其他你需要的工具组件

### 命令行方式：

```sh
opkg update
opkg install tailscale
```

> \[!NOTE]
> 安装过程中出现 `"failed log upload"` 报错属于预期现象，可放心忽略。

---

## Web UI (LuCI)

为了获得图形界面来管理 Tailscale，我们建议安装由 [@Tokisaki-Galaxy](https://github.com/Tokisaki-Galaxy) 开发并在 GitHub 上开源的 LuCI 应用：[luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)  
这提供了一个易于使用的 Web 界面，可以直接从 OpenWrt 的 LuCI 仪表板配置和管理 Tailscale。

---

## 安装后步骤

安装完成后，需要配置 Tailscale 以将设备接入 Tailscale 网络。

执行以下命令：

```sh
tailscale up \
    --accept-dns=false \
    --advertise-routes=10.0.0.0/24 \
    --advertise-exit-node
```
> [!WARNING]
> 如果你的OpenWrt版本为22.03，你还需要添加 `--netfilter-mode=off`参数， 对于 OpenWrt 23+ 则不应该包含该参数

---

> [!TIP]
> 建议添加 `--hostname=your-router-name` 参数，以便在 Tailscale 网络中更容易识别该设备。

> [!NOTE]
> 如果你有如下情况出现：
> > 1. 设备运行内存有限，在使用过程中出现tailscale占用极高运行内存;  
> > 2. 或直接致使tailscale被OOM KILLER杀死并重启;  
> > 3. 或你不清楚什么原因导致tailscale异常重启;  
>
> 则，你可以尝试以更高的CPU占用换取较低的内存占用，操作如下：  
> > 1. 修改`/etc/init.d/tailscale`文件
> >    ```bash
> >    vi /etc/init.d/tailscale  
> >    ```
> > 2. 找到 `procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"` 一行
> >    ```bash
> >    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"  
> >    ```
> > 3. 在该行后方加上参数 `GOGC=10` 
> >    ```bash
> >    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode" GOGC=10  
> >    ```
> >    该参数将使tailscale更积极地回收内存

---

> 💖 如果本项目对您有帮助，欢迎点亮小星星⭐！  
