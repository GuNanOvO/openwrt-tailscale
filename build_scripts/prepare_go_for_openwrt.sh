#!/bin/bash
# Override the Go toolchain used by an OpenWrt buildroot with a newer upstream Go release.
# This is useful when the OpenWrt packages feed provides an older Go version that cannot
# build newer Tailscale releases (for example, when the build fails with "go.mod requires go >= ...").
#
# Usage:
#   ./build_scripts/prepare_go_for_openwrt.sh /path/to/openwrt/buildroot [go_version]
#
# Example:
#   ./build_scripts/prepare_go_for_openwrt.sh /home/user/openwrt 1.26.3
#
# Environment:
#   GO_OS / GO_ARCH   Host platform of the Go tarball (default: detected)
#   GO_DL_BASE        Preferred download base URL
#                     (default: https://golang.google.cn/dl, official China mirror;
#                     https://go.dev/dl is always tried as fallback)

set -euo pipefail

BUILDROOT_DIR="${1:-$PWD}"
GO_VERSION="${2:-${GO_VERSION:-1.26.3}}"
GO_OS="${GO_OS:-linux}"
GO_ARCH="${GO_ARCH:-}"

if [ ! -d "$BUILDROOT_DIR" ]; then
  echo "Error: buildroot directory not found: $BUILDROOT_DIR" >&2
  exit 1
fi

if [ -z "$GO_ARCH" ]; then
  case "$(uname -m)" in
    x86_64|amd64)
      GO_ARCH="amd64"
      ;;
    aarch64|arm64)
      GO_ARCH="arm64"
      ;;
    armv7l|armv6l)
      GO_ARCH="armv6l"
      ;;
    *)
      echo "Unsupported host architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
fi

# golang.google.cn first: official Google mirror, reachable from mainland China
# without a proxy. go.dev is the international fallback and serves the same files.
GO_DL_BASES=(
  "${GO_DL_BASE:-https://golang.google.cn/dl}"
  "https://go.dev/dl"
)

GO_TARBALL="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
GO_INSTALL_DIR="$BUILDROOT_DIR/staging_dir/hostpkg/go"
GO_BIN_DIR="$BUILDROOT_DIR/staging_dir/hostpkg/bin"
GO_HOST_BIN_DIR="$BUILDROOT_DIR/staging_dir/host/bin"
GO_CROSS_BIN_DIR="$BUILDROOT_DIR/staging_dir/hostpkg/lib/go-cross/bin"
DOWNLOAD_DIR="$BUILDROOT_DIR/dl/go-toolchain"

mkdir -p "$DOWNLOAD_DIR" "$GO_BIN_DIR" "$GO_HOST_BIN_DIR" "$GO_CROSS_BIN_DIR"

ARCHIVE_PATH="$DOWNLOAD_DIR/$GO_TARBALL"
if [ ! -f "$ARCHIVE_PATH" ]; then
  downloaded="false"
  for base in "${GO_DL_BASES[@]}"; do
    GO_URL="${base}/${GO_TARBALL}"
    echo "Downloading Go ${GO_VERSION} from ${GO_URL}"
    if curl -fsSL --retry 3 -o "$ARCHIVE_PATH" "$GO_URL"; then
      downloaded="true"
      break
    fi
    rm -f "$ARCHIVE_PATH"
    echo "  Download from ${base} failed, trying next mirror..." >&2
  done
  if [ "$downloaded" != "true" ]; then
    echo "Error: failed to download ${GO_TARBALL} from any mirror" >&2
    exit 1
  fi
else
  echo "Using cached Go archive: $ARCHIVE_PATH"
fi

rm -rf "$GO_INSTALL_DIR"
mkdir -p "$GO_INSTALL_DIR"

echo "Extracting Go ${GO_VERSION} into $GO_INSTALL_DIR"
tar -C "$GO_INSTALL_DIR" --strip-components=1 -xzf "$ARCHIVE_PATH"

ln -sfn "$GO_INSTALL_DIR/bin/go" "$GO_BIN_DIR/go"
ln -sfn "$GO_INSTALL_DIR/bin/gofmt" "$GO_BIN_DIR/gofmt"
ln -sfn "$GO_INSTALL_DIR/bin/go" "$GO_HOST_BIN_DIR/go"
ln -sfn "$GO_INSTALL_DIR/bin/gofmt" "$GO_HOST_BIN_DIR/gofmt"
ln -sfn "$GO_INSTALL_DIR/bin/go" "$GO_CROSS_BIN_DIR/go"

"$GO_INSTALL_DIR/bin/go" version

echo

echo "Go toolchain prepared successfully."
echo ""
echo "To build the package into your firmware:"
echo "  1. Select tailscale in menuconfig:"
echo "       echo 'CONFIG_PACKAGE_tailscale=y' >> .config"
echo "       make defconfig"
echo "  2. Build the full firmware (tailscale compiled automatically):"
echo "       make -j$(nproc) V=s"
echo ""
echo "Or to build only the .ipk package:"
echo "  make package/tailscale/compile -j$(nproc)"
