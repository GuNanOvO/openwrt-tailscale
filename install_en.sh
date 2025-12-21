#!/bin/sh

# Script Information
SCRIPT_VERSION="v1.08"
SCRIPT_DATE="2025/12/15"

# Basic Configuration
REPO_URL="https://github.com/GuNanOvO/openwrt-tailscale"
REPO="gunanovo/openwrt-tailscale"
TAILSCALE_URL="${REPO_URL}/releases/latest"
TAILSCALE_FILE="" # Set by get_tailscale_info
PACKAGES_TO_CHECK="libc kmod-tun ca-bundle"

# TMP Installation [/usr/sbin/tailscale]
TMP_TAILSCALE='#!/bin/sh
                set -e

                if [ -f "/tmp/tailscale" ]; then
                    /tmp/tailscale "$@"
                fi'
# TMP Installation [/usr/sbin/tailscaled]
TMP_TAILSCALED='#!/bin/sh
                set -e
                if [ -f "/tmp/tailscaled" ]; then
                    /tmp/tailscaled "$@"
                else
                    /usr/sbin/install.sh --tempinstall
                    /tmp/tailscaled "$@"
                fi'

TAILSCALE_LATEST_VERSION="" # Set by get_tailscale_info
TAILSCALE_LOCAL_VERSION=""
IS_TAILSCALE_INSTALLED="false"
TAILSCALE_INSTALL_STATUS="none"
FOUND_TAILSCALE_FILE="false"

DEVICE_TARGET=""
DEVICE_MEM_TOTAL=""
DEVICE_MEM_FREE=""
DEVICE_STORAGE_TOTAL=""
DEVICE_STORAGE_AVAILABLE=""
TAILSCALE_FILE_SIZE="" # Set by get_tailscale_info

TAILSCALE_PERSISTENT_INSTALLABLE=""
TAILSCALE_TEMP_INSTALLABLE=""

ENABLE_INIT_PROGRESS_BAR="true"


# Function: Script Information
script_info() {
    echo "#╔╦╗┌─┐ ┬ ┬  ┌─┐┌─┐┌─┐┬  ┌─┐  ┌─┐┌┐┌  ╔═╗┌─┐┌─┐┌┐┌ ╦ ╦ ┬─┐┌┬┐  ╦ ┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐#"
    echo "# ║ ├─┤ │ │  └─┐│  ├─┤│  ├┤   │ ││││  ║ ║├─┘├┤ │││ ║║║ ├┬┘ │   ║ │││└─┐ │ ├─┤│  │  ├┤ ├┬┘#"
    echo "# ╩ ┴ ┴ ┴ ┴─┘└─┘└─┘┴ ┴┴─┘└─┘  └─┘┘└┘  ╚═╝┴  └─┘┘└┘ ╚╩╝ ┴└─ ┴   ╩ ┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─#"
    echo "┌────────────────────────────────────────────────────────────────────────────────────────┐"
    echo "│ A script for installing Tailscale on OpenWrt, updating Tailscale, or...                │"
    echo "│ Project URL: $REPO_URL                                │"
    echo "│ Script Version: $SCRIPT_VERSION                                                                        │"
    echo "│ Update Date: $SCRIPT_DATE                                                                   │"
    echo "│ Thank you for using, if it helps, please give a star /<3                                 │"
    echo "└────────────────────────────────────────────────────────────────────────────────────────┘"
}

# Function: Get Device Architecture
check_device_target() {
    local exclude_target="powerpc_64_e5500|powerpc_464fp|powerpc_8548|armeb_xscale"
    local raw_target=""

    raw_target=$(opkg print-architecture 2>/dev/null | awk '{print $2}' | grep -vE "all|noarch" | head -n 1)

    if [ -z "$raw_target" ]; then
        raw_target=$(grep "DISTRIB_ARCH" /etc/openwrt_release 2>/dev/null | awk -F"'" '{print $2}')
    fi

    if [ -z "$raw_target" ]; then
        echo "[ERROR]: Unable to get device architecture, script exiting."
        exit 1
    fi

    if echo "$raw_target" | grep -iqE "$exclude_target"; then
        echo "[ERROR]: Current architecture [$raw_target] is in the exclusion list, script exiting."
        exit 1
    fi

    DEVICE_TARGET=$(echo "$raw_target" | tr -d '[:space:]')
}

