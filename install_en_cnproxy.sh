#!/bin/sh

# Script Information
SCRIPT_VERSION="v1.07"
SCRIPT_DATE="2025/09/29"
script_info() {
    echo "#╔╦╗┌─┐ ┬ ┬  ┌─┐┌─┐┌─┐┬  ┌─┐  ┌─┐┌┐┌  ╔═╗┌─┐┌─┐┌┐┌ ╦ ╦ ┬─┐┌┬┐  ╦ ┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐#"
    echo "# ║ ├─┤ │ │  └─┐│  ├─┤│  ├┤   │ ││││  ║ ║├─┘├┤ │││ ║║║ ├┬┘ │   ║ │││└─┐ │ ├─┤│  │  ├┤ ├┬┘#"
    echo "# ╩ ┴ ┴ ┴ ┴─┘└─┘└─┘┴ ┴┴─┘└─┘  └─┘┘└┘  ╚═╝┴  └─┘┘└┘ ╚╩╝ ┴└─ ┴   ╩ ┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─#"
    echo "┌────────────────────────────────────────────────────────────────────────────────────────┐"
    echo "│ A script for installing/updating Tailscale on OpenWrt and related operations.          │"
    echo "│ Project URL: https://github.com/GuNanOvO/openwrt-tailscale                             │"
    echo "│ Script Version: "$SCRIPT_VERSION"                                                                  │"
    echo "│ Update Date: "$SCRIPT_DATE"                                                                │"
    echo "│ Thanks for using! If helpful, please give us a star /<3                                │"
    echo "└────────────────────────────────────────────────────────────────────────────────────────┘"
}

# Basic Configuration
TAILSCALE_URL="gunanovo/openwrt-tailscale/releases/latest"
URL_PROXYS="https://ghfast.top/https://github.com
https://cf.ghproxy.cc/https://github.com
https://www.ghproxy.cc/https://github.com
https://gh-proxy.com/https://github.com
https://ghproxy.cc/https://github.com
https://ghproxy.cn/https://github.com
https://www.ghproxy.cn/https://github.com
https://github.com"
INIT_URL="/gunanovo/openwrt-tailscale/blob/main/etc/init.d/tailscale"
MOUNT_POINT="/"
PACKAGES_TO_CHECK="libc kmod-tun ca-bundle"
# tmp tailscale
TMP_TAILSCALE='#!/bin/sh
                set -e

                if [ -f "/tmp/tailscale" ]; then
                    /tmp/tailscale "$@"
                fi'
# tmp tailscaled
TMP_TAILSCALED='#!/bin/sh
                set -e
                if [ -f "/tmp/tailscaled" ]; then
                    /tmp/tailscaled "$@"
                else
                    /usr/bin/install.sh --tempinstall
                    /tmp/tailscaled "$@"
                fi'
# tmp tailscaled
TMP_NORMAL_TAILSCALED='#!/bin/sh
                set -e

                if [ -f "/tmp/tailscaled" ]; then
                    /tmp/tailscaled "$@"
                else
                    /usr/bin/install.sh --tempinstall --notiny
                    /tmp/tailscaled "$@"
                fi'

NO_TINY="false"
USE_CUSTOM_PROXY="false"

tailscale_latest_version=""

is_tailscale_installed=false
tailscale_install_status="none"
found_tailscale_file=false
tailscale_version=""

total_mem=""
free_mem=""
free_space=""
file_size=""
free_space_mb=""
file_size_mb=""
tailscale_persistent_installable=""

show_init_progress_bar="true"

# Function: Set DNS
set_system_dns() {
cat <<EOF > /etc/resolv.conf
search lan
nameserver 223.5.5.5
nameserver 119.29.29.29
EOF
}

