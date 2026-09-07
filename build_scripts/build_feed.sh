#!/bin/bash
# Build this repository's tailscale package inside an OpenWrt buildroot via a custom feed.
# The package keeps the official name `tailscale`, so the buildroot's stale official
# tailscale (e.g. from a frozen openwrt/packages branch) is replaced instead of duplicated.
#
# Usage:
#   # Remote mode (GitHub feed, recommended for firmware builds):
#   ./build_feed.sh /path/to/openwrt/buildroot
#
#   # Local mode (development, points the feed at a local checkout):
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale
#
#   # With a specific Go version (positional, flag or env):
#   ./build_feed.sh /path/to/openwrt/buildroot /path/to/openwrt-tailscale 1.26.6
#   ./build_feed.sh /path/to/openwrt/buildroot --go-version 1.26.6
#   GO_VERSION=1.26.6 ./build_feed.sh /path/to/openwrt/buildroot
#
#   # Only compile, no index:
#   ./build_feed.sh /path/to/openwrt/buildroot --no-index
#
#   # Only set up the feed and select it in .config, no compile:
#   ./build_feed.sh /path/to/openwrt/buildroot --no-compile
#
#   # One-line online usage (no local checkout needed):
#   bash <(curl -fsSL https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/build_scripts/build_feed.sh) /path/to/openwrt/buildroot
#
# Options:
#   --no-index           Skip 'make package/index'
#   --no-compile         Skip compiling; only set up the feed and select it in
#                        .config (implies --no-index)
#   --go-version <ver>   Pin a Go toolchain version; by default the latest
#                        stable release is auto-detected from golang.google.cn
#                        (fallback: go.dev), with 1.26.6 as the offline fallback
#   -h, --help           Show help
#
# Environment overrides:
#   REPO_URL             Git URL used in remote mode (useful for mirrors)
#   JOBS                 Parallel build jobs (default: nproc)
#   GO_VERSION           Pin a Go version (same as --go-version)
#   GO_VERSION_API       URL queried for the latest Go version
#                        (default: https://golang.google.cn/VERSION?m=text)
#
# The script is idempotent: re-running it after `./scripts/feeds update -a` re-removes
# the official tailscale and rebuilds this repository's version, so the override
# survives feed refreshes. Note that the official tailscale link is removed *before*
# `feeds install`, because OpenWrt silently skips packages that are already installed
# from another feed.

set -euo pipefail

# --------------------------------------------------------------- settings ---