# Function: Detect Tailscale Installation Status
check_tailscale_install_status() {
    local bin_bin="/usr/bin/tailscaled"
    local bin_sbin="/usr/sbin/tailscaled"
    local bin_tmp="/tmp/tailscaled"
    
    local has_bin=false
    local has_sbin=false
    local has_tmp=false
    local bin_is_script=false

    [ -f "$bin_bin" ] && has_bin=true
    [ -f "$bin_sbin" ] && has_sbin=true
    [ -f "$bin_tmp" ] && has_tmp=true

    if $has_bin; then
        if head -n 1 "$bin_bin" 2>/dev/null | grep -q "^#!"; then
            bin_is_script=true
        fi
    fi
    
    if $has_sbin; then
        if head -n 1 "$bin_sbin" 2>/dev/null | grep -q "^#!"; then
            bin_is_script=true
        fi
    fi

    if command -v tailscale >/dev/null 2>&1; then
        local version_output
        version_output=$(tailscale version 2>/dev/null | head -n 1 | tr -d '[:space:]')
        [ -n "$version_output" ] && TAILSCALE_LOCAL_VERSION="$version_output"
    fi

    # Flexible Status Judgment
    if $has_tmp; then
        if $bin_is_script; then
            # Core scenario: binary in tmp, usr has boot script
            TAILSCALE_INSTALL_STATUS="temp"
            IS_TAILSCALE_INSTALLED="true"
        elif $has_bin || $has_sbin; then
            # Conflict scenario: tmp has, usr also has real binary
            TAILSCALE_INSTALL_STATUS="unknown"
            IS_TAILSCALE_INSTALLED="true"
        else
            # Pure temporary scenario: only tmp has
            TAILSCALE_INSTALL_STATUS="temp"
            IS_TAILSCALE_INSTALLED="true"
        fi
    elif $has_bin || $has_sbin; then
        # Persistent scenario: file in usr/sbin
        TAILSCALE_INSTALL_STATUS="persistent"
        IS_TAILSCALE_INSTALLED="true"
    else
        IS_TAILSCALE_INSTALLED="false"
    fi

    [ "$IS_TAILSCALE_INSTALLED" = "true" ] && FOUND_TAILSCALE_FILE="true"
}

# Function: Check Device Memory
check_device_memory() {
    local mem_info=$(free 2>/dev/null | grep "Mem:")
    local mem_total_kb=$(echo "$mem_info" | awk '{print $2}')
    local mem_available_kb=$(echo "$mem_info" | awk '{print $7}')
    
    [ -z "$mem_available_kb" ] && mem_available_kb=$(echo "$mem_info" | awk '{print $4}')

    if [ -z "$mem_total_kb" ] || ! echo "$mem_total_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: Unable to identify total device memory value" && exit 1
    fi

    if [ -z "$mem_available_kb" ] || ! echo "$mem_available_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: Unable to identify available device memory value" && exit 1
    fi

    DEVICE_MEM_TOTAL=$((mem_total_kb / 1024))
    DEVICE_MEM_FREE=$((mem_available_kb / 1024))
}

# Function: Check Device Storage Space
check_device_storage() {
    local mount_point="${1:-/}"

    local storage_info=$(df -Pk "$mount_point")
    local storage_used_kb=$(echo "$storage_info" | awk 'NR==2 {print $(NF-3)}')
    local storage_available_kb=$(echo "$storage_info" | awk 'NR==2 {print $(NF-2)}')

    if [ -z "$storage_used_kb" ] || ! echo "$storage_used_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: Unable to identify used storage space value for $mount_point" && exit 1
    fi

    if ! echo "$storage_available_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: Unable to identify available storage space value for $mount_point" && exit 1
    fi

    DEVICE_STORAGE_TOTAL=$(( (storage_used_kb + storage_available_kb) / 1024 ))
    DEVICE_STORAGE_AVAILABLE=$((storage_available_kb / 1024))
}

