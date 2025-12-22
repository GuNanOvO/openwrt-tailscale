**简体中文文档** | [English Docs](README_en.md)

![Tailscale & OpenWrt](./banner.png)

# The Latest, Smaller Tailscale for OpenWrt Devices

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale\&label=Views\&countColor=%23b7d079\&style=flat)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars\&color=yellow)

### This repository provides:

* The latest and smaller **Tailscale ipk packages** for multiple architectures
* One-click installation scripts supporting **persistent installation** and **temporary installation**
* An **OPKG feed** for easier and continuous updates
  ➡️ [ [Smaller Tailscale Repo](https://gunanovo.github.io/openwrt-tailscale/) ]

---

<details>
<summary><h3>Supported Architectures:</h3></summary>

The following target architectures are supported.
Due to the large number of architectures, testing is not yet complete.
Your testing and feedback are greatly appreciated ♥️

* `aarch64_cortex-a53`
* `aarch64_cortex-a72`
* `aarch64_cortex-a76`
* `aarch64_generic`
* `arm_arm1176jzf-s_vfp`
* `arm_arm926ej-s`
* `arm_cortex-a15_neon-vfpv4`
* `arm_cortex-a5_vfpv4`
* `arm_cortex-a7`
* `arm_cortex-a7_neon-vfpv4`
* `arm_cortex-a7_vfpv4`
* `arm_cortex-a8_vfpv3`
* `arm_cortex-a9`
* `arm_cortex-a9_neon`
* `arm_cortex-a9_vfpv3-d16`
* `arm_fa526`
* `arm_xscale`
* `i386_pentium-mmx`
* `i386_pentium4`
* `loongarch64_generic`
* `mips64_mips64r2`
* `mips64_octeonplus`
* `mips64el_mips64r2`
* `mips_24kc`
* `mips_4kec`
* `mips_mips32`
* `mipsel_24kc`
* `mipsel_24kc_24kf`
* `mipsel_74kc`
* `mipsel_mips32`
* `riscv64_riscv64`
* `x86_64` ✅

The following architectures are **not supported**:

* `armeb_xscale`
* `powerpc64_e5500`
* `powerpc_464fp`
* `powerpc_8548`

</details>

---

### Usage:

> [!WARNING]
> Please read the following before use
> **Requirements:**
>
> * **Storage**: Less than 8MB (except `mips64`, `riscv64`, `loongarch64`)
> * **RAM**: About 60MB (runtime)
> * **Network**: Ability to access GitHub or mirror/proxy services
>
> **Notes:**
>
> * Devices with less than 256MB RAM may fail to run Tailscale
> * Temporary installation heavily depends on network stability and is less reliable
>   — recommended only for devices where persistent installation is impossible
> * Most devices/architectures are untested;
>   if you encounter issues, please open an issue and I will respond as soon as possible

#### **One-click CLI Installation Script**

SSH into your OpenWrt device and run:

```bash
wget -O /usr/sbin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/sbin/install.sh && /usr/sbin/install.sh
```

For Mainland China users only.
For other regions, please refer to the [English README](README_en.md)

#### **Add OPKG Feed**

See the [feed branch README](../feed/README.md)
or the repository page:
[Smaller Tailscale Repository For OpenWrt](https://gunanovo.github.io/openwrt-tailscale/)

Only ipk packages for supported architectures are included.

#### **Manual ipk Installation**

1. Download the ipk package matching your device architecture from
   [Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases)
2. Open OpenWrt Web UI → System → Software → Upload Package
   Upload and install the downloaded ipk

Note:
If the UI shows an installation error, try running `tailscale up`.
If it works normally, the installation was successful.

#### **Recommended LuCI GUI**

For easier usage with minimal CLI interaction:
From @Tokisaki-Galaxy’s open-source project:
[luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)

---

> [!NOTE]
> If you experience any of the following:
>
> 1. Very high memory usage by Tailscale
> 2. Tailscale being killed and restarted by OOM Killer
> 3. Unexpected Tailscale restarts with unknown cause
>
> You can trade higher CPU usage for lower memory usage as follows:
>
> 1. Edit `/etc/init.d/tailscale`
>
>    ```bash
>    vi /etc/init.d/tailscale
>    ```
> 2. Locate the line:
>
>    ```bash
>    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode"
>    ```
> 3. Append `GOGC=10` to the line:
>
>    ```bash
>    procd_set_param env TS_DEBUG_FIREWALL_MODE="$fw_mode" GOGC=10
>    ```
>
> This makes Tailscale reclaim memory more aggressively.
> For more details, see issue:
> [Memory usage discussion](https://github.com/GuNanOvO/openwrt-tailscale/issues/17)

---

### Build Optimizations

The following build options are used to minimize Tailscale.
See [Makefile](../package/tailscale/Makefile) for details:

* **TAGS**

```
ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient
```

* **LDFLAGS**

```
-s -w -buildid=
```

Binary compression is performed using [UPX](https://upx.github.io/) with:

```
--best --lzma
```

---

### Script Logic

* **Persistent installation**:
  Automatically downloads ipk packages and installs them using `opkg install`
* **Temporary installation**:
  Downloads and extracts the ipk, places binaries in `/tmp`,
  and creates symlinks under `/usr/sbin`

See [install_en.sh](../install_en.sh) for details.

---

### Special Thanks 🙏

**[[UPX](https://upx.github.io/)]**
Binary compression technology that makes ultra-small Tailscale builds possible

**[[GitHub Actions](https://github.com/features/actions)]**
Used for automated build and release

**[[glinet-tailscale-updater](https://github.com/Admonstrator/glinet-tailscale-updater)]**
One of the original technical references — highly recommended for GL.iNet devices

**[[tailscale-openwrt](https://github.com/CH3NGYZ/tailscale-openwrt)]**
Another early reference providing Tailscale install scripts for OpenWrt

**[[openwrt-tailscale-repo](https://github.com/lanrat/openwrt-tailscale-repo)]**
Feed repository reference

---

### Issue Reporting

Please submit issues via
[Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues)
and include:

1. Device architecture (`uname -m`)
2. Target platform architectures (`opkg print-architecture`)
3. Installation mode (persistent / temporary / opkg)
4. Relevant log snippets

---

### Forking This Project

If you plan to fork this project, note the following:

**Modify install script**

* Update `REPO_URL` and `REPO` variables at the top of `install_en.sh`

**Modify GitHub Actions workflows**

* Replace all occurrences of `GuNanOvO/openwrt-tailscale` in
  `.github/workflows/build-tailscale.yml` and
  `.github/workflows/check-version.yml`
  (usually only the `env` section needs changes)

**Secrets used in workflows**

* `secrets.USIGN_SECRET_KEY_B64`

  * Base64-encoded usign private key for signing ipk packages
* `secrets.PAT_TOKEN`

  * GitHub token with `repo` permission, used to trigger build workflow
* `secrets.GHCR_READ_TOKEN`

  * GitHub token with `read:packages` permission
  * Used to detect upstream GHCR releases (optional)

---

### Security Statement

This project redistributes the official open-source **Tailscale** software,
aiming to provide OpenWrt users with **up-to-date**, **space-efficient** packages
to replace outdated versions in official feeds.

Outdated Tailscale versions may contain known security vulnerabilities.
Timely updates are critical for network security.

**Transparency & Verifiability**

* **Open source**: All packaging, build, and install scripts are fully open
* **Automated builds**: Entirely built by GitHub Actions with public logs
* **Official source builds**: All binaries are compiled from official
  [**Tailscale**](https://github.com/tailscale/tailscale) release sources
* **Reproducible**: Anyone can reproduce the build locally or via GitHub

**Security Commitment**

* No malicious code, no data collection, no telemetry injection
* Only size/build optimizations, no changes to core functionality or security
* All releases include verifiable build records and checksums
  (SHA256 / usign signatures)

This project strives to provide OpenWrt users with a **secure, transparent,
and auditable** way to install and update Tailscale.

---

### License

This project is licensed under the **MIT License**
and includes code from the
[**Tailscale**](https://github.com/tailscale/tailscale) project,
which is licensed under **BSD 3-Clause**.

---

> 💖 If this project helps you, please consider giving it a ⭐!