DEFAULT_GO_VERSION="1.26.6"
FEED_NAME="openwrt_tailscale"
REPO_URL="${REPO_URL:-https://github.com/GuNanOvO/openwrt-tailscale.git}"
REPO_OWNER="GuNanOvO"
REPO_NAME="openwrt-tailscale"
JOBS="${JOBS:-$(nproc)}"
BUILD_INDEX="true"
BUILD_PACKAGE="true"
GO_VERSION="${GO_VERSION:-}"
# Latest-version endpoints, tried in order. golang.google.cn first: it is the
# official Google mirror reachable from mainland China without a proxy; go.dev
# is the international fallback. Both return "goX.Y.Z" on the first line.
GO_VERSION_APIS=(
    "${GO_VERSION_API:-https://golang.google.cn/VERSION?m=text}"
    "https://go.dev/VERSION?m=text"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"

# --------------------------------------------------------------- helpers ----

warn() { printf '  [!] %s\n' "$*" >&2; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }

# Detect the latest stable Go version from the official endpoints.
# Sets GO_VERSION_DETECTED and GO_VERSION_SOURCE on success; returns non-zero
# when every endpoint fails or replies with something that does not parse as a
# version (never trust arbitrary remote content blindly).
detect_latest_go_version() {
    local api out ver
    for api in "${GO_VERSION_APIS[@]}"; do
        out="$(curl -fsSL --max-time 15 "$api" 2>/dev/null || true)"
        [ -n "$out" ] || continue
        ver="${out%%$'\n'*}"        # first line only
        ver="${ver//[[:space:]]/}"  # strip any whitespace
        if [[ "$ver" =~ ^go([0-9]+(\.[0-9]+)*)$ ]]; then
            GO_VERSION_DETECTED="${BASH_REMATCH[1]}"
            GO_VERSION_SOURCE="$api"
            return 0
        fi
        warn "unrecognized version reply from ${api}: ${ver:0:40}"
    done
    return 1
}

usage() {
    cat <<'EOF'
Usage: build_feed.sh /path/to/openwrt/buildroot [/path/to/openwrt-tailscale] [go_version] [options]

Builds the openwrt-tailscale package inside an OpenWrt buildroot via a custom feed
named openwrt_tailscale, overriding the official packages-feed version.

Arguments:
  buildroot              OpenWrt buildroot directory (required)
  source                 Local openwrt-tailscale checkout; omit it to use the
                         remote GitHub feed (or $REPO_URL)
  go_version             Pin a Go toolchain version; by default the latest
                         stable release is auto-detected from golang.google.cn
                         (fallback: go.dev)

Options:
  --no-index             Skip 'make package/index'
  --no-compile           Skip compiling; only set up the feed and select the
                         package in .config (implies --no-index)
  --go-version <ver>     Pin the Go toolchain version
  -h, --help             Show this help

Environment:
  REPO_URL               Git URL for remote mode (e.g. a mirror)
  JOBS                   Parallel jobs for make (default: nproc)
  GO_VERSION             Pin a Go version (same as --go-version)
  GO_VERSION_API         URL queried for the latest Go version
                         (default: https://golang.google.cn/VERSION?m=text)
EOF
}

# --------------------------------------------------------------- arg parse ---

POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        --no-index)
            BUILD_INDEX="false"; shift ;;
        --no-compile)
            BUILD_PACKAGE="false"; BUILD_INDEX="false"; shift ;;
        --go-version)
            [ $# -ge 2 ] || die "--go-version requires a value"
            GO_VERSION="$2"; shift 2 ;;
        --go-version=*)
            GO_VERSION="${1#--go-version=}"; shift ;;
        -h|--help)
            usage; exit 0 ;;
        --)
            shift
            while [ $# -gt 0 ]; do POSITIONAL+=("$1"); shift; done
            ;;
        -*)
            die "unknown option: $1 (see --help)" ;;
        *)
            POSITIONAL+=("$1"); shift ;;
    esac
done

BUILDROOT="${POSITIONAL[0]:-}"
TAILSCALE_SRC="${POSITIONAL[1]:-}"
# Precedence: --go-version flag > GO_VERSION env > positional argument;
# when none is given the latest stable version is auto-detected (Step 0).
if [ -z "$GO_VERSION" ] && [ -n "${POSITIONAL[2]:-}" ]; then
    GO_VERSION="${POSITIONAL[2]}"
fi
GO_VERSION_SPECIFIED="false"
if [ -n "$GO_VERSION" ]; then
    GO_VERSION_SPECIFIED="true"
fi

# --------------------------------------------------------------- validation ---

if [ -z "$BUILDROOT" ]; then
    usage >&2
    exit 1
fi
[ -d "$BUILDROOT" ] || die "OpenWrt buildroot directory not found: $BUILDROOT"
BUILDROOT="$(cd "$BUILDROOT" && pwd)"
if [ ! -f "$BUILDROOT/scripts/feeds" ] || [ ! -f "$BUILDROOT/Makefile" ]; then
    die "$BUILDROOT does not look like an OpenWrt buildroot (scripts/feeds or Makefile missing)"
fi
[ -x "$BUILDROOT/scripts/feeds" ] || die "scripts/feeds is not executable; run: chmod +x $BUILDROOT/scripts/feeds"

if [ -n "$TAILSCALE_SRC" ]; then
    [ -d "$TAILSCALE_SRC" ] || die "local openwrt-tailscale source not found: $TAILSCALE_SRC"
    # src-link entries are resolved relative to the buildroot by scripts/feeds,
    # so always store an absolute path.
    TAILSCALE_SRC="$(cd "$TAILSCALE_SRC" && pwd)"