# Function: Get Tailscale Information
get_tailscale_info() {
    local version
    local file
    local file_size
    # Try 3 times
    local attempt_range="1 2 3"
    # Timeout (seconds)
    local attempt_timeout=10

    for attempt_times in $attempt_range; do
        version=$(wget -qO- --timeout=$attempt_timeout "${TAILSCALE_URL}/download/version" | tr -d ' \n\r')
        file="tailscale_${version}_${DEVICE_TARGET}"
        file_size=$(wget -qO- --timeout=$attempt_timeout "${TAILSCALE_URL}/download/Packages" | \
            awk -v ipk="${file}.ipk" '
            BEGIN { RS=""; FS="\n" }
            $0 ~ ipk {
                for(i=1; i<=NF; i++) {
                    if($i ~ /^Installed-Size:/) {
                        print $i
                        exit
                    }
                }
            }' | awk '{print $2}')
            
        if [ -n "$version" ] && [ -n "$file_size" ]; then
            break
        else
            sleep 1
        fi
    done

    if [ -z "$version" ] || [ -z "$file_size" ]; then
        echo ""
        echo "[ERROR]: Unable to get tailscale version or file size"
        echo "1. Ensure network connection is normal"
        echo "2. Retry"
        echo "3. Report to developer"
        exit 1
    fi

    TAILSCALE_LATEST_VERSION="$version"
    TAILSCALE_FILE="$file"
    TAILSCALE_FILE_SIZE=$((file_size / 1024 / 1024))

    if [ "$DEVICE_STORAGE_AVAILABLE" -gt "$TAILSCALE_FILE_SIZE" ]; then
        TAILSCALE_PERSISTENT_INSTALLABLE="true"
    else
        TAILSCALE_PERSISTENT_INSTALLABLE="false"
    fi

    if [ "$DEVICE_MEM_FREE" -gt "$TAILSCALE_FILE_SIZE" ]; then
        TAILSCALE_TEMP_INSTALLABLE="true"
    else
        TAILSCALE_TEMP_INSTALLABLE="false"
    fi
}

# Function: Update
update() {
    echo "[INFO]: Updating..."
    if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ]; then
        temp_install "" "true"
    elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
        persistent_install "" "true"
    fi
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ [WARNING]!!! Please confirm the following:            ║"
        echo "║                                                       ║"
        echo "║ You are updating Tailscale, Tailscale needs restart.  ║"
        echo "║ If you are currently connected to the device via      ║"
        echo "║ Tailscale, you may lose connection. Please confirm    ║"
        echo "║ your operation to avoid loss! Thank you for using!    ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        read -n 1 -p "Confirm restart tailscale? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            /etc/init.d/tailscale stop
            /etc/init.d/tailscale start
            break
        else
            echo "[INFO]: Cancel restart tailscale, you can restart tailscale service later with command: /etc/init.d/tailscale stop && /etc/init.d/tailscale start"
            break
        fi
    done
}