# Function: Get system architecture
get_system_arch() {
    arch_=$(uname -m)
    endianness=""

    case "$arch_" in
        i386 | i486 | i586 | i686)
            arch=386
            ;;
        x86_64)
            arch=amd64
            ;;
        armv7l)
            arch=arm
            ;;
        aarch64 | armv8l)
            arch=arm64
            ;;
        geode)
            arch=geode
            ;;
        mips)
            endianness=$(echo -n I | hexdump -o | awk '{ print (substr($2,6,1)=="1") ? "le" : ""; exit }')
            arch=mips${endianness}
            ;;
        riscv64)
            arch=riscv64
            ;;
        *)  
            echo "╔═══════════════════════════════════════════════════════╗"
            echo "   WARNING!!!                                            "
            echo "                                                        "
            echo "   Device architecture detected: [${arch_}${endianness}] "
            echo "   This script does not currently support your device   "
            echo "                                                        "
            echo "╚═══════════════════════════════════════════════════════╝"
            exit 1
            ;;
    esac
}

# Function: Check Tailscale installation status
check_tailscale_install_status() {
    if command -v tailscale >/dev/null 2>&1; then
        version_output=$(tailscale version 2>/dev/null)
        if [ -n "$version_output" ]; then
            tailscale_version=v$(echo "$version_output" | sed -n '1p' | tr -d '[:space:]')
            if [ -f "/usr/bin/tailscaled" ] && [ -f "/tmp/tailscaled" ]; then
                tailscale_install_status="temp"
            elif [ -f "/usr/bin/tailscaled" ]; then
                tailscale_install_status="persistent"
            fi
            is_tailscale_installed="true"
        else
            if [ -f "/usr/bin/tailscaled" ] || [ -f "/tmp/tailscaled" ]; then
                is_tailscale_installed="unknown"
                found_tailscale_file="true"
            fi
        fi
    else
        if [ -f "/usr/bin/tailscaled" ] || [ -f "/tmp/tailscaled" ]; then
            is_tailscale_installed="unknown"
            found_tailscale_file="true"
        fi
    fi
}

# Function: Check free space
get_free_space() {
    if [ -z "$MOUNT_POINT" ]; then
        echo "Error: MOUNT_POINT undefined"
        exit 1
    fi

    free_space_kb=$(df -Pk "$MOUNT_POINT" | awk 'NR==2 {print $(NF-2)}')
    
    total_mem=$(expr $(free | grep Mem | awk '{print $2}') / 1024)
    free_mem=$(expr $(free | grep Mem | awk '{print $7}') / 1024)

    if [ -z "$free_space_kb" ] || ! echo "$free_space_kb" | grep -q '^[0-9]\+$'; then
        echo "Error: Failed to get free space for $MOUNT_POINT"
        exit 1
    fi

    free_space=$((free_space_kb * 1024))
    free_space_mb=$(expr $free_space / 1024 / 1024)
}

# Function: Get Tailscale info
get_tailscale_info() {
    attempt_range="1 2 3"
    attempt_timeout=10
    
    if [ "$NO_TINY" == "true" ]; then
        tailscale_file_name="tailscaled-linux-${arch}-normal"
    else
        tailscale_file_name="tailscaled-linux-${arch}"
    fi

    if [ "$USE_CUSTOM_PROXY" == "true" ]; then
        attempt_url="$available_proxy/$TAILSCALE_URL/download/build-info.txt"
        tailscale_latest_version=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "Version: " | awk '{print $2}')
        file_size=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "$tailscale_file_name " | awk '{print $2}')

        if [ -z "$tailscale_latest_version" ] && [ -z "$file_size" ]; then
            echo ""
            echo "Your custom proxy is unavailable. Exiting..."
            exit 1
        fi
    else
        for attempt_times in $attempt_range; do
            for attempt_proxy in $URL_PROXYS; do
                attempt_url="$attempt_proxy/$TAILSCALE_URL/download/build-info.txt"
                tailscale_latest_version=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "Version: " | awk '{print $2}')
                file_size=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "$tailscale_file_name " | awk '{print $2}')

                if [ -n "$tailscale_latest_version" ] && [ -n "$file_size" ]; then
                    available_proxy="$attempt_proxy"
                    break 2
                fi
            done
        done
    fi
    
    if [ -z "$file_size" ] || ! [[ "$file_size" =~ ^[0-9]+$ ]]; then
        echo "Error: Failed to get Tailscale size"
        echo "1. Check network connection"
        echo "2. Retry"
        echo "3. Report to developer"
        exit 1
    else
        if [ "$free_space" -gt "$file_size" ]; then
            tailscale_persistent_installable=true
        else
            tailscale_persistent_installable=false
        fi
    fi

    file_size_mb=$(expr $file_size / 1024 / 1024)
}

