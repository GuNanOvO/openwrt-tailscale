**简体中文文档** | [English Docs](README_en.md)

![Tailscale & OpenWrt](./banner.png)  
# 适用于 OpenWrt 设备的 最新的、更小的 Tailscale 
![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale&label=Views&countColor=%23b7d079&style=flat)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=yellow)

### 本仓库提供以下内容：

- 适用于多种架构的、最新的、更小的 Tailscale 软件包（ipk）
- 一键安装脚本，支持 持久化安装、临时安装 Tailscale
- OPKG 软件源，更简单、更加方便持续更新 ➡️ [ [Smaller Tailscale Repo](https://gunanovo.github.io/openwrt-tailscale/) ]

---

<details>
<summary><h3>支持架构列表：</h3></summary>

以下目标架构平台受支持，由于架构较多，测试仍未完善，希望您能测试使用并反馈♥️  
   - `aarch64_cortex-a53`
   - `aarch64_cortex-a72`
   - `aarch64_cortex-a76`
   - `aarch64_generic`
   - `arm_arm1176jzf-s_vfp`
   - `arm_arm926ej-s`
   - `arm_cortex-a15_neon-vfpv4`
   - `arm_cortex-a5_vfpv4`
   - `arm_cortex-a7`
   - `arm_cortex-a7_neon-vfpv4`
   - `arm_cortex-a7_vfpv4`
   - `arm_cortex-a8_vfpv3`
   - `arm_cortex-a9`
   - `arm_cortex-a9_neon`
   - `arm_cortex-a9_vfpv3-d16`
   - `arm_fa526`
   - `arm_xscale`
   - `i386_pentium-mmx`
   - `i386_pentium4`
   - `loongarch64_generic`
   - `mips64_mips64r2`
   - `mips64_octeonplus`
   - `mips64el_mips64r2`
   - `mips_24kc`
   - `mips_4kec`
   - `mips_mips32`
   - `mipsel_24kc`
   - `mipsel_24kc_24kf`
   - `mipsel_74kc`
   - `mipsel_mips32`
   - `riscv64_riscv64`
   - `x86_64`✅

以下架构不受支持：  
   - `armeb_xscale`
   - `powerpc64_e5500`
   - `powerpc_464fp`
   - `powerpc_8548`

</details>

---

> [!WARNING]  
> 请在使用前阅读以下内容  
> **需求说明:**
> - **存储空间**: 小于 8MB (除`mips64` `riscv64` `loongarch64`)；  
> - **运行内存**: 大约 60MB (运行时)；  
> - **网络环境**: 能够访问 GitHub 或代理镜像站；  
> **注意事项:**
> - 运行内存小于 256MB 的设备可能无法运行；  
> - 临时安装高度依赖于网络环境，可靠性较低！建议仅用于无法持久安装的设备；  
> - 多数设备或架构未经过测试，如果您测试不可用，烦请提出issues,我会尽快与您沟通进行修复；  


### 使用方式：
**一键式命令行脚本：**
> SSH链接至OpenWrt设备执行:
> ```bash
> wget -O /usr/sbin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
> ```
> For Mainland China users only. For other regions, please refer to [English README](README_en.md)  

**添加opkg软件源：**
> 详见本项目分支 [软件源分支](../feed/README.md) 或本项目opkg软件源页面 [Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale/)  
> 仅包含受支持的架构的ipk包

**一键式命令行脚本使用自定义代理：**
> 使用参数`--custom-proxy`
> ```bash
> wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --custom-proxy
> ```

**自行安装ipk软件包：**
> 1. 于本仓库[Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases)下载与您设备对应架构的ipk软件包； 
> 2. 可以于OpenWrt设备后台网页界面 -> 系统 -> 软件包 -> 上传软件包，选择您下载的软件包进行上传并安装；  
> 注意: 显示安装错误，则先测试 `tailscale up` ，如若正常，则安装成功。

**Luci 图形化界面推荐：**  
> 来自于@Tokisaki-Galaxy开源项目：[luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)  
> 可自行选择使用  

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
> 更多信息，可查看issues：[关于内存占用](https://github.com/GuNanOvO/openwrt-tailscale/issues/17)


---

### 编译优化:  
使用了下列编译参数，精简了tailscale，详见[Makefile](../package/tailscale/Makefile)：  
> TAGS: 
> ```
> ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient
> ```
> LDFLAGS:
> ```
> -s -w -buildid=
> ```
使用了[UPX](https://upx.github.io/)二进制文件压缩技术，并使用了以下参数，详见[Makefile](../package/tailscale/Makefile)：  
> ```
> --best --lzma
> ```

### 脚本逻辑:  
- **持久安装**：代替手动下载ipk包，自动将ipk包下载至设备，使用`opkg install`进行安装；  
- **临时安装**：下载ipk包至设备，解包ipk,提取二进制文件，放置于`/tmp`目录下，并在`/usr/sbin`目录下创建连接；  
以上两点，可详查于[install.sh](../install.sh)

### 特别致谢 🙏   

> **[[UPX](https://upx.github.io/)]**：UPX技术，为本仓库编译如此小巧的tailscale包创造了可能；  
> **[[Github Actions](https://github.com/features/actions)]**：用于自动化构建与发布；  
> **[[glinet-tailscale-updater](https://github.com/Admonstrator/glinet-tailscale-updater)]**: 本仓库最初技术参考之一，如果你的glinet设备需要使用tailscale，这是你的不二之选；  
> **[[tailscale-openwrt](https://github.com/CH3NGYZ/tailscale-openwrt)]**: 本仓库最初技术参考之一，同样提供tailscale在openwrt上的安装脚本，您可自行选用；  
> **[[openwrt-tailscale-repo](https://github.com/lanrat/openwrt-tailscale-repo)]**: 本仓库feed源技术参考；  
> **[[Github加速代理](../install.sh)]**: 本仓库安装脚本中使用的加速代理服务，详查于[install.sh](../install.sh)；  

---
### 问题反馈  
遇到问题请至 [Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) 提交，请附上：
1. 设备架构信息（`uname -m`）
2. 目标平台架构信息（`opkg print-architecture`）
3. 安装模式（持久/临时/opkg安装）
4. 相关日志片段

---

### 自行复刻
如果你需要对本项目进行fork复刻，你需要注意以下几点：  
> **修改install脚本**：
> - 修改脚本顶部变量区域的：`REPO_URL` & `REPO` 对应到你的fork仓库。

> **修改github actions 工作流文件**：
> - 修改`.github/workflows/build-tailscale.yml`与`.github/workflows/check-version.yml`当中的所有`GuNanOvO/openwrt-tailscale`为你fork项目，通常只需要修改env部分。  

> **工作流文件当中使用的SECRETS**：  
> - `secrets.USIGN_SECRET_KEY_B64`：
> - - 使用usign生成的私钥，用于签名ipk包，使用base64对私钥进行编码后，设置于仓库的setting > security > secrets and variables > actions > Repository secrets。
> - `secrets.PAT_TOKEN`：
> - - github账户`repo`权限token，用于供`.github/workflows/check-version.yml`触发`.github/workflows/build-tailscale.yml`进行构建工作。
> - `secrets.GHCR_READ_TOKEN`：  
> - - github账户`read:packages`权限token，用于供action检测上游ghcr发布版本，默认不使用ghcr版本，可去除。

---

### 安全声明
本项目是对 **Tailscale** 官方开源软件的再分发，主要目的是为 **OpenWrt** 用户提供及时更新的、且更适用于小存储容量的OpenWrt设备的软件包，以替换官方源中已过时的版本。
过时的 Tailscale 版本可能存在已知安全漏洞，及时更新对于保障网络安全至关重要。

**透明与可验证**：  
 - **源代码公开**：所有打包、构建与安装脚本完全开源，任何人均可审查、复现整个构建、安装流程。
 - **自动化构建**：构建与打包过程完全由 GitHub Actions 自动执行，构建日志和产物对外公开，确保无人工干预。
 - **官方源码构建**：所有二进制文件均直接从 [**Tailscale**](https://github.com/tailscale/tailscale) 官方项目 的发布版本源码编译，无任何功能性修改或隐藏代码。
 - **可重复构建**：任何人可使用本项目的脚本在自己的 GitHub 或本地环境中重现构建结果，以验证一致性。  
**安全承诺**：  
 - 本项目 **不植入任何恶意代码**，不收集、不上传用户的任何数据。
 - 仅对构建过程进行优化（如体积精简），不改动 Tailscale 的核心功能与安全机制。
 - 所有发布的软件包均提供可公开验证的构建记录与校验信息（SHA256 校验和 / usign 签名）。

通过以上措施，本项目旨在为 OpenWrt 用户提供 **安全、透明、可审计** 的 Tailscale 安装与更新途径，降低使用过时版本带来的安全风险。

---

### License

本项目使用 MIT 协议，并包含来自 [**Tailscale**](https://github.com/tailscale/tailscale) 项目的代码，该部分遵循 BSD 3-Clause 协议。  

---

> 💖 如果本项目对您有帮助，欢迎点亮小星星⭐！  