# Function: Uninstall
remove() { 
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ [WARNING]!!! Please confirm the following:            ║"
        echo "║                                                       ║"
        echo "║ You are uninstalling Tailscale. After uninstallation, ║"
        echo "║ all your services relying on Tailscale will fail. If  ║"
        echo "║ you are currently connected to the device via         ║"
        echo "║ Tailscale, you may lose connection. Please confirm    ║"
        echo "║ your operation to avoid loss! Thank you for using!    ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        read -n 1 -p "Confirm uninstall tailscale? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            if [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
                opkg remove tailscale
            fi

            # Remove tailscale or tailscaled files in specified directories
            local directories="/etc/init.d /etc /etc/config /usr/bin /usr/sbin /tmp /var/lib"
            local binaries="tailscale tailscaled"

            # Remove tailscale or tailscaled files in specified directories
            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        rm -rf $dir/$bin
                        echo "[INFO]: Deleted file: $dir/$bin"
                    fi
                done
            done

            ip link delete tailscale0
            script_exit
        else
            echo "[INFO]: Cancel uninstall"
            break
        fi
    done
}

# Function: Clean Unknown Files
remove_unknown_file() {
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ [WARNING]!!! Please confirm the following:            ║"
        echo "║                                                       ║"
        echo "║ You are deleting Tailscale residual files. If these   ║"
        echo "║ files were created by you, they should not be deleted.║"
        echo "║ Please cancel this operation!                         ║"
        echo "║ Please confirm your operation to avoid loss!          ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        # Remove tailscale or tailscaled files in specified directories
        local directories="/etc/init.d /etc /etc/config /usr/bin /usr/sbin /tmp /var/lib"
        local files="tailscale tailscaled"

        for dir in $directories; do
            for file in $files; do
                if [ -f "$dir/$file" ]; then
                    echo "[INFO]: Found file: $dir/$file"
                fi
            done
        done

        read -n 1 -p "Confirm delete residual files? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            for dir in $directories; do
                for file in $files; do
                    if [ -f "$dir/$file" ]; then
                        rm -rf $dir/$file
                        echo "[INFO]: Deleted file: $dir/$file"
                    fi
                done
            done

            ip link delete tailscale0

            echo "[INFO]: All residual files deleted, restarting script..."
            sleep 2
            exec "$0" "$@"

            break
        else
            echo "[INFO]: Cancel delete residual files"
            break
        fi
    done
}

# Function: Clean Old Installation
clean_old_installation() {
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        echo "[INFO]: Cleaning old installation files..."
        local old_paths="/usr/bin/tailscale /usr/bin/tailscaled"
        for file in $old_paths; do
            if [ -f "$file" ]; then
                rm -f "$file"
                echo "[INFO]: Removed old file: $file"
            fi
        done
    fi
}

# Function: Persistent Installation
persistent_install() {
    local confirm2persistent_install=$1
    local silent_install=$2

    if [ "$silent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ [WARNING]!!! Please confirm the following:            ║"
        echo "║                                                       ║"
        echo "║ When using persistent installation, please ensure     ║"
        echo "║ your OpenWrt has at least ${TAILSCALE_FILE_SIZE}M free space,      ║"
        echo "║ recommended more than $(expr $TAILSCALE_FILE_SIZE \* 3)M.                            ║"
        echo "║ If any error occurs during installation, you can      ║"
        echo "║ report at: $REPO_URL/issues  ║"
        echo "║ Provide feedback. Thank you for using! /<3            ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm using persistent installation method to install tailscale? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            return
        fi
    fi

    echo ""
    clean_old_installation

    if [ "$confirm2persistent_install" = "true" ]; then
        tailscale_stoper
        rm -rf /tmp/tailscale
        rm -rf /tmp/tailscaled
        rm -rf /usr/sbin/tailscale
        rm -rf /usr/sbin/tailscaled
    fi
    
    echo ""
    echo "[INFO]: Persistent installation in progress..."
    downloader
    opkg install /tmp/$TAILSCALE_FILE.ipk

    rm -rf "$TAILSCALE_FILE.ipk" "/tmp/$TAILSCALE_FILE.sha256"

    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║ Tailscale installation & service startup complete!!!  ║"
    echo "║                                                       ║"
    echo "║ You can now start using it as you wish!               ║"
    echo "║ Direct startup: tailscale up                          ║"
    echo "║ If any problems occur after installation, you can     ║"
    echo "║ report at: $REPO_URL/issues  ║"
    echo "║ Provide feedback. Thank you for using! /<3            ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""

    echo "[INFO]: Re-initializing script, please wait..."
    init "" "false"
}

# Function: Switch from Temporary to Persistent Installation
temp_to_persistent() {
    persistent_install "true"
}

# Function: Temporary Installation
temp_install() { 
    local confirm2temp_install=$1
    local silent_install=$2

    if [ "$silent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ [WARNING]!!! Please confirm the following:            ║"
        echo "║                                                       ║"
        echo "║ Temporary installation places tailscale files in /tmp ║"
        echo "║ directory, /tmp directory will be cleared after       ║"
        echo "║ device restart. If the script fails to re-download    ║"
        echo "║ tailscale after restart, tailscale will not work      ║"
        echo "║ properly, all your services relying on tailscale will ║"
        echo "║ fail. Please understand and confirm this information  ║"
        echo "║ to avoid loss. Thank you! If persistent installation  ║"
        echo "║ is possible, we recommend you use persistent method!  ║"
        echo "║ If any error occurs during installation, you can      ║"
        echo "║ report at: $REPO_URL/issues  ║"
        echo "║ Provide feedback. Thank you for using! /<3            ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm using temporary installation method to install tailscale? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            return
        fi
    fi

    echo ""
    clean_old_installation

    if [ "$confirm2temp_install" = "true" ]; then
        tailscale_stoper
        rm -rf /usr/sbin/tailscale
        rm -rf /usr/sbin/tailscaled
    fi

    echo ""
    echo "[INFO]: Temporary installation in progress..." 
    downloader

    local ipk_file="/tmp/$TAILSCALE_FILE.ipk"
    local extract_dir="/tmp/ts_extract"

    mkdir -p "$extract_dir"

    echo "[INFO]: Extracting and deploying files..."
    tar -xOzf "$ipk_file" ./data.tar.gz 2>/dev/null | tar -xzC "$extract_dir" 2>/dev/null

    [ -d "$extract_dir/etc" ] && cp -r "$extract_dir/etc/"* /etc/
    [ -d "$extract_dir/lib" ] && cp -r "$extract_dir/lib/"* /lib/
    [ -f "$extract_dir/usr/sbin/tailscale" ] && mv "$extract_dir/usr/sbin/tailscale" /tmp/tailscale
    [ -f "$extract_dir/usr/sbin/tailscaled" ] && mv "$extract_dir/usr/sbin/tailscaled" /tmp/tailscaled

    echo "$TMP_TAILSCALE" > /usr/sbin/tailscale
    echo "$TMP_TAILSCALED" > /usr/sbin/tailscaled

    rm -rf "$extract_dir" "$ipk_file" "/tmp/$TAILSCALE_FILE.sha256"

    echo "[INFO]: Temporary installation complete!"
    echo "[INFO]: Starting tailscale service..."

    opkg update
    opkg install $PACKAGES_TO_CHECK

    chmod +x /etc/init.d/tailscale
    chmod +x /usr/sbin/tailscale
    chmod +x /usr/sbin/tailscaled
    chmod +x /tmp/tailscale
    chmod +x /tmp/tailscaled
    
    /etc/init.d/tailscale enable
    /etc/init.d/tailscale start

    sleep 3

    tailscaled &>/dev/null &
    if [ "$TMP_INSTALL" == "true" ]; then
        tailscale up
    fi
    echo "[INFO]: Tailscale service startup complete"
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║ Tailscale installation & service startup complete!!!  ║"
    echo "║                                                       ║"
    echo "║ You can now start using it as you wish!               ║"
    echo "║ Direct startup: tailscale up                          ║"
    echo "║ If any problems occur after installation, you can     ║"
    echo "║ report at: $REPO_URL/issues  ║"
    echo "║ Provide feedback. Thank you for using! /<3            ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "[INFO]: Re-initializing script, please wait..."
    init "" "false"
}

# Function: Switch from Persistent to Temporary Installation
persistent_to_temp() {
    temp_install "true"
}

# Function: Downloader
downloader() {
    local attempt_range="1 2 3"
    local attempt_timeout=20

    local tmp="/tmp"
    local file_path="$tmp/$TAILSCALE_FILE.ipk"
    local sha_file="$tmp/$TAILSCALE_FILE.sha256"
    local target_ipk="${TAILSCALE_FILE}.ipk"
    local download_url="${TAILSCALE_URL}/releases/latest/download"

    for attempt_times in $attempt_range; do
        if ! wget -cO "$file_path" "$download_url/$target_ipk"; then
            if [ "$attempt_times" == "3" ]; then
                echo "[ERROR]: Tailscale file failed to download three times, restarting script!"
                sleep 3
                init
            fi
            continue
        fi

        wget -qO- --timeout=$attempt_timeout "$download_url/Packages" | \
            awk -v ipk="$target_ipk" -v path="$file_path" '
            BEGIN { RS=""; FS="\n" }
            $0 ~ "Filename: " ipk {
                for(i=1; i<=NF; i++) {
                    if($i ~ /^SHA256sum:/) {
                        split($i, a, ": ");
                        print a[2] "  " path;
                        exit;
                    }
                }
            }' > "$sha_file"

        if [ ! -s "$sha_file" ] || ! sha256sum -c "$sha_file" >/dev/null 2>&1; then
            if [ "$attempt_times" == "3" ]; then
                echo "[ERROR]: Tailscale file failed to download three times, restarting script, please retry!"
                rm -f "$file_path" "$sha_file"
                sleep 3
                init
            else
                echo "[INFO]: Tailscale file verification failed, trying to re-download!"
                rm -f "$file_path" "$sha_file"
                sleep 3
            fi
        else
            echo "[INFO]: Tailscale file verification passed!"
            rm -f "$sha_file"
            break
        fi
    done
}

# Function: Tailscale Service Stopper
tailscale_stoper() {
    echo ""
    if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ]; then
        /etc/init.d/tailscale stop
        /tmp/tailscale down --accept-risk=lose-ssh
        /tmp/tailscale logout
        /etc/init.d/tailscale disable
    elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
        /etc/init.d/tailscale stop
        /usr/sbin/tailscale down --accept-risk=lose-ssh
        /usr/sbin/tailscale logout
        /etc/init.d/tailscale disable
    fi
    echo ""
}

# Function: Initialize
init() {
    local show_init_progress_bar=$1

    local functions="check_device_target check_tailscale_install_status check_device_memory check_device_storage get_tailscale_info"
    local function_count=5
    local total=$function_count
    local progress=0
    
    if [ "$show_init_progress_bar" != "false" ]; then
        echo ""

        printf "\r[INFO] Initializing: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
        
        for function in $functions; do
            eval "$function"
            progress=$((progress + 1))
            percent=$((progress * 100 / function_count))
            bars=$((percent / 2))
            printf "\r[INFO] Initializing: [%-50s] %3d%%" "$(printf '=%.0s' $(seq 1 "$bars"))" "$percent"
        done
    
        printf "\r[INFO]   Complete  : [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$bars"))" "$percent"
    else
        for function in $functions; do
            eval "$function"
        done
    fi
    echo ""
}