# Function: Update
update() {
    echo "Updating..."
    if [ "$TMP_INSTALL" = "true" ]; then
        temp_install "true"
    else
        if [ "$tailscale_install_status" = "temp" ]; then
            temp_install "true"
        elif [ "$tailscale_install_status" = "persistent" ]; then
            persistent_install "true"
        fi
    fi
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ You are updating Tailscale, which requires a restart. ║"
        echo "║ If you are currently connected to the device via      ║"
        echo "║ Tailscale, you may lose connection to the device.     ║"
        echo "║ Please confirm your operation to avoid disconnection! ║"
        echo "║ Thank you for using!                                  ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        read -n 1 -p "Confirm restarting Tailscale? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            /etc/init.d/tailscale stop
            /etc/init.d/tailscale start
            break
        else
            echo "Tailscale restart canceled, you can restart the Tailscale service later using the command /etc/init.d/tailscale stop && /etc/init.d/tailscale start"
            break
        fi
    done
}

# Function: Remove
remove() { 
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Uninstalling Tailscale will disable all related       ║"
        echo "║ services. You may lose connection if currently using  ║"
        echo "║ Tailscale. Confirm operation to avoid data loss!      ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        read -n 1 -p "Confirm uninstall Tailscale? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
            binaries="tailscale tailscaled"

            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        rm -rf $dir/$bin
                        echo "Removed file: $dir/$bin"
                    fi
                done
            done

            ip link delete tailscale0
            break
            script_exit
        else
            echo "Uninstall canceled"
            break
        fi
    done

}

# Function: Remove unknown files
remove_unknown_file() {
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ You are about to delete Tailscale residual files. If  ║"
        echo "║ you created these files yourself, they should not be  ║"
        echo "║ deleted. Please cancel this operation!                ║"
        echo "║ Please confirm your operation to avoid data loss!     ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
        binaries="tailscale tailscaled"

        for dir in $directories; do
            for bin in $binaries; do
                if [ -f "$dir/$bin" ]; then
                    echo "Found file: $dir/$bin"
                fi
            done
        done
        
        read -n 1 -p "Confirm removing Tailscale residual files? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
            binaries="tailscale tailscaled"

            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        rm -rf $dir/$bin
                        echo "Removed file: $dir/$bin"
                    fi
                done
            done

            ip link delete tailscale0
            
            echo "All residual files removed, restarting script..."
            sleep 2
            exec "$0" "$@"

            break
        else
            echo "Operation canceled"
            break
        fi
    done
}

