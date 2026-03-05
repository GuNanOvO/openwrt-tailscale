**简体中文文档** | [English Docs](README_en.md)

![Tailscale & OpenWrt](./banner.png)  

# 适用于 OpenWrt 设备的 最新的、更小的 Tailscale  

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat-square&color=2196f3)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale&label=Views&countColor=%23a8d08d&style=flat-square)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat-square&color=4caf50)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=f1c40f&style=flat-square)
![OpenWrt 24.10](https://img.shields.io/badge/OpenWrt-24.10-2196f3?style=flat-square&logo=OpenWrt&logoColor=white&labelColor=1565c0)
![OpenWrt 25.12](https://img.shields.io/badge/OpenWrt-25.12-2196f3?style=flat-square&logo=OpenWrt&logoColor=white&labelColor=1565c0)
![IPK Package](https://img.shields.io/badge/IPK%20Package-OpenWrt-42a5f5?style=flat-square&logo=OpenWrt&logoColor=white&labelColor=1976d2)
![APK Package](https://img.shields.io/badge/APK%20Package-OpenWrt-42a5f5?style=flat-square&logo=OpenWrt&logoColor=white&labelColor=1976d2)  

### 本项目提供以下内容：

* 适用于多种架构的、最新的、更小的 **Tailscale.ipk** 和 **Tailscale.apk** 软件包
* 一键安装脚本，支持 **持久化安装**、**临时安装** Tailscale 至你的 OpenWrt 24.10 或 OpenWrt 25.12 设备
* **OPKG 和 APK 软件源**，更简单、更加方便持续更新 ➡️ [ [Smaller Tailscale Repo](https://gunanovo.github.io/openwrt-tailscale/) ]

---

### 使用方式：

> [!WARNING]  
> 请在使用前阅读以下内容  
> **需求说明:**
>
> * **存储空间**：小于 8MB (除`mips64` `riscv64` `loongarch64`)；  
> * **运行内存**：大约 60MB (运行时)；  
> * **网络环境**：能够访问 GitHub 或代理镜像站；  
> 
> **注意事项:**
>
> * 运行内存小于 256MB 的设备可能无法运行，详见[关于内存占用](https://github.com/GuNanOvO/openwrt-tailscale/issues/17)；  
> * 临时安装高度依赖于网络环境，可靠性较低！建议仅用于无法持久安装的设备；  
> * 多数设备或架构未经过测试，如果您测试不可用，烦请提出issues,我会尽快与您沟通进行修复；  

#### 一键式命令行脚本：

SSH链接至OpenWrt设备执行：

```bash
wget -O /usr/sbin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
```

For Mainland China users only. 
For other regions, please refer to [English README](README_en.md)  

#### 一键式命令行脚本使用自定义代理：

使用参数`--custom-proxy`：

```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --custom-proxy
```

#### 添加软件源：

详见本项目分支 [软件源分支](https://github.com/GuNanOvO/openwrt-tailscale/tree/feed) 或本项目软件源页面 [Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale/)

仅包含受支持的架构的包

#### 自行安装ipk或apk软件包：

1. 于本项目 [Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases) 下载与您设备对应架构的ipk或apk软件包；
2. 可以于OpenWrt设备后台网页界面 -> 系统 -> 软件包
   -> 上传软件包，选择您下载的软件包进行上传并安装；

> [!NOTE]
> 一切安装结果成功与否以能否正常运行 `tailscale up` 为准，如若 `tailscale up` 正常返回登录url，则安装成功；如若显示 `command not found` 或其他错误，则安装失败；

#### **Luci 图形化界面推荐：**

为方便使用，免除大部分命令行操作，可自行选择使用：
来自于@Tokisaki-Galaxy开源项目：[luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)。  
  
### 其他情况说明：

> [!NOTE]
> 如果你有如下情况出现：
>
>  1. 设备运行内存有限，在使用过程中出现tailscale占用极高运行内存;  
>  2. 或直接致使tailscale被OOM KILLER杀死并重启;  
>  3. 或你不清楚什么原因导致tailscale异常重启;  
>
> 则，你可以尝试以更高的CPU占用换取较低的内存占用，操作如下：  
>
>  1. 修改`/etc/init.d/tailscale`文件
>
>     ```bash
>     vi /etc/init.d/tailscale  
>     ```
>  2. 找到 `procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"` 一行
>
>     ```bash
>     procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"  
>     ```
>  3. 在该行后方加上参数 `GOGC=10` 
>
>     ```bash
>     procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode" GOGC=10  
>     ```
>
> 该参数将使tailscale更积极地回收内存  
> 更多信息，可查看issues：[关于内存占用](https://github.com/GuNanOvO/openwrt-tailscale/issues/17)

---

### 编译优化：

使用了下列编译参数，精简了tailscale，详见[Makefile](../package/tailscale/Makefile)：

* **[TAGS](../package/tailscale/Makefile#L31)**:  

``` text
ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient
```

* **[LDFLAGS](../package/tailscale/Makefile#L29)**:

``` text
-s -w
```

使用了[UPX](https://upx.github.io/)二进制文件压缩技术，并使用了以下参数，详见[Makefile](../package/tailscale/Makefile#L65-L74)：

``` text
--best --lzma
```

---

### 脚本逻辑:  

* **持久安装**：代替手动下载ipk包或apk包到设备，使用 `opkg install` 或 `apk add` 进行安装；  
* **临时安装**：下载二进制可执行文件至设备 `/tmp` 目录下，并在 `/usr/sbin` 目录下创建脚本连接；

以上两点，可详查于[install.sh](../install.sh)

---

### Powered By

**[[UPX](https://upx.github.io/)]**：UPX技术，为本项目编译如此小巧的tailscale包创造了可能；  
**[[Github Actions](https://github.com/features/actions)]**：用于自动化构建、发布、部署软件源；  
**[[Github加速代理-ghfast](https://ghfast.top/)]**: 本项目安装脚本中使用的加速代理服务其一；  
**[[Github加速代理-gh-proxy](https://gh-proxy.com/)]**: 本项目安装脚本中使用的加速代理服务其二；  
**[[Github加速代理-jsdelivr](https://www.jsdelivr.com/?docs=gh)]**: 本项目安装脚本中使用的加速代理服务其三；  

---

### 问题反馈  

遇到问题请至 [Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) 提交，请附上：

1. 目标平台架构信息（`opkg print-architecture`）
2. 安装模式（持久/临时/opkg安装/apk安装）
3. 相关日志片段

---

### 自行复刻

如果你需要对本项目进行fork复刻，检查 [有关对fork的说明](./FORK.md) 。

---

### 安全与免责声明

本项目是基于 [Tailscale 官方源码](https://github.com/tailscale/tailscale) 的第三方压缩优化版本，与官方无关。本项目所有源码、脚本、软件包按 “原样” 提供，所有编译、打包、发布步骤均由 [Github Actions](https://github.com/GuNanOvO/openwrt-tailscale/actions) 自动完成，使用本项目即表示您已知晓并自行承担潜在的安全与稳定性风险。

---

### License

本项目使用 **MIT协议**，并包含来自 [**Tailscale**](https://github.com/tailscale/tailscale) 项目的代码，该部分遵循 **BSD 3-Clause 协议**。  

---

> 💖 如果本项目对您有帮助，给我一颗小星星⭐表示支持，谢谢！  