# Function: Exit
script_exit() {
        echo "┌───────────────────────────────────────────────────────┐"
        echo "│ THANKS!!! Thank you for your trust and use!!!         │"
        echo "│                                                       │"
        echo "│ If this script helps you, you can give a Star to      │"
        echo "│ support me!                                           │"
        echo "│ $REPO_URL/        │"
        echo "│ If any problems occur after installation, you can     │"
        echo "│ report at: $REPO_URL/issues  │"
        echo "│ Provide feedback. Thank you for using! /<3            │"
        echo "│                                                       │"
        echo "└───────────────────────────────────────────────────────┘"
        exit 0
}


# Function: Show Basic Information
show_info() {
    echo "╔═════════════════════ BASIC INFORMATION ═════════════════════╗"

    echo "   Device Information:"
    echo "     - Current Device TARGET: [${DEVICE_TARGET}]"
    echo "     - Available / Total Storage Space: ($DEVICE_STORAGE_AVAILABLE / $DEVICE_STORAGE_TOTAL) M"
    echo "     - Available / Total Memory: ($DEVICE_MEM_FREE / $DEVICE_MEM_TOTAL) M"
    echo "   "

    echo "   Local Tailscale Information:"
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        echo "     - Installation Status: Installed"
        if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ]; then
            echo "     - Installation Mode: Temporary Installation"
        elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
            echo "     - Installation Mode: Persistent Installation"
        fi
        echo "     - Version: $TAILSCALE_LOCAL_VERSION"
    elif [ "$TAILSCALE_INSTALL_STATUS" = "unknown" ]; then
        echo "     - Installation Status: Abnormal"
        echo "     - Installation Mode: Unknown (tailscale file exists, but tailscale runs abnormally)"
        echo "     - Version: Unknown"
    else
        echo "     - Installation Status: Not Installed"
        echo "     - Installation Mode: Not Installed"
        echo "     - Version: Not Installed"
    
    fi

    echo "   "
    echo "   Latest Tailscale Information:"
    echo "     - Version: $TAILSCALE_LATEST_VERSION"
    echo "     - File Size: $TAILSCALE_FILE_SIZE M" 
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        if [ "$TAILSCALE_LATEST_VERSION" != "$TAILSCALE_LOCAL_VERSION" ]; then
            echo "   Update: New version available, you can choose to update"
        else
            echo "   Update: Already the latest version"
        fi
    fi
    
    echo "   "
    echo "   Tips:"
    if [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
        echo "     - Persistent Installation: Available"
    else
        echo "     - Persistent Installation: Not Available"
    fi
    if [ "$TAILSCALE_TEMP_INSTALLABLE" = "true" ]; then
        echo "     - Temporary Installation: Available"
    else
        echo "     - Temporary Installation: Not Available"
    fi
    if [ "$DEVICE_MEM_FREE" -lt 60 ]; then
        echo "     - Device available memory too low, Tailscale may: Unable to run normally"
    elif [ "$DEVICE_MEM_FREE" -lt 120 ]; then
        echo "     - Device available memory low, Tailscale may: Run sluggishly"
    fi

    echo "╚═════════════════════ BASIC INFORMATION ═════════════════════╝"
}


