**简体中文文档** | [English Docs](README_en.md)

![Tailscale & OpenWrt](./banner.png)  
# 适用于 OpenWrt 的 Tailscale 一键安装脚本
## 同时提供OPKG软件源 -> [ [Smaller Tailscale Repo](https://gunanovo.github.io/openwrt-tailscale/) ]

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale&label=Views&countColor=%23b7d079&style=flat)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=yellow)

Bring the latest Tailscale to small-storage OpenWrt device. space-saving & easy install & easy update  

> [!NOTE]
> 一个专为 OpenWrt 小存储空间设备设计的 Tailscale 安装工具  
> 支持持久化安装、临时安装、opkg安装  
> 缩小tailscale体积至 **6MB**！（使用编译优化+UPX压缩技术）  
> 可以帮助您升级您的旧版本OpenWrt设备上的旧版本Tailscale

---

<details>
<summary><h2>支持架构列表</h2></summary>

| 架构类型        | 测试情况      | 测试设备  | 测试系统环境 |
|-----------------|---------------|-----------|--------------|
| `i386`          | 已测试✔️     | kvm虚拟机  | ImmortalWrt 24.10.0 |
| `x86_64`        | 已测试✔️     | kvm虚拟机  | ImmortalWrt 24.10.0 |
| `arm`           | 已测试✔️     | CMCC-XR30  | OpenWrt 23.05.0     |
| `arm64`         | 已测试✔️     | R2S        | ImmortalWrt 23.05.4 |
| `mipsle`        | 已测试✔️     | qemu虚拟机 | ImmortalWrt 24.10.0 |

</details>

---

<details open>
<summary><h2>使用方法</h2></summary>

<details open>
<summary><h3>用前必看</h3></summary>

> **⚠️ 需求说明:**
> - **存储空间**: 小于 10MB (UPX 压缩后)  
> - **运行内存**: 大约 60MB (运行时)  
> - **网络环境**: 能够访问 GitHub 或代理镜像站  

> **⚠️ 需要注意:**
> - 内存小于 256MB 的设备可能无法运行  
> - 临时安装高度依赖于网络环境，可靠性较低！建议仅用于无法持久安装的设备  
> - 多数设备或架构未经过测试，如果您测试不可用，烦请提出issues,我会尽快与您沟通进行修复  

</details>

<details open>
<summary><h3>推荐方式</h3></summary>

**一键式命令行脚本:**
> SSH链接至OpenWrt设备执行:
> ```bash
> wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
> ```
> 仅中国大陆用户，其他地区请见[English README](README_en.md)  

**添加opkg软件源:**
> 详见本项目分支 [软件源项目分支](../feed/README.md) 或本项目opkg软件源页面 [Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale/)  
> 仅包含经过UPX压缩的ipk软件包（mips64架构与mips64le架构仅有未经UPX压缩版）

</details>

<details>
<summary><h3>更多可选方式</h3></summary>

#### 不支持中文的终端
```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en_cnproxy.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
```

#### 安装未压缩的版本（约25mb）
使用参数`--notiny`
```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --notiny
```

#### 自定义代理
使用参数`--custom-proxy`
```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --custom-proxy
```

</details>


<details>
<summary><h3>手动持久安装</h3></summary>

#### 安装二进制文件:
 1. 于本项目[Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases)下载与您设备对应架构的tailscaled文件  
 2. 将该二进制可执行文件置于您设备的`/usr/bin`目录下  
 3. 重命名该二进制可执行文件重命名为`tailscaled`  
 4. 使用命令`ln -sv /usr/bin/tailscaled /usr/bin/tailscale`  
 5. 于本项目[目录](https://github.com/GuNanOvO/openwrt-tailscale/tree/main/etc/init.d)下的tailscale文件（您也可以手动创建文件并填入该文件的内容）  
 6. 将该文件置于您设备的`/etc/init.d`目录下  
 7. 将上述文件添加可执行权限`chmod +x /etc/init.d/tailscale && chmod +x /usr/bin/tailscale && chmod +x /usr/bin/tailscaled`
 8. 执行命令`/etc/init.d/tailscale start`稍等一会，再执行`tailscale up`  
 9. 如果你的OpenWrt版本为22.03，你还需要添加 `--netfilter-mode=off`参数， 对于OpenWrt 23+ 则不应该包含该参数  
 10. enjoy～🫰🏻

#### 安装ipk软件包:
 1. 于本项目[Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases)下载与您设备对应架构的ipk软件包(自由选择压缩版与未压缩版)； 
 2. 可以于OpenWrt设备后台网页界面 -> 系统 -> 软件包 -> 上传软件包，选择您下载的软件包进行上传并安装；
> 注意: 显示安装错误，则先测试 `tailscale up` ，如若正常，则安装成功。

</details>


</details>

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
> >    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode GOGC=10"  
> >    ```
> >    该参数将使tailscale更积极地回收内存

---

<details>
<summary><h2>实现原理</h2></summary>

#### 编译优化:  
使用了下列编译参数，精简了tailscale： 
```
TAGS: ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_tap,ts_omit_kube,ts_omit_completion,ts_omit_ssh,ts_omit_wakeonlan,ts_omit_capture,ts_omit_relayserver,ts_omit_systray,ts_omit_taildrop,ts_omit_tpm,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient

LDFLAGS:
-s -w

```
 加之[UPX](https://upx.github.io/)的二进制文件压缩技术，将tailscale压缩至原来的20%，使得在小存储空间的openwrt设备上使用tailscale变得可能🎉

#### 核心逻辑:  
1. **持久安装**  
   - 将tailscaled二进制文件置于`/usr/bin`，使用`ln -sv tailscaled tailscale`软链接tailscaled到tailscale，仅需大约 **7mb** 即可正常使用tailscale服务。即便所需空间仅 **7mb** 。

2. **临时安装**  
   - 将tailscaled二进制文件至于`/tmp`，同样使用`ln -sv tailscaled tailscale`软链接tailscaled到tailscale，由于是放置于/tmp目录，该安装方式会占用设备运行内存。每次重启后，会调用到脚本进行重新下载tailscale，因此可靠性较低。

</details>

---

<details open>
<summary><h2>特别致谢 🙏</h2></summary>

> **[[glinet-tailscale-updater](https://github.com/Admonstrator/glinet-tailscale-updater)]**: 永久安装与UPX压缩技术参考来源  
> **[[tailscale-openwrt](https://github.com/CH3NGYZ/tailscale-openwrt)]**: 临时安装参考来源  
> **[[openwrt-tailscale-repo](https://github.com/lanrat/openwrt-tailscale-repo)]**: ipk打包与软件源部署参考来源  

</details>

---

<details open>
<summary><h2>问题反馈</h2></summary>

遇到问题请至 [Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) 提交，请附上：
1. 设备架构信息（`uname -m`）
2. 目标平台架构信息（`opkg print-architecture`）
3. 安装模式（持久/临时/opkg安装）
4. 相关日志片段

</details>

---

## 安全声明
本项目是对 **Tailscale** 官方开源软件的再分发，主要目的是为 **OpenWrt** 用户提供及时更新的软件包，以替换官方源中已过时的版本。
过时的 Tailscale 版本可能存在已知安全漏洞，及时更新对于保障网络安全至关重要。

**透明与可验证**
 - **源代码公开**：所有打包、构建与安装脚本完全开源，任何人均可审查、复现整个构建、安装流程。
 - **自动化构建**：构建与打包过程完全由 GitHub Actions 自动执行，构建日志和产物对外公开，确保无人工干预。
 - **官方源码构建**：所有二进制文件均直接从 [**Tailscale**](https://github.com/tailscale/tailscale) 官方项目 的发布版本源码编译，无任何功能性修改或隐藏代码。
 - **可重复构建**：任何人可使用本项目的脚本在自己的 GitHub 或本地环境中重现构建结果，以验证一致性。

**安全承诺**
 - 本项目 **不植入任何恶意代码**，不收集、不上传用户的任何数据。
 - 仅对构建过程进行优化（如体积精简），不改动 Tailscale 的核心功能与安全机制。
 - 所有发布的软件包均提供可公开验证的构建记录与校验信息（SHA256 校验和 / usign 签名）。

通过以上措施，本项目旨在为 OpenWrt 用户提供 **安全、透明、可审计** 的 Tailscale 安装与更新途径，降低使用过时版本带来的安全风险。

---

## License

本项目使用 MIT 协议，并包含来自 [**Tailscale**](https://github.com/tailscale/tailscale) 项目的代码，该部分遵循 BSD 3-Clause 协议。  

---

> 💖 如果本项目对您有帮助，欢迎点亮小星星⭐！  
