# Build instructions for contributors and CI

This document explains how to use this repository as an OpenWrt feed and how to build the package locally for debugging.

## Add repository as feed

In your OpenWrt buildroot, create `feeds.conf.default` if not present, and add this repository as a src-git feed:

```sh
# in OpenWrt buildroot
cat > feeds.conf.default <<'EOF'
src-git openwrt_tailscale https://github.com/Potterli20/openwrt-tailscale.git
EOF
```

Or, if you already have a feeds.conf.default, append:

```sh
echo 'src-git openwrt_tailscale https://github.com/Potterli20/openwrt-tailscale.git' >> feeds.conf.default
```

## Update & install feed

```sh
./scripts/feeds update openwrt_tailscale || ./scripts/feeds update -a
./scripts/feeds install openwrt_tailscale || ./scripts/feeds install -a
```

## Prepare .config

Remove any conflicting lines and enable the package we provide:

```sh
sed -i '/^CONFIG_PACKAGE_tailscale=/d' .config || true
sed -i '/^CONFIG_PACKAGE_tailscale-upx=/d' .config || true
# enable our package
echo 'CONFIG_PACKAGE_tailscale-upx=y' >> .config
make defconfig
```

If you want to export the raw tailscaled binary into `bin/packages/.../base/`, enable `EXPORT_TAILSCALED` at build time:

```sh
# Enable exporting binary for debugging
make package/tailscale/compile EXPORT_TAILSCALED=1 -j$(nproc) V=s
```

If you want to temporarily replace the official `tailscale` package in your build, run the build script (or set this env var) to enable replacing behavior:

```sh
# Replace the official tailscale (use with caution)
USE_AS_TAILSCALE=1 ./build_scripts/build_ipk.sh <version> <target_arch>
```

## Build package manually

```sh
make package/tailscale/compile -j$(nproc) V=s
```

## Inspect results

```sh
ls -lh bin/packages/*/*/base | grep tailscale || true
grep -A2 '^Package: tailscale-upx' bin/packages/<arch>/base/Packages || true
```

## Notes

- The repository contains `build_scripts/prepare_go_for_openwrt.sh` which helps prepare a modern Go toolchain in `staging_dir` if your buildroot's default Go is outdated.
- The package is named `tailscale-upx` to avoid unintentional conflicts with upstream `tailscale` in OpenWrt feeds. Use `USE_AS_TAILSCALE=1` or modify the Makefile if you intentionally want to override upstream package names.