# Function: Persistent Install
persistent_install() {
    confirm2persistent_install=$1
    if [ "$confirm2persistent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Ensure free space ≥ $file_size_mb MB, recommended ≥ $(expr $file_size_mb \* 3)M.          ║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm persistent install? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
    echo "Persistent installing..."
    fi 
    downloader
    mv -f /tmp/tailscaled /usr/bin
    ln -sv /usr/bin/tailscaled /usr/bin/tailscale
    echo "Persistent installation complete!"
    tailscale_starter
    script_exit
}

# Function: Switch Temp to Persistent
temp_to_persistent() {
    confirm2persistent_install=$1
    if [ "$confirm2persistent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Ensure free space ≥ $file_size_mb MB, recommended ≥ $(expr $file_size_mb \* 3)M.          ║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm persistent install? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
        echo "Switching to persistent install..."
    fi
    tailscale_stoper
    rm -rf /tmp/tailscale
    rm -rf /tmp/tailscaled
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    persistent_install
    script
}

# Function: Temporary Install
temp_install() { 
    confirm2temp_install=$1
    if [ "$confirm2temp_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Temp install uses /tmp directory (cleared on reboot). ║"
        echo "║ Services may fail if script fails after reboot.       ║"
        echo "║ Recommended to use persistent install if possible.    ║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm temporary install? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
        echo "Temporary installing..."
    fi 
    downloader
    ln -sv /tmp/tailscaled /tmp/tailscale
    if [ "$NO_TINY" == "true" ]; then
        echo "$TMP_TAILSCALE" > /usr/bin/tailscale
        echo "$TMP_NORMAL_TAILSCALED" > /usr/bin/tailscaled
    else
        echo "$TMP_TAILSCALE" > /usr/bin/tailscale
        echo "$TMP_TAILSCALED" > /usr/bin/tailscaled
    fi
    echo "Temporary installation complete!"
    tailscale_starter
    script_exit
}

# Function: Switch Persistent to Temp
persistent_to_temp() {
    confirm2temp_install=$1
    if [ "$confirm2temp_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Temp install uses /tmp directory (cleared on reboot). ║"
        echo "║ Services may fail if script fails after reboot.       ║"
        echo "║ Recommended to use persistent install if possible.    ║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm temporary install? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
    fi 
    echo "Switching to temporary install..."
    tailscale_stoper
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    temp_install "true"
    script_exit
}

# Function: Downloader
downloader() {
    if [ "$NO_TINY" == "true" ]; then
        wget -cO /tmp/tailscaled "$available_proxy/$TAILSCALE_URL/download/tailscaled-linux-${arch}-normal"
    else
        wget -cO /tmp/tailscaled "$available_proxy/$TAILSCALE_URL/download/tailscaled-linux-${arch}"
    fi
        wget -cO /etc/init.d/tailscale "$available_proxy/$INIT_URL"
}

# Function: Start Tailscale
tailscale_starter() {
    echo ""
    echo "Starting Tailscale service..."
    chmod +x /etc/init.d/tailscale
    chmod +x /usr/bin/tailscale
    chmod +x /usr/bin/tailscaled
    if [ -f "/tmp/tailscaled" ]; then
        chmod +x /tmp/tailscale
        chmod +x /tmp/tailscaled
    fi

    opkg update
    opkg install $PACKAGES_TO_CHECK
    
    /etc/init.d/tailscale enable
    /etc/init.d/tailscale start

    sleep 3

    tailscaled &>/dev/null &
    tailscaled &>/dev/null &
    if [ "$TMP_INSTALL" == "true" ]; then
        tailscale up
    fi
    echo "Tailscale service started"
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║ Tailscale installation & service started successfully!║"
    echo "║                                                       ║"
    echo "║ You can now start using it as you wish!               ║"
    echo "║ To start directly: tailscale up                       ║"
    echo "║ If you encounter any issues after installation,       ║"
    echo "║ please submit feedback at:                            ║"
    echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
    echo "║ Thank you for using! /<3                              ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
}

# Function: Stop Tailscale
tailscale_stoper() {
    echo ""
    if [ "$tailscale_install_status" = "temp" ]; then
        /etc/init.d/tailscale stop
        /tmp/tailscale down --accept-risk=lose-ssh
        /tmp/tailscale logout
        /etc/init.d/tailscale disable
    elif [ "$tailscale_install_status" = "persistent" ]; then
        /etc/init.d/tailscale stop
        /usr/bin/tailscale down --accept-risk=lose-ssh
        /usr/bin/tailscale logout
        /etc/init.d/tailscale disable
    fi
    echo ""
}

# Function: Initialize
init() {
    show_init_progress_bar=$1
    local functions="set_system_dns get_system_arch check_tailscale_install_status get_free_space get_tailscale_info"
    local function_count=5
    local total=50
    local progress=0
    
    if [ "$show_init_progress_bar" != "false" ]; then
        printf "\rInitializing: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
        
        for function in $functions; do
            printf "\rInitializing: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
            eval "$function"
            progress=$((progress + $((total / $function_count))))
        done
    
        printf "\r   Done  : [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
    else
        for function in $functions; do
            eval "$function"
        done
    fi
}

# Function: Exit message
script_exit() {
        echo "┌───────────────────────────────────────────────────────┐"
        echo "│ THANKS!!! Appreciate your trust and usage!            │"
        echo "│                                                       │"
        echo "│ Please consider giving a star if helpful:             │"
        echo "│ https://github.com/GuNanOvO/openwrt-tailscale/        │"
        echo "│ Report issues at:                                     │"
        echo "│ https://github.com/GuNanOvO/openwrt-tailscale/issues  │"
        echo "└───────────────────────────────────────────────────────┘"
        exit 0
}

# Function: Show info
show_info() {
    echo "╔═════════════════════ Basic Information ══════════════════╗"
    echo "   Device Architecture: [${arch}]"
    if [ "$is_tailscale_installed" = "true" ]; then
        echo "   Tailscale Status: Installed"
        if [ "$tailscale_install_status" = "temp" ]; then
        echo "   Install Mode: Temporary"
        elif [ "$tailscale_install_status" = "persistent" ]; then
        echo "   Install Mode: Persistent"
        fi
        echo "   Tailscale Version: $tailscale_version"
    else 
        if [ "$is_tailscale_installed" = "unknown" ]; then
            echo "   Tailscale Status: Unknown (Residual files detected)"
            echo "   Tailscale Version: N/A"
        else
            echo "   Tailscale Status: Not Installed"
            echo "   Tailscale Version: N/A"
        fi
    fi

    echo "   Latest Tailscale Version: $tailscale_latest_version"
    echo "   Tailscale Size: $file_size B / $(expr $file_size / 1024 / 1024) M" 
    echo "   Free Space: $free_space B / $(expr $free_space / 1024 / 1024) M"

    if [ "$free_space" -gt "$file_size" ]; then
        echo "   Sufficient space for persistent install"
    else
        echo "   Insufficient space for persistent install"
    fi

    echo "   Device Free/Total Memory: $free_mem MB / $total_mem MB"
    if [ "$free_mem" -lt 60 ]; then
        echo "   Device memory is too low, which may cause Tailscale to malfunction"
    elif [ "$free_mem" -lt 120 ]; then
        echo "   Device memory is relatively low, which may cause Tailscale to run slowly"
    fi

    if [ "$USE_CUSTOM_PROXY" = "true" ]; then
        echo "   Using GitHub Custom Proxy: $available_proxy"
    else
        echo "   Using GitHub Proxy: $available_proxy"
    fi

    if [ "$is_tailscale_installed" = "true" ]; then
        if [ $tailscale_latest_version != $tailscale_version ]; then
            echo "   New Tailscale version available, you can choose to update"
        else
            echo "   Tailscale is up to date"
        fi
    fi

    echo "╚═════════════════════ Basic Information ══════════════════╝"
}

# Function: Option menu
option_menu() {
    while true; do
        menu_items=""
        menu_operations=""
        option_index=1

        menu_items="$option_index).Show-Basic-Info"
        menu_operations="show_info"
        option_index=$((option_index + 1))

        if [ "$is_tailscale_installed" = "true" ] && [ $tailscale_latest_version != $tailscale_version ]; then
            menu_items="$menu_items $option_index).Update"
            menu_operations="$menu_operations update"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "true" ]; then
            menu_items="$menu_items $option_index).Uninstall"
            menu_operations="$menu_operations remove"
            option_index=$((option_index + 1))
        fi

        if [ "$found_tailscale_file" = "true" ] && [ "$is_tailscale_installed" = "unknown" ]; then
            menu_items="$menu_items $option_index).Remove-Unknown-Files(Found-tailscale-files-but-tailscale-runs-abnormally)"
            menu_operations="$menu_operations remove_unknown_file"
            option_index=$((option_index + 1))
        fi

        if [ "$tailscale_install_status" = "temp" ] && [ "$tailscale_persistent_installable" = "true" ]; then
            menu_items="$menu_items $option_index).Switch-to-Persistent"
            menu_operations="$menu_operations temp_to_persistent"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "false" ] && [ "$tailscale_persistent_installable" = "true" ]; then
            menu_items="$menu_items $option_index).Persistent-Install"
            menu_operations="$menu_operations persistent_install"
            option_index=$((option_index + 1))
        fi

        if [ "$tailscale_install_status" = "persistent" ]; then
            menu_items="$menu_items $option_index).Switch-to-Temporary"
            menu_operations="$menu_operations persistent_to_temp"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "false" ]; then
            menu_items="$menu_items $option_index).Temporary-Install"
            menu_operations="$menu_operations temp_install"
            option_index=$((option_index + 1))
        fi

        menu_items="$menu_items $option_index).Exit"
        menu_operations="$menu_operations exit"

        while true; do
            echo ""
            echo "┌───────────────────────── Menu ────────────────────────┐"
            
            for item in $menu_items; do
                echo "│       $item"
            done
            echo ""

            read -n 1 -p "│ Enter option (0 ~ $option_index): " choice
            echo ""
            echo ""

            if [ "$choice" -ge 0 ] && [ "$choice" -le "$option_index" ]; then
                operation_index=1
                for operation in $menu_operations; do
                    if [ "$operation_index" = "$choice" ]; then
                        eval "$operation"
                    fi
                    operation_index=$((operation_index + 1))
                done
                echo ""
            else
                echo "Invalid option, please retry!"
                echo ""
                break
            fi
        done
    done
}

# Function: Show help
show_help() {
    echo "Tailscale on OpenWrt installer script. $SCRIPT_VERSION"
    echo "https://github.com/GuNanOvO/openwrt-tailscale"
    echo "  Usage:   "
    echo "      --help: Show this help"
    echo "      --notiny: Use uncompressed version "
    echo "      --custom-proxy: Custom github proxy"
}

# Handle arguments
for arg in "$@"; do
    case $arg in
    --help)
        show_help
        exit 0
        ;;
    --tempinstall)
        TMP_INSTALL="true"
        ;;
    --custom-proxy)
        while true; do
            echo "╔═══════════════════════════════════════════════════════╗"
            echo "║ WARNING!!! Please confirm:                            ║"
            echo "║                                                       ║"
            echo "║ You're setting a custom GitHub proxy. Ensure it's     ║"
            echo "║ valid. Format should be:                              ║"
            echo "║ https://example.com                                   ║"
            echo "║                                                       ║"
            echo "║ Submit working proxies via:                          ║"
            echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
            echo "╚═══════════════════════════════════════════════════════╝"
            read -p "Enter your proxy: " custom_proxy
            while true; do
                echo "Your proxy: $custom_proxy"
                read -n 1 -p "Confirm? (y/N): " choise
                if [ "$choise" == "y" ] || [ "$choise" == "Y" ]; then
                    USE_CUSTOM_PROXY="true"
                    available_proxy="$custom_proxy/https://github.com/"
                    break 2
                else
                    break
                fi 
            done
        done
        ;;
    --notiny)
        NO_TINY="true"
        ;;
    *)
        echo "Unknown argument: $arg"
        show_help
        ;;
    esac
done

# Main Program
main() {
    clear
    script_info
    init
    clear
    script_info
    option_menu
}

if [ "$TMP_INSTALL" = "true" ]; then
    set_system_dns
    get_system_arch 
    get_tailscale_info
    update
    exit 0
fi

main