fi

echo "=== OpenWrt Buildroot: $BUILDROOT ==="
cd "$BUILDROOT"

# -- Step 0: Resolve the Go version --
if [ "$GO_VERSION_SPECIFIED" = "true" ]; then
    echo ""
    echo "[Step 0] Go version pinned by user: ${GO_VERSION}"
else
    echo ""
    echo "[Step 0] Detecting latest Go version..."
    if detect_latest_go_version; then
        GO_VERSION="$GO_VERSION_DETECTED"
        echo "  Latest stable Go: ${GO_VERSION} (from ${GO_VERSION_SOURCE})"
    else
        GO_VERSION="$DEFAULT_GO_VERSION"
        warn "could not detect the latest Go version (offline or endpoints changed);"
        warn "falling back to pinned default ${GO_VERSION}. Use --go-version to pin one manually."
    fi
fi

# -- Step 1: Prepare Go toolchain --
# Override the buildroot's Go with a recent upstream release, otherwise newer
# Tailscale sources fail with "go.mod requires go >= ...".
echo ""
echo "[Step 1] Preparing Go ${GO_VERSION} toolchain..."
if [ -n "$SCRIPT_DIR" ] && [ -f "${SCRIPT_DIR}/prepare_go_for_openwrt.sh" ]; then
    bash "${SCRIPT_DIR}/prepare_go_for_openwrt.sh" "$BUILDROOT" "$GO_VERSION"
else
    # Fallback for curl|bash execution: the companion script is not on disk
    # (SCRIPT_DIR resolves to /dev/fd), download it into a temp dir instead.
    echo "  Companion script not found locally, downloading it..."
    command -v curl > /dev/null 2>&1 || die "curl is required to download the companion script"
    PREPARE_TMP="$(mktemp -d)"
    trap 'rm -rf "$PREPARE_TMP"' EXIT
    curl -fsSL "https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/build_scripts/prepare_go_for_openwrt.sh" \
        -o "$PREPARE_TMP/prepare_go_for_openwrt.sh" \
        || die "failed to download prepare_go_for_openwrt.sh"
    bash "$PREPARE_TMP/prepare_go_for_openwrt.sh" "$BUILDROOT" "$GO_VERSION"
fi

# -- Step 2: Set up custom feed --
echo ""
echo "[Step 2] Setting up custom feed: $FEED_NAME"

# OpenWrt reads feeds.conf when it exists and then ignores feeds.conf.default
# entirely (see parse_config() in scripts/feeds), so always edit the active file.
if [ -f feeds.conf ]; then
    FEEDS_CONF="feeds.conf"
elif [ -f feeds.conf.default ]; then
    FEEDS_CONF="feeds.conf.default"
else
    die "no feeds configuration found (feeds.conf / feeds.conf.default) in $BUILDROOT"
fi
echo "  Active feeds config: $FEEDS_CONF"

if [ "$FEEDS_CONF" = "feeds.conf" ] \
   && ! grep -qE '^[[:space:]]*src-' feeds.conf \
   && grep -qE '^[[:space:]]*src-' feeds.conf.default 2> /dev/null; then
    warn "feeds.conf exists but has no feed entries while feeds.conf.default does;"
    warn "OpenWrt ignores feeds.conf.default in that case - other feeds will be missing."
fi

# Keep a single pristine backup so the original state can always be restored.
if [ ! -f "${FEEDS_CONF}.bak" ]; then
    cp "$FEEDS_CONF" "${FEEDS_CONF}.bak"
    echo "  Backup saved: ${FEEDS_CONF}.bak"
fi

# Remove any previous entry of our feed so re-runs stay clean. The boundary
# ([[:space:]]|$) avoids matching feeds whose name merely starts with ours.
sed -i -E "/^[[:space:]]*src-[a-z]+[[:space:]]+${FEED_NAME}([[:space:]]|\$)/d" "$FEEDS_CONF"

if [ -n "$TAILSCALE_SRC" ]; then
    echo "  Using local source: $TAILSCALE_SRC"
    echo "src-link ${FEED_NAME} ${TAILSCALE_SRC}" >> "$FEEDS_CONF"
else
    echo "  Using remote source: ${REPO_URL}"
    echo "src-git ${FEED_NAME} ${REPO_URL}" >> "$FEEDS_CONF"
fi

FEED_LINES="$(grep -cE "^[[:space:]]*src-[a-z]+[[:space:]]+${FEED_NAME}([[:space:]]|\$)" "$FEEDS_CONF" || true)"
if [ "$FEED_LINES" != "1" ]; then
    die "expected exactly one '${FEED_NAME}' line in $FEEDS_CONF, found $FEED_LINES"
fi
grep -E "^[[:space:]]*src-[a-z]+[[:space:]]+${FEED_NAME}([[:space:]]|\$)" "$FEEDS_CONF"

# -- Step 3: Update the feed --
echo ""
echo "[Step 3] Updating feeds..."

# Force a clean checkout/relink so a stale or relocated source cannot survive silently.
rm -rf "feeds/${FEED_NAME}"
./scripts/feeds update "$FEED_NAME"
[ -d "feeds/${FEED_NAME}" ] || die "feed update did not produce feeds/${FEED_NAME}"

# -- Step 4: Remove the official tailscale from other feeds --
# The official packages feed (often frozen on release branches like 24.10) ships an
# old tailscale. Keeping its link around makes the build resolve the wrong Makefile.
# This must happen BEFORE 'feeds install' (Step 5): OpenWrt silently skips a package
# that is already installed from another feed, which would leave no symlink under
# package/feeds/<our feed>/ and break the build on the first run.
# Running it on every invocation also keeps the override alive after 'feeds update -a'.
echo ""
echo "[Step 4] Removing official tailscale from other feeds..."
REMOVED_CONFLICT="false"
# 'tailscaled' is covered too: some feeds historically shipped it as a separate
# package, and our package PROVIDES both names.
for pkgname in tailscale tailscaled; do
    for conflict in package/feeds/*/${pkgname}; do
        [ -e "$conflict" ] || continue
        case "$conflict" in
            package/feeds/${FEED_NAME}/*) continue ;;
        esac
        rm -rf "$conflict"
        echo "  Removed ${conflict}"
        REMOVED_CONFLICT="true"
    done
done
if [ "$REMOVED_CONFLICT" = "false" ]; then
    echo "  No tailscale from other feeds found, nothing to do"
fi

# -- Step 5: Install the package from our feed --
echo ""
echo "[Step 5] Installing tailscale from feed ${FEED_NAME}..."

# -a is required: bare `feeds install -p <feed>` only marks the feed as
# preferred and installs nothing (silently), which leaves no symlink under
# package/feeds/<feed>/. See scripts/feeds install() in OpenWrt 24.10.
./scripts/feeds install -a -p "$FEED_NAME"

PKG_LINK="package/feeds/${FEED_NAME}/tailscale"
if [ ! -d "$PKG_LINK" ]; then
    echo "Error: Feed package not found at ${PKG_LINK}" >&2
    find package/feeds/ -maxdepth 3 -name "Makefile" -path "*tailscale*" 2> /dev/null || true
    exit 1
fi
echo "  Package installed at: ${PKG_LINK}"

LINK_TARGET="$(readlink "$PKG_LINK" 2> /dev/null || true)"
case "$LINK_TARGET" in
    *feeds/${FEED_NAME}/*| "") : ;;
    *) warn "unexpected symlink target for ${PKG_LINK}: ${LINK_TARGET}" ;;
esac

# -- Step 6: Select the package in .config --
echo ""
echo "[Step 6] Selecting tailscale package..."

sed -i '/^CONFIG_PACKAGE_tailscale=/d' .config 2> /dev/null || true
echo "CONFIG_PACKAGE_tailscale=y" >> .config
if ! make defconfig > /dev/null 2>&1; then
    die "make defconfig failed; check the buildroot configuration"
fi
if grep -q '^CONFIG_PACKAGE_tailscale=y' .config 2> /dev/null; then
    echo "  tailscale selected in config"
else
    die "tailscale is not in .config after defconfig; run 'make menuconfig' and check dependencies"
fi

# -- Step 7: Compile (optional) --
if [ "$BUILD_PACKAGE" = "true" ]; then
    echo ""
    echo "[Step 7] Compiling tailscale..."

    make "${PKG_LINK}/clean" > /dev/null 2>&1 || true
    make "${PKG_LINK}/compile" -j"$JOBS" V=s || die "compiling tailscale failed"

    # -- Step 8: Verify build output --
    echo ""
    echo "[Step 8] Verifying build output..."

    # Pick the newest match: bin/ may still hold artifacts of the official tailscale
    # from earlier builds. APK file names use dashes, IPK names use underscores.
    IPK_FILE=""
    if find bin/ -type f -printf '%T@ %p\n' >/dev/null 2>&1; then
        IPK_FILE="$(find bin/ -type f \
                \( -name 'tailscale_*.ipk' -o -name 'tailscale_*.apk' -o -name 'tailscale-*.apk' \) \
                -printf '%T@ %p\n' 2> /dev/null \
            | sort -rn | head -n 1 | cut -d' ' -f2- || true)"
    else
        # BSD/macOS find without -printf: fall back to -newer-based ordering or plain list
        IPK_FILE="$(find bin/ -type f \
                \( -name 'tailscale_*.ipk' -o -name 'tailscale_*.apk' -o -name 'tailscale-*.apk' \) \
                2> /dev/null | head -n 1 || true)"
    fi

    if [ -n "$IPK_FILE" ] && [ -f "$IPK_FILE" ]; then
        echo "  Package generated: $IPK_FILE"
        ls -lh "$IPK_FILE"
    else
        echo "Error: No package file generated!" >&2
        find bin/ -name 'tailscale*' 2> /dev/null || echo "  No tailscale files in bin/" >&2
        exit 1
    fi
else
    echo ""
    echo "[Step 7] Skipped compilation (--no-compile)"
fi

# -- Step 9: Generate index (optional) --
if [ "$BUILD_INDEX" = "true" ]; then
    echo ""
    echo "[Step 9] Generating package index..."

    make package/index V=s || warn "package index generation failed (not fatal)"

    INDEX_FILE="$(find bin/packages -name Packages -type f 2> /dev/null | head -n 1 || true)"
    if [ -n "$INDEX_FILE" ] && grep -q '^Package: tailscale$' "$INDEX_FILE"; then
        echo "  tailscale found in Packages index (${INDEX_FILE})"
    else
        warn "tailscale not found in Packages index"
    fi
elif [ "$BUILD_PACKAGE" = "true" ]; then
    echo ""
    echo "[Step 9] Skipped index generation (--no-index)"
else
    echo ""
    echo "[Step 9] Skipped index generation (--no-compile)"
fi

# -- Done --
echo ""
echo "================================================"
echo " tailscale build completed!"
echo "================================================"
echo ""
if [ "$BUILD_PACKAGE" = "true" ]; then
    echo "Package: $IPK_FILE"
    echo ""
    case "$IPK_FILE" in
        *.ipk) echo "To install on device:  opkg install $IPK_FILE" ;;
        *.apk) echo "To install on device:  apk add --allow-untrusted $IPK_FILE" ;;
    esac
    echo ""
    echo "To build the full firmware with tailscale embedded:"
    echo "  make -j$JOBS V=s"
else
    echo "Feed setup and package selection completed (compilation skipped)."
    echo ""
    echo "To compile the package now:"
    echo "  make ${PKG_LINK}/compile -j$JOBS V=s"
    echo ""
    echo "To build the full firmware with tailscale embedded:"
    echo "  make -j$JOBS V=s"
fi
echo ""
echo "NOTE: running './scripts/feeds update -a && ./scripts/feeds install -a' later"
echo "      brings the official tailscale back - re-run this script to override it again."
