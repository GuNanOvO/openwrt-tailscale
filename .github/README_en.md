[简体中文文档](README.md) | **English Docs**  

![Tailscale & OpenWrt](./banner.png)  
# One-Click Installation Script for Tailscale on OpenWrt
# Also provided opkg software source -> [ [Smaller Tailscale Repo](https://gunanovo.github.io/openwrt-tailscale/) ]

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale&label=Views&countColor=%23b7d079&style=flat)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=yellow)

Bring the latest Tailscale to small-storage OpenWrt device. space-saving & easy install & easy update  

> [!NOTE]
> A Tailscale installation tool designed for OpenWrt devices with limited storage  
> Supports persistent installation, temporary installation, and opkg installation  
> Reduces Tailscale size to **6MB**! (Using compilation optimization + UPX compression)  
> Helps upgrade old Tailscale versions on legacy OpenWrt devices

---

<details>
<summary><h2>Supported Architectures</h2></summary>

| Architecture     | Test Status    | Test Device | Test System Environment |
|-----------------|---------------|-------------|-------------------------|
| `i386`          | Tested ✔️     | kvm VM      | ImmortalWrt 24.10.0     |
| `x86_64`        | Tested ✔️     | kvm VM      | ImmortalWrt 24.10.0     |
| `arm`           | Tested ✔️     | CMCC-XR30   | OpenWrt 23.05.0         |
| `arm64`         | Tested ✔️     | R2S         | ImmortalWrt 23.05.4     |
| `mipsle`        | Tested ✔️     | qemu VM     | ImmortalWrt 24.10.0     |

</details>

---

<details open>
<summary><h2>Usage Guide</h2></summary>

<details open>
<summary><h3>Important Notes</h3></summary>

> **⚠️ Requirements:**
> - **Storage Space**: Less than 10MB (UPX compressed)  
> - **Memory**: Approximately 60MB (runtime)  
> - **Network**: Access to GitHub  

> **⚠️ Important Considerations:**
> - May not work on devices with less than 256MB RAM  
> - Temporary installation heavily depends on network reliability! Recommended only for devices that cannot support persistent installation  
> - Most devices/architectures are untested. If you encounter issues, please submit an issue report  

</details>

<details open>
<summary><h3>Recommended Methods</h3></summary>

**One-Click Installation Script:**
> SSH into your OpenWrt device and execute:
> ```bash
> wget -O /usr/bin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
> ```

**Add opkg Repository:**
> See our repository branch [Feed Repository Branch](../feed/README.md) or visit our opkg repository page:  
> [Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale/)  
> Contains UPX-compressed ipk packages (mips64/mips64le available uncompressed only)

</details>

<details>
<summary><h3>Additional Options</h3></summary>

#### Install uncompressed version (~25MB)
Use `--notiny` parameter:
```bash
wget -O /usr/bin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --notiny
```

</details>

<details>
<summary><h3>Manual Persistent Installation</h3></summary>