option_menu() {
    # Display menu and get user input
    while true; do
        local menu_items=""
        local menu_operations=""
        local option_index=1

        menu_items="$option_index).Show-Basic-Information"
        menu_operations="show_info"
        option_index=$((option_index + 1))

        if [ "$IS_TAILSCALE_INSTALLED" = "true" ] && [ "$TAILSCALE_LATEST_VERSION" != "$TAILSCALE_LOCAL_VERSION" ]; then
            menu_items="$menu_items $option_index).Update"
            menu_operations="$menu_operations update"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
            menu_items="$menu_items $option_index).Uninstall"
            menu_operations="$menu_operations remove"
            option_index=$((option_index + 1))
        fi

        if [ "$FOUND_TAILSCALE_FILE" = "true" ] && [ "$TAILSCALE_INSTALL_STATUS" = "unknown" ]; then
            menu_items="$menu_items $option_index).Delete-Residual-Files-(Found-tailscale-file-but-tailscale-runs-abnormally)"
            menu_operations="$menu_operations remove_unknown_file"
            option_index=$((option_index + 1))
        fi

        if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ] && [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
            menu_items="$menu_items $option_index).Switch-to-Persistent-Installation"
            menu_operations="$menu_operations temp_to_persistent"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "false" ] && [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
            menu_items="$menu_items $option_index).Persistent-Installation"
            menu_operations="$menu_operations persistent_install"
            option_index=$((option_index + 1))
        fi

        if [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
            menu_items="$menu_items $option_index).Switch-to-Temporary-Installation"
            menu_operations="$menu_operations persistent_to_temp"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "false" ]; then
            menu_items="$menu_items $option_index).Temporary-Installation"
            menu_operations="$menu_operations temp_install"
            option_index=$((option_index + 1))
        fi

        menu_items="$menu_items $option_index).Exit"
        menu_operations="$menu_operations exit"
        
        echo ""
        echo "┌───────────────────────── MENU ─────────────────────────┐"
        
        # Traverse option list, dynamically generate menu
        for item in $menu_items; do
            echo "│       $item"
        done
        echo ""

        read -n 1 -p "│ Please enter option (1 ~ $option_index): " choice
        echo ""
        echo ""

        # Determine if input is legal
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$option_index" ]; then
            operation_index=1
            for operation in $menu_operations; do
                if [ "$operation_index" = "$choice" ]; then
                    eval "$operation"
                fi
                operation_index=$((operation_index + 1))
            done
            echo ""
        else
            echo "[WARNING]: Invalid option, please try again!"
            echo ""
            break
        fi
    done
}

show_help() {
    echo "Tailscale on OpenWrt installer script. $SCRIPT_VERSION"
    echo "$REPO_URL"
    echo "  Usage:   "
    echo "      --help: Show this help"
    echo "      --tempinstall: Temporary installation mode"

}


# Read Parameters
for arg in "$@"; do
    case $arg in
    --help)
        show_help
        exit 0
        ;;
    --tempinstall)
        TMP_INSTALL="true"
        ;;
    *)
        echo "[ERROR]: Unknown argument: $arg"
        show_help
        ;;
    esac
done

# Main Program

main() {
    clear
    script_info
    init
    sleep 1
    clear
    script_info
    option_menu
}

if [ "$TMP_INSTALL" = "true" ]; then
    check_device_target
    get_tailscale_info
    temp_install "" "true"
    exit 0
fi

main