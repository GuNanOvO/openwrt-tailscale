# openwrt-tailscale

This repository provides a trimmed Tailscale package for OpenWrt.

## Building with self-compiled OpenWrt firmware

If your OpenWrt buildroot uses an older Go toolchain from the official packages feed, newer Tailscale versions may fail during compilation with errors such as:

- `go.mod requires go >= ...`
- `unknown directive: tool`

This usually happens because the OpenWrt packages feed provides an older Go version than the one required by the current Tailscale source.

### Recommended workaround

Use a newer Go toolchain for the build process and override the Go binary used by the OpenWrt buildroot.

1. Run the helper script:

```bash
bash build_scripts/prepare_go_for_openwrt.sh /path/to/openwrt/buildroot 1.26.5
```

2. Select tailscale in the kernel configuration:

```bash
# 方法 A：用菜单选择 Network → VPN → tailscale（按 Y）
make menuconfig

# 或方法 B：直接写入 .config
echo "CONFIG_PACKAGE_tailscale=y" >> .config
make defconfig
```

3. Then build the full firmware image (tailscale will be compiled automatically as part of the process):

```bash
make -j$(nproc) V=s
```

> **Note**: If you only need the `.ipk` package (not a full firmware), you can use `make package/tailscale/compile -j$(nproc) V=s` instead of the full `make`.

```bash
make -j$(nproc) V=s
```

### Notes

- The script installs the newer Go toolchain under the OpenWrt staging directory so that the build uses it instead of the older packages-feed version.
- If your target is not amd64, you may need to set `GO_ARCH` explicitly, for example:

```bash
GO_ARCH=arm64 bash build_scripts/prepare_go_for_openwrt.sh /path/to/openwrt/buildroot 1.26.3
```

- For a package-only workflow, you can also build and install the generated `.ipk` file manually from the OpenWrt buildroot.