#### Install binary files:
 1. Download the tailscaled file matching your device architecture from [Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases)  
 2. Place the binary in your device's `/usr/bin` directory  
 3. Rename the binary to `tailscaled`  
 4. Create symbolic link: `ln -sv /usr/bin/tailscaled /usr/bin/tailscale`  
 5. Get the init script from our [directory](https://github.com/GuNanOvO/openwrt-tailscale/tree/main/etc/init.d) or create manually  
 6. Place the file in your device's `/etc/init.d` directory  
 7. Add execute permissions: `chmod +x /etc/init.d/tailscale && chmod +x /usr/bin/tailscale && chmod +x /usr/bin/tailscaled`  
 8. Start service: `/etc/init.d/tailscale start` then run `tailscale up`  
 9. For OpenWrt 22.03, add `--netfilter-mode=off` parameter. Not required for OpenWrt 23+  
 10. Enjoy～🫰🏻  

#### Install ipk package:
 1. Download matching ipk package from [Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases) (choose compressed or uncompressed version)  
 2. Install via OpenWrt web UI: System → Software → Upload Package  
> Note: Ignore "failed log upload" error when install if `tailscale up` works normally  

</details>

</details>

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

<details>
<summary><h2>Implementation Details</h2></summary>

#### Compilation Optimization:  
The following build parameters were used to slim down Tailscale:

```
TAGS: ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_tap,ts_omit_kube,ts_omit_completion,ts_omit_ssh,ts_omit_wakeonlan,ts_omit_capture,ts_omit_relayserver,ts_omit_systray,ts_omit_taildrop,ts_omit_tpm,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient

LDFLAGS:
-s -w
```

Additionally, by applying [UPX](https://upx.github.io/) binary compression, the Tailscale binary was reduced to only 20% of its original size, making it feasible to run Tailscale on OpenWrt devices with limited storage space 🎉.

#### Core Logic:  
1. **Persistent Installation**  
   - Places the `tailscaled` binary in `/usr/bin`, creating a symbolic link using `ln -sv tailscaled tailscale`. Only **6MB** of storage is required to run Tailscale.  

2. **Temporary Installation**  
   - Places the `tailscaled` binary in `/tmp`, creating a symbolic link as above. Since it is stored in the `/tmp` directory, this method **uses device RAM**. Upon reboot, the script will automatically re-download Tailscale.  
   
</details>

---

<details open>
<summary><h2>Special Thanks 🙏</h2></summary>

> **[[glinet-tailscale-updater](https://github.com/Admonstrator/glinet-tailscale-updater)]**: Reference for persistent installation & UPX compression  
> **[[tailscale-openwrt](https://github.com/CH3NGYZ/tailscale-openwrt)]**: Reference for temporary installation  
> **[[openwrt-tailscale-repo](https://github.com/lanrat/openwrt-tailscale-repo)]**: Reference for ipk packaging & repository deployment  

</details>

---

<details open>
<summary><h2>Issue Reporting</h2></summary>

Please submit issues at [Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) with:  
1. Device architecture (`uname -m`)  
2. Target platform architecture (`opkg print-architecture`)  
3. Installation mode (persistent/temporary/opkg)  
4. Relevant log snippets  

</details>

---

## Security Statement
This repository redistributes the official **Tailscale** open-source software, with the primary goal of providing timely updates for **OpenWrt** users, as a replacement for the outdated versions often found in community feeds.
Outdated versions of Tailscale may contain known vulnerabilities, and keeping Tailscale up-to-date is essential for maintaining network security.

**Transparency & Verifiability**  
 - **Open Source Code**: All build, packaging, and installation scripts are fully open-source. Anyone can inspect, audit, and reproduce the entire build and installation process.  
 - **Automated Builds**: All builds and packaging are executed via GitHub Actions. The build logs and artifacts are publicly accessible to ensure full transparency and no manual interference.  
 - **Built from Official Source**: All binaries are compiled directly from the Tailscale official repository’s released source code, with no functional modifications or hidden code.  
 - **Reproducible Builds**: Anyone can rebuild the same packages using the provided scripts either on GitHub or in a local environment to verify consistency and authenticity. 
  
**Security Commitment**  
 - This repository **does not introduce any malicious code**, nor does it collect or transmit any user data.
 - Only build-time optimizations are applied (such as binary size reduction); the core functionality and security model of Tailscale remain untouched.
 - All published packages include publicly verifiable build records and integrity data (SHA256 checksums / usign signatures).

Through these practices, this project aims to offer a **secure, transparent, and auditable** Tailscale installation and update path for OpenWrt users — reducing the risks associated with outdated versions.

---

## License

This project is licensed under the MIT License and includes components from the [**Tailscale**](https://github.com/tailscale/tailscale) project, which is licensed under the BSD 3-Clause License.

---

> 💖 If this project helps you, feel free to give it a star⭐!  