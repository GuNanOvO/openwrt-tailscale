#!/bin/sh

# 脚本信息
SCRIPT_VERSION="v1.1.1"
SCRIPT_DATE="2025/03/24"

# 基本配置
REPO="gunanovo/openwrt-tailscale"
REPO_URL="https://github.com/${REPO}"
URL_HEAD="https://raw.githubusercontent.com/${REPO}/refs/heads/feed"
TAILSCALE_FILE="" # 由get_tailscale_info设置
PACKAGES_TO_CHECK="libc kmod-tun ca-bundle"

# 代理头
PROXYS="https://ghfast.top/${URL_HEAD}
https://gh-proxy.org/${URL_HEAD}
https://cdn.jsdelivr.net/gh/${REPO}@feed
https://raw.githubusercontent.com/${REPO}/refs/heads/feed"

# 使用自定义代理头
USE_CUSTOM_PROXY="false"

# 可用URL_HEAD, 由test_proxy设置
AVAILABLE_URL_HEAD=""

# TMP安装 [/usr/sbin/tailscale]
TMP_TAILSCALE='#!/bin/sh
                set -e

                if [ -f "/tmp/tailscale" ]; then
                    /tmp/tailscale "$@"
                fi'
# TMP安装 [/usr/sbin/tailscaled]
TMP_TAILSCALED='#!/bin/sh
                set -e
                if [ -f "/tmp/tailscaled" ]; then
                    /tmp/tailscaled "$@"
                else
                    /usr/sbin/install.sh --tempinstall
                    /tmp/tailscaled "$@"
                fi'

TAILSCALE_LATEST_VERSION="" # 由get_tailscale_info设置
TAILSCALE_LOCAL_VERSION=""
IS_TAILSCALE_INSTALLED="false"
TAILSCALE_INSTALL_STATUS="none"
FOUND_TAILSCALE_FILE="false"

PACKAGE_MANAGER=""
DEVICE_TARGET=""
DEVICE_MEM_TOTAL=""
DEVICE_MEM_FREE=""
DEVICE_STORAGE_TOTAL=""
DEVICE_STORAGE_AVAILABLE=""
TAILSCALE_FILE_SIZE="" # 由get_tailscale_info设置

TAILSCALE_PERSISTENT_INSTALLABLE=""
TAILSCALE_TEMP_INSTALLABLE=""
TAILSCALE_BINARY_INSTALLABLE=""

# 二进制安装路径 [默认: /usr/sbin]
BINARY_INSTALL_PATH="/usr/sbin"
# 自定义安装路径 (由 --install-path 设置)
CUSTOM_INSTALL_PATH=""
# 安装模式标记文件
TAILSCALE_MODE_MARKER="/usr/sbin/.tailscale_install_mode"

# 免交互模式（跳过确认提示）
YES_MODE="false"

# Cron 自动更新
CRON_SCRIPT="/usr/sbin/tailscale-update-check"
CRON_ID="# tailscale-auto-update"
CRON_LOG="/var/log/tailscale-update.log"

ENABLE_INIT_PROGRESS_BAR="true"


# 函数：脚本信息
script_info() {
    echo "#╔╦╗┌─┐ ┬ ┬  ┌─┐┌─┐┌─┐┬  ┌─┐  ┌─┐┌┐┌  ╔═╗┌─┐┌─┐┌┐┌ ╦ ╦ ┬─┐┌┬┐  ╦ ┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐#"
    echo "# ║ ├─┤ │ │  └─┐│  ├─┤│  ├┤   │ ││││  ║ ║├─┘├┤ │││ ║║║ ├┬┘ │   ║ │││└─┐ │ ├─┤│  │  ├┤ ├┬┘#"
    echo "# ╩ ┴ ┴ ┴ ┴─┘└─┘└─┘┴ ┴┴─┘└─┘  └─┘┘└┘  ╚═╝┴  └─┘┘└┘ ╚╩╝ ┴└─ ┴   ╩ ┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─#"
    echo "┌────────────────────────────────────────────────────────────────────────────────────────┐"
    echo "│ 一个用于在OpenWrt上安装Tailscale或更新Tailscale或...的一个脚本。                       │"
    echo "│ 项目地址: "$REPO_URL"                                │"
    echo "│ 脚本版本: "$SCRIPT_VERSION"                                                                       │"
    echo "│ 更新日期: "$SCRIPT_DATE"                                                                   │"
    echo "│ 感谢您的使用, 如有帮助, 还请点颗star /<3                                               │"
    echo "└────────────────────────────────────────────────────────────────────────────────────────┘"
}

# 函数：设置DNS
set_system_dns() {
    cat <<EOF > /etc/resolv.conf
search lan
nameserver 223.5.5.5
nameserver 119.29.29.29
EOF
}

check_package_manager() {
    if command -v opkg >/dev/null 2>&1; then
        PACKAGE_MANAGER="opkg"
    elif command -v apk >/dev/null 2>&1; then
        PACKAGE_MANAGER="apk"
    else
        PACKAGE_MANAGER=""
        echo "[WARNING]: 未找到包管理器(opkg/apk)"
        echo "[WARNING]: 持久安装和临时安装不可用，可使用 --bin-install 进行二进制安装"
    fi
}

# 函数：获取设备架构
check_device_target() {
    local exclude_target='powerpc_64_e5500|powerpc_464fp|powerpc_8548|armeb_xscale'
    local raw_target

    if [ "$PACKAGE_MANAGER" = "opkg" ]; then
        raw_target="$(opkg print-architecture 2>/dev/null \
            | awk '{print $2}' \
            | grep -vE '^(all|noarch)$' \
            | head -n 1)"
    elif [ "$PACKAGE_MANAGER" = "apk" ]; then
        raw_target="$(cat /etc/apk/arch 2>/dev/null)"
    fi

    if [ -z "$raw_target" ]; then
        echo "[ERROR]: 无法获取设备架构，脚本退出。"
        exit 1
    fi

    raw_target="$(printf '%s' "$raw_target" \
        | tr -d '\r\n\t\\ ' )"

    if printf '%s' "$raw_target" | grep -qiE "$exclude_target"; then
        echo "[ERROR]: 当前架构 [$raw_target] 不受支持，脚本退出。"
        exit 1
    fi

    DEVICE_TARGET="$raw_target"
}

# 函数：检测tailscale安装状态
check_tailscale_install_status() {
    local bin_bin="/usr/bin/tailscaled"
    local bin_sbin="/usr/sbin/tailscaled"
    local bin_tmp="/tmp/tailscaled"

    local has_bin=false
    local has_sbin=false
    local has_tmp=false
    local bin_is_script=false
    local bin_is_symlink=false

    [ -f "$bin_bin" ] && has_bin=true
    [ -f "$bin_sbin" ] && has_sbin=true
    [ -f "$bin_tmp" ] && has_tmp=true
    [ -L "$bin_sbin" ] && bin_is_symlink=true
    [ -L "$bin_bin" ] && bin_is_symlink=true

    if $has_bin && ! $bin_is_symlink; then
        if head -n 1 "$bin_bin" 2>/dev/null | grep -q "^#!"; then
            bin_is_script=true
        fi
    fi

    if $has_sbin && ! $bin_is_symlink; then
        if head -n 1 "$bin_sbin" 2>/dev/null | grep -q "^#!"; then
            bin_is_script=true
        fi
    fi

    if command -v tailscale >/dev/null 2>&1; then
        local version_output
        version_output=$(tailscale version 2>/dev/null | head -n 1 | tr -d '[:space:]')
        [ -n "$version_output" ] && TAILSCALE_LOCAL_VERSION="$version_output"
    fi

    # 灵活状态判定
    if $has_tmp; then
        if $bin_is_script; then
            # 核心场景：二进制在 tmp，usr 下是引导脚本
            TAILSCALE_INSTALL_STATUS="temp"
            IS_TAILSCALE_INSTALLED="true"
        elif $has_bin || $has_sbin; then
            # 冲突场景：tmp 有，usr 也有真实的二进制
            TAILSCALE_INSTALL_STATUS="unknown"
            IS_TAILSCALE_INSTALLED="true"
        else
            # 纯临时场景：只有 tmp 有
            TAILSCALE_INSTALL_STATUS="temp"
            IS_TAILSCALE_INSTALLED="true"
        fi
    elif $has_bin || $has_sbin; then
        if $bin_is_symlink; then
            # 符号链接 → 二进制安装模式（二进制在自定义路径）
            TAILSCALE_INSTALL_STATUS="binary"
            IS_TAILSCALE_INSTALLED="true"
        elif $bin_is_script; then
            # 检查是临时安装脚本还是二进制安装脚本
            if grep -q "/tmp/tailscaled" "$bin_sbin" 2>/dev/null || grep -q "/tmp/tailscaled" "$bin_bin" 2>/dev/null; then
                TAILSCALE_INSTALL_STATUS="temp"
                IS_TAILSCALE_INSTALLED="true"
            else
                TAILSCALE_INSTALL_STATUS="binary"
                IS_TAILSCALE_INSTALLED="true"
            fi
        else
            # 持久化场景：usr/sbin 下有真实二进制文件
            TAILSCALE_INSTALL_STATUS="persistent"
            IS_TAILSCALE_INSTALLED="true"
        fi
    else
        IS_TAILSCALE_INSTALLED="false"
    fi

    # 通过标记文件覆盖检测（处理安装路径 = /usr/sbin 的情况）
    if [ -f "$TAILSCALE_MODE_MARKER" ]; then
        local marker_path
        marker_path=$(cat "$TAILSCALE_MODE_MARKER" 2>/dev/null | cut -d':' -f2)
        if [ -n "$marker_path" ] && [ -f "${marker_path}/tailscaled" ]; then
            TAILSCALE_INSTALL_STATUS="binary"
            IS_TAILSCALE_INSTALLED="true"
            if command -v tailscale >/dev/null 2>&1; then
                local version_output
                version_output=$(tailscale version 2>/dev/null | head -n 1 | tr -d '[:space:]')
                [ -n "$version_output" ] && TAILSCALE_LOCAL_VERSION="$version_output"
            fi
        fi
    fi

    [ "$IS_TAILSCALE_INSTALLED" = "true" ] && FOUND_TAILSCALE_FILE="true"
}

# 函数：检查设备运行内存
check_device_memory() {
    local mem_info=$(free 2>/dev/null | grep "Mem:")
    local mem_total_kb=$(echo "$mem_info" | awk '{print $2}')
    local mem_available_kb=$(echo "$mem_info" | awk '{print $7}')

    [ -z "$mem_available_kb" ] && mem_available_kb=$(echo "$mem_info" | awk '{print $4}')

    if [ -z "$mem_total_kb" ] || ! echo "$mem_total_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: 无法识别设备总内存数值" && exit 1
    fi

    if [ -z "$mem_available_kb" ] || ! echo "$mem_available_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: 无法识别设备可用内存数值" && exit 1
    fi

    DEVICE_MEM_TOTAL=$((mem_total_kb / 1024))
    DEVICE_MEM_FREE=$((mem_available_kb / 1024))
}

# 函数：检查设备存储空间
check_device_storage() {
    local mount_point="${1:-/}"

    local storage_info=$(df -Pk "$mount_point")
    local storage_used_kb=$(echo "$storage_info" | awk 'NR==2 {print $(NF-3)}')
    local storage_available_kb=$(echo "$storage_info" | awk 'NR==2 {print $(NF-2)}')

    if [ -z "$storage_used_kb" ] || ! echo "$storage_used_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: 无法识别 $mount_point 的已用空间数值" && exit 1
    fi

    if ! echo "$storage_available_kb" | grep -q '^[0-9]\+$'; then
        echo "[ERROR]: 无法识别 $mount_point 的可用空间数值" && exit 1
    fi

    DEVICE_STORAGE_TOTAL=$(( (storage_used_kb + storage_available_kb) / 1024 ))
    DEVICE_STORAGE_AVAILABLE=$((storage_available_kb / 1024))
}

# 函数：测试proxy
test_proxy() {
    local attempt_range="1 2 3"
    # 超时时间（秒）
    local attempt_timeout=10
    local version

    for attempt_times in $attempt_range; do
        for attempt_proxy in $PROXYS; do
            attempt_url="$attempt_proxy/${DEVICE_TARGET}/version"
            version=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | tr -d ' \n\r')

            if [ -n "$version" ] && [[ "$version" =~ ^[0-9] ]]; then
                AVAILABLE_URL_HEAD="$attempt_proxy"
                break 2
            fi
        done
    done

    if [ "$USE_CUSTOM_PROXY" == "true" ] && [ -z "$AVAILABLE_URL_HEAD" ]; then
        echo ""
        echo "[ERROR]: 您的自定义代理不可用, 脚本退出..."
        exit 1
    fi

    if [ -z "$AVAILABLE_URL_HEAD" ]; then
        echo "[ERROR]: 所有代理均不可用, 脚本退出..."
        echo "1. 确保网络连接正常"
        echo "2. 重试"
        echo "3. 报告开发者"
        exit 1
    fi
}

# 函数：获取tailscale信息
get_tailscale_info() {
    local version
    local file_size
    # 尝试3次
    local attempt_range="1 2 3"
    # 超时时间（秒）
    local attempt_timeout=10

    for attempt_times in $attempt_range; do
        version=$(wget -qO- --timeout=$attempt_timeout "$AVAILABLE_URL_HEAD/${DEVICE_TARGET}/version" | tr -d ' \n\r')
        file_size=$(wget -qO- --timeout=$attempt_timeout "$AVAILABLE_URL_HEAD/${DEVICE_TARGET}/bin.size" | tr -d ' \n\r')

        if [ -n "$version" ] && [ -n "$file_size" ]; then
            break
        else
            sleep 1
        fi
    done

    if [ -z "$version" ] || [ -z "$file_size" ]; then
        echo ""
        echo "[ERROR]: 无法获取 tailscale 版本或文件大小"
        echo "1. 确保网络连接正常"
        echo "2. 重试"
        echo "3. 报告开发者"
        exit 1
    fi

    TAILSCALE_LATEST_VERSION="$version"
    TAILSCALE_FILE="tailscale-${TAILSCALE_LATEST_VERSION}-r1"
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

    # 二进制安装可行性：检查目标路径所在分区的可用空间
    local binary_path_check="${CUSTOM_INSTALL_PATH:-/usr/sbin}"
    local binary_mount_point="/"
    # 尝试获取二进制安装路径的挂载点
    if [ -d "$binary_path_check" ]; then
        binary_mount_point="$binary_path_check"
    fi
    local binary_storage_info=$(df -Pk "$binary_mount_point" 2>/dev/null | awk 'NR==2 {print $(NF-2)}')
    if [ -n "$binary_storage_info" ] && [ "$binary_storage_info" -gt "$((TAILSCALE_FILE_SIZE * 1024))" ] 2>/dev/null; then
        TAILSCALE_BINARY_INSTALLABLE="true"
    else
        TAILSCALE_BINARY_INSTALLABLE="false"
    fi
}

# 函数：更新
update() {
    echo "[INFO]: 正在更新..."
    if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ]; then
        echo "[INFO]: 检测到临时安装模式，执行临时安装更新..."
        temp_install "" "true"
    elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
        echo "[INFO]: 检测到持久安装模式，执行持久安装更新..."
        persistent_install "" "true"
    elif [ "$TAILSCALE_INSTALL_STATUS" = "binary" ]; then
        echo "[INFO]: 检测到二进制安装模式，执行二进制安装更新..."
        binary_install "" "true"
    fi

    # 如果更新已经重新安装了tailscale, 跳过重启确认
    if [ "$YES_MODE" = "true" ]; then
        echo "[INFO]: --yes 模式, 自动重启tailscale服务..."
        /etc/init.d/tailscale stop 2>/dev/null || true
        /etc/init.d/tailscale start 2>/dev/null || true
        echo "[INFO]: tailscale服务重启完成"
        init "" "false"
        return
    fi

    while true; do
        echo "┌─ [WARNING]!!!请您确认以下信息:"
        echo "│"
        echo "│ 您正在执行更新Tailscale, Tailscale需要重启, 如果您当"
        echo "│ 当前正在通过Tailscale连接至设备有可能断开与设备的连接"
        echo "│ 请您确认您的操作, 避免造成失! 感谢您的使用!"
        echo "└─"
        echo ""

        read -n 1 -p "确认重启tailscale吗? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            echo "[INFO]: 停止tailscale服务..."
            /etc/init.d/tailscale stop
            echo "[INFO]: 启动tailscale服务..."
            /etc/init.d/tailscale start
            echo "[INFO]: tailscale服务重启完成"
            break
        else
            echo "[INFO]: 取消重启tailscale，稍后可自行通过命令 /etc/init.d/tailscale stop && /etc/init.d/tailscale start 来重启tailscale服务"
            break
        fi
    done

    init "" "false"
}

# 函数：卸载
remove() {
    if [ "$YES_MODE" != "true" ]; then
        while true; do
            echo "┌─ [WARNING]!!!请您确认以下信息:"
            echo "│"
            echo "│ 您正在执行卸载Tailscale, 卸载后,您所有依托于Tailscale"
            echo "│ 的服务都将失效, 如果您当前正在通过Tailscale连接至设备"
            echo "│ 则有可能断开与设备的连接, 请您确认您的操作, 避免造成"
            echo "│ 损失! 感谢您的使用!"
            echo "└─"
            echo ""

            read -n 1 -p "确认卸载tailscale吗? (y/N): " choice

            if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
                break
            else
                echo "[INFO]: 取消卸载"
                return
            fi
        done
    fi

    echo "[INFO]: 开始卸载tailscale..."
    tailscale_stoper

    if [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
        echo "[INFO]: 移除持久安装的tailscale包..."
        if [ "$PACKAGE_MANAGER" = "opkg" ]; then
            opkg remove tailscale
            echo "[INFO]: opkg包移除完成"
        elif [ "$PACKAGE_MANAGER" = "apk" ]; then
            apk del tailscale
            echo "[INFO]: apk包移除完成"
        fi
    fi

    # 如果是二进制安装模式，清理二进制安装路径下的文件
    if [ "$TAILSCALE_INSTALL_STATUS" = "binary" ]; then
        local binary_path=""
        if [ -f "$TAILSCALE_MODE_MARKER" ]; then
            binary_path=$(cat "$TAILSCALE_MODE_MARKER" 2>/dev/null | cut -d':' -f2)
        fi
        if [ -z "$binary_path" ]; then
            binary_path="${CUSTOM_INSTALL_PATH:-/usr/sbin}"
        fi
        echo "[INFO]: 清理二进制安装文件: ${binary_path}"
        rm -f "${binary_path}/tailscale" "${binary_path}/tailscaled" 2>/dev/null || true
        echo "[INFO]: 二进制安装文件清理完成"
    fi

    # remove指定目录的 tailscale 或 tailscaled 文件
    local directories="/etc/init.d /etc /etc/config /usr/bin /usr/sbin /tmp /var/lib"
    local binaries="tailscale tailscaled"

    echo "[INFO]: 清理tailscale相关文件..."
    for dir in $directories; do
        for bin in $binaries; do
            if [ -f "$dir/$bin" ]; then
                echo "[INFO]: 删除文件: $dir/$bin"
                rm -rf $dir/$bin
                echo "[INFO]: 已删除文件: $dir/$bin"
            fi
        done
    done

    # 清理安装模式标记
    rm -f "$TAILSCALE_MODE_MARKER" 2>/dev/null || true

    echo "[INFO]: 删除tailscale虚拟网卡..."
    ip link delete tailscale0
    echo "[INFO]: tailscale卸载完成"
    script_exit
}

# 函数：清理未知文件
remove_unknown_file() {
    while true; do
        echo "┌─ [WARNING]!!!请您确认以下信息:"
        echo "│"
        echo "│ 您正在执行删除Tailscale残留文件,如果这些文件为您自行"
        echo "│ 创建,则不应该被删除,请您取消该操作!"
        echo "│ 请您确认您的操作, 避免造成损失!"
        echo "└─"
        echo ""

        # remove指定目录的 tailscale 或 tailscaled 文件
        local directories="/etc/init.d /etc /etc/config /usr/bin /usr/sbin /tmp /var/lib"
        local files="tailscale tailscaled"

        echo "[INFO]: 扫描tailscale残留文件..."
        for dir in $directories; do
            for file in $files; do
                if [ -f "$dir/$file" ]; then
                    echo "[INFO]: 找到文件: $dir/$file"
                fi
            done
        done

        read -n 1 -p "确认删除残留文件吗? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            echo "[INFO]: 开始删除残留文件..."
            tailscale_stoper

            for dir in $directories; do
                for file in $files; do
                    if [ -f "$dir/$file" ]; then
                        echo "[INFO]: 删除文件: $dir/$file"
                        rm -rf $dir/$file
                        echo "[INFO]: 已删除文件: $dir/$file"
                    fi
                done
            done

            echo "[INFO]: 删除tailscale虚拟网卡..."
            ip link delete tailscale0

            echo "[INFO]: 已删除所有残留文件，重启脚本..."
            sleep 2
            exec "$0" "$@"

            break
        else
            echo "[INFO]: 取消删除残留文件"
            break
        fi
    done
}

# 函数：清理旧的安装文件
clean_old_installation() {
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        echo "[INFO]: 清理旧的安装文件..."
        local old_paths="/usr/bin/tailscale /usr/bin/tailscaled"
        for file in $old_paths; do
            if [ -f "$file" ]; then
                echo "[INFO]: 删除旧文件: $file"
                rm -f "$file"
                echo "[INFO]: 已删除旧文件: $file"
            fi
        done
        echo "[INFO]: 旧文件清理完成"
    else
        echo "[INFO]: 未检测到已安装的tailscale，跳过清理"
    fi

    # 始终清理二进制安装标记和自定义路径下的文件
    if [ -f "$TAILSCALE_MODE_MARKER" ]; then
        local bin_path
        bin_path=$(cat "$TAILSCALE_MODE_MARKER" 2>/dev/null | cut -d':' -f2)
        if [ -n "$bin_path" ] && [ "$bin_path" != "/usr/sbin" ]; then
            echo "[INFO]: 清理二进制安装文件: ${bin_path}"
            rm -f "${bin_path}/tailscale" "${bin_path}/tailscaled" 2>/dev/null || true
        fi
        rm -f "$TAILSCALE_MODE_MARKER" 2>/dev/null || true
        echo "[INFO]: 安装标记已清理"
    fi
}

# 函数：持久安装
persistent_install() {
    local confirm2persistent_install=$1
    local silent_install=$2

    if [ "$silent_install" != "true" ]; then
        echo "┌─ [WARNING]!!!请您确认以下信息:"
        echo "│"
        echo "│ 使用持久安装时, 请您确认您的openwrt的剩余空间至少大于"
        echo "│ "$TAILSCALE_FILE_SIZE", 推荐大于$(expr $TAILSCALE_FILE_SIZE \* 3)M."
        echo "│ 安装时产生任何错误, 您可以于:"
        echo "│ "$REPO_URL"/issues"
        echo "│ 提出反馈. 谢谢您的使用! /<3"
        echo "└─"
        echo ""
        read -n 1 -p "确认采用持久安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            echo "[INFO]: 取消持久安装"
            return
        fi
    fi

    echo ""
    clean_old_installation

    if [ "$confirm2persistent_install" = "true" ]; then
        echo "[INFO]: 停止现有tailscale服务..."
        tailscale_stoper
        echo "[INFO]: 清理临时文件..."
        rm -rf /tmp/tailscale
        rm -rf /tmp/tailscaled
        rm -rf /usr/sbin/tailscale
        rm -rf /usr/sbin/tailscaled
        echo "[INFO]: 临时文件清理完成"
    fi

    echo ""
    echo "[INFO]: 正在持久安装..."
    echo "[INFO]: 开始下载tailscale文件..."
    downloader

    local install_success=false
    local install_attempt_range="1 2 3"

    for install_attempt in $install_attempt_range; do
        echo "[INFO]: 安装尝试 $install_attempt/3"
        if [ "$PACKAGE_MANAGER" = "opkg" ]; then
            echo "[INFO]: 移除旧的tailscale包..."
            opkg remove tailscale 2>/dev/null || true
            echo "[INFO]: 安装tailscale IPK包..."
            if opkg install /tmp/$TAILSCALE_FILE.ipk; then
                install_success=true
                echo "[INFO]: IPK包安装成功"
                rm -f "/tmp/$TAILSCALE_FILE.ipk" "/tmp/$TAILSCALE_FILE.sha256"
                break
            else
                echo "[INFO]: IPK包安装失败，准备重试..."
            fi
        elif [ "$PACKAGE_MANAGER" = "apk" ]; then
            echo "[INFO]: 移除旧的tailscale包..."
            apk del tailscale 2>/dev/null || true
            echo "[INFO]: 安装tailscale APK包..."
            if apk add --allow-untrusted /tmp/$TAILSCALE_FILE.apk; then
                install_success=true
                echo "[INFO]: APK包安装成功"
                rm -f "/tmp/$TAILSCALE_FILE.apk" "/tmp/$TAILSCALE_FILE.sha256"
                break
            else
                echo "[INFO]: APK包安装失败，准备重试..."
            fi
        fi
    done

    if ! $install_success; then
        echo "[ERROR]: 包安装失败，已重试3次，可能原因：设备存储空间不足、网络连接异常或未知错误"
        echo "[ERROR]: 请检查设备存储空间、网络连接后重试"
        rm -f "/tmp/$TAILSCALE_FILE.ipk" "/tmp/$TAILSCALE_FILE.apk" "/tmp/$TAILSCALE_FILE.sha256"
        exit 1
    fi

    echo "[INFO]: 验证安装状态..."
    check_tailscale_install_status

    if [ "$TAILSCALE_INSTALL_STATUS" == "persistent" ] && [ "$IS_TAILSCALE_INSTALLED" == "true" ]; then
        echo "[INFO]: 持久安装完成!"
        echo "[INFO]: 正在启动tailscale服务..."

        tailscaled up &>/dev/null &

        if [ "$silent_install" != "true" ]; then
            echo ""
            echo "┌─ Tailscale安装&服务启动完成!!!"
            echo "│"
            echo "│ 现在您可以按照您希望的方式开始使用!"
            echo "│ 直接启动: tailscale up"
            echo "│ 安装后有任何无法使用的问题, 可以于:"
            echo "│ "$REPO_URL"/issues"
            echo "│ 提出反馈. 谢谢您的使用! /<3"
            echo "└─"
            echo ""
            echo ""
            echo "[INFO]: 正在重新初始化脚本, 请稍候..."
            init "" "false"
        fi
    else
        echo "[ERROR]: 持久安装失败，请检查安装日志"
        exit 1
    fi
}

# 函数：临时安装切换到持久安装
temp_to_persistent() {
    persistent_install "true"
}

# 函数：临时安装
temp_install() {
    local confirm2temp_install=$1
    local silent_install=$2

    if [ "$silent_install" != "true" ]; then
        echo "┌─ [WARNING]!!!请您确认以下信息:"
        echo "│"
        echo "│ 临时安装是将tailscale文件置于/tmp目录, /tmp目录会在重"
        echo "│ 启设备后清空. 如果该脚本在重启后重新下载tailscale失败"
        echo "│ 则tailscale将无法正常使用, 您所有依托于tailscale的服"
        echo "│ 务都将失效, 请您明悉并确定该讯息, 以免造成损失. 谢谢!"
        echo "│ 如果可以持久安装，推荐您采取持久安装方式!"
        echo "│ 安装时产生任何错误, 您可以于:"
        echo "│ "$REPO_URL"/issues"
        echo "│ 提出反馈. 谢谢您的使用! /<3"
        echo "└─"
        echo ""
        read -n 1 -p "确认采用临时安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            echo "[INFO]: 取消临时安装"
            return
        fi
    fi

    echo ""
    clean_old_installation

    if [ "$confirm2temp_install" = "true" ]; then
        echo "[INFO]: 停止现有tailscale服务..."
        tailscale_stoper
        echo "[INFO]: 清理持久安装文件..."
        rm -rf /usr/sbin/tailscale
        rm -rf /usr/sbin/tailscaled
        echo "[INFO]: 持久安装文件清理完成"
    fi

    echo ""
    echo "[INFO]: 正在临时安装..."

    local attempt_range="1 2 3"
    local attempt_timeout=20

    local sha_file="/tmp/tailscaled.sha256"
    local file_path="/tmp/tailscaled"

    for attempt_times in $attempt_range; do
        echo "[INFO]: 下载尝试 $attempt_times/3"
        echo "[INFO]: 下载tailscaled二进制文件..."
        if ! wget -cO "$file_path" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/tailscaled"; then
            if [ "$attempt_times" == "3" ]; then
                echo "[ERROR]: tailscaled 三次下载均失败，可能原因：网络连接异常或代理不可用"
                echo "[ERROR]: 即将重启脚本，请检查网络连接后重试"
                sleep 3
                init
            fi
            echo "[INFO]: 下载失败，准备重试..."
            continue
        fi

        echo "[INFO]: 下载配置文件和初始化脚本..."
        wget -cO "$sha_file" --timeout="$attempt_timeout"  "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/bin.sha256"
        wget -cO "/etc/config/tailscale" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/tailscale.conf"
        wget -cO  "/etc/init.d/tailscale" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/tailscale.init"

        printf "$(cat "$sha_file" | tr -d '\n\r')" > "$sha_file"
        printf "  $file_path" >> "$sha_file"

        echo "[INFO]: 验证文件完整性..."
        if [ ! -s "$sha_file" ] || ! sha256sum -c "$sha_file" >/dev/null 2>&1; then
            if [ "$attempt_times" == "3" ]; then
                echo "[ERROR]: tailscaled 文件三次下载均失败，可能原因：文件损坏或网络不稳定"
                echo "[ERROR]: 即将重启脚本，请重试"
                sleep 3
                rm -f "$file_path" "$sha_file"
                init
            else
                echo "[INFO]: tailscaled 文件校验不通过，正在尝试重新下载..."
                rm -f "$file_path" "$sha_file"
                sleep 3
            fi
        else
            echo "[INFO]: tailscaled 文件校验通过!"
            rm -f "$sha_file"
            break
        fi
    done

    echo "[INFO]: 创建启动脚本..."
    echo "$TMP_TAILSCALE" > /usr/sbin/tailscale
    echo "$TMP_TAILSCALED" > /usr/sbin/tailscaled
    ln -sf /tmp/tailscaled /tmp/tailscale

    if [ "$TMP_INSTALL" != "true" ]; then
        echo "[INFO]: 安装依赖包..."
        local pkg_install_success=false
        local pkg_attempt_range="1 2 3"

        for pkg_attempt in $pkg_attempt_range; do
            echo "[INFO]: 依赖包安装尝试 $pkg_attempt/3"
            if [ "$PACKAGE_MANAGER" = "opkg" ]; then
                echo "[INFO]: 更新opkg包列表..."
                opkg update || continue
                echo "[INFO]: 安装依赖包: $PACKAGES_TO_CHECK"
                opkg install $PACKAGES_TO_CHECK || continue

                local all_installed=true
                for pkg in $PACKAGES_TO_CHECK; do
                    opkg list-installed | grep -q "^$pkg " || { all_installed=false; break; }
                done

                if $all_installed; then
                    pkg_install_success=true
                    echo "[INFO]: 所有依赖包安装成功"
                    break
                fi
            elif [ "$PACKAGE_MANAGER" = "apk" ]; then
                echo "[INFO]: 更新apk包列表..."
                apk update || continue
                echo "[INFO]: 安装依赖包: $PACKAGES_TO_CHECK"
                apk add --no-cache $PACKAGES_TO_CHECK || continue

                local all_installed=true
                for pkg in $PACKAGES_TO_CHECK; do
                    apk info | grep -q "^$pkg$" || { all_installed=false; break; }
                done

                if $all_installed; then
                    pkg_install_success=true
                    echo "[INFO]: 所有依赖包安装成功"
                    break
                fi
            fi
        done

        if ! $pkg_install_success; then
            echo "[ERROR]: 依赖包安装失败，已重试3次，可能原因：网络连接异常或包源不可用"
            exit 1
        fi
    fi

    echo "[INFO]: 设置文件权限..."
    chmod +x /etc/init.d/tailscale
    chmod +x /usr/sbin/tailscale
    chmod +x /usr/sbin/tailscaled
    chmod +x /tmp/tailscale
    chmod +x /tmp/tailscaled

    echo "[INFO]: 临时安装完成!"
    echo "[INFO]: 正在启动tailscale服务..."

    /etc/init.d/tailscale enable
    /etc/init.d/tailscale start

    sleep 3

    tailscaled up &>/dev/null &

    sleep 2
    check_tailscale_install_status

    if [ "$TAILSCALE_INSTALL_STATUS" == "temp" ] && [ "$IS_TAILSCALE_INSTALLED" == "true" ]; then
        if [ "$silent_install" != "true" ]; then
            echo "[INFO]: tailscale服务启动完成"
            echo ""
            echo "┌─ Tailscale安装&服务启动完成!!!"
            echo "│"
            echo "│ 现在您可以按照您希望的方式开始使用!"
            echo "│ 直接启动: tailscale up"
            echo "│ 安装后有任何无法使用的问题, 可以于:"
            echo "│ "$REPO_URL"/issues"
            echo "│ 提出反馈. 谢谢您的使用! /<3"
            echo "└─"
            echo ""
            echo "[INFO]: 正在重新初始化脚本, 请稍候..."
            init "" "false"
        fi
    else
        echo "[ERROR]: 临时安装失败，请检查安装日志"
        exit 1
    fi
}

# 函数：持久安装切换到临时安装
persistent_to_temp() {
    temp_install "true"
}

# ──────────────────────────────────────────────
# 二进制安装模式
# ──────────────────────────────────────────────

# 函数：二进制安装
binary_install() {
    local confirm2binary_install=$1
    local silent_install=$2

    # 确定安装路径
    local install_path="${CUSTOM_INSTALL_PATH:-/usr/sbin}"
    if [ -z "$install_path" ]; then
        install_path="/usr/sbin"
    fi

    if [ "$silent_install" != "true" ]; then
        echo "┌─ [WARNING]!!!请您确认以下信息:"
        echo "│"
        echo "│ 二进制安装模式将直接下载 tailscaled 可执行文件到指定路径"
        if [ -n "$CUSTOM_INSTALL_PATH" ]; then
            echo "│ 安装路径: ${install_path}"
            echo "│ 请确保该路径所在设备有足够空间(至少 ${TAILSCALE_FILE_SIZE}M)"
        fi
        echo "│ 此模式不使用 opkg/apk 包管理器进行安装"
        echo "│ 但仍会尝试通过包管理器安装依赖库"
        echo "│ 如果包管理器不可用，您需要手动安装以下依赖："
        echo "│   ${PACKAGES_TO_CHECK}"
        echo "│ 安装时产生任何错误, 您可以于:"
        echo "│ ${REPO_URL}/issues"
        echo "│ 提出反馈. 谢谢您的使用! /<3"
        echo "└─"
        echo ""
        read -n 1 -p "确认采用二进制安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            echo "[INFO]: 取消二进制安装"
            return
        fi
    fi

    echo ""
    clean_old_installation

    if [ "$confirm2binary_install" = "true" ]; then
        echo "[INFO]: 停止现有tailscale服务..."
        tailscale_stoper
        echo "[INFO]: 清理旧安装文件..."
        rm -rf /tmp/tailscale /tmp/tailscaled
        echo "[INFO]: 清理完成"
    fi

    echo ""
    echo "[INFO]: 正在二进制安装..."
    echo "[INFO]: 安装路径: ${install_path}"

    # 创建安装目录
    mkdir -p "${install_path}" 2>/dev/null || {
        echo "[ERROR]: 无法创建安装目录 ${install_path}"
        echo "[ERROR]: 请检查路径权限"
        exit 1
    }

    # 检查目标路径可用空间
    local target_avail=$(df -Pk "${install_path}" 2>/dev/null | awk 'NR==2 {print $(NF-2)}')
    if [ -n "$target_avail" ] && [ "$target_avail" -lt "$((TAILSCALE_FILE_SIZE * 1024))" ] 2>/dev/null; then
        echo "[WARNING]: 目标路径 ${install_path} 可用空间不足 ${TAILSCALE_FILE_SIZE}M"
        echo "[WARNING]: 当前可用: $((target_avail / 1024))M"
        read -n 1 -p "是否继续? (y/N): " space_choice
        if [ "$space_choice" != "Y" ] && [ "$space_choice" != "y" ]; then
            echo "[INFO]: 取消安装"
            return
        fi
    fi

    local attempt_range="1 2 3"
    local attempt_timeout=20

    local sha_file="/tmp/tailscaled.sha256"
    local file_path="${install_path}/tailscaled"

    for attempt_times in $attempt_range; do
        echo "[INFO]: 下载尝试 $attempt_times/3"
        echo "[INFO]: 下载tailscaled二进制文件..."
        if ! wget -cO "$file_path" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/tailscaled"; then
            if [ "$attempt_times" = "3" ]; then
                echo "[ERROR]: tailscaled 三次下载均失败，可能原因：网络连接异常或代理不可用"
                echo "[ERROR]: 即将重启脚本，请检查网络连接后重试"
                sleep 3
                rm -f "$file_path"
                init
            fi
            echo "[INFO]: 下载失败，准备重试..."
            continue
        fi

        echo "[INFO]: 下载配置文件和初始化脚本..."
        wget -cO "$sha_file" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/bin.sha256"
        wget -cO "/etc/config/tailscale" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/tailscale.conf"
        wget -cO "/etc/init.d/tailscale" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/tailscale.init"

        printf "$(cat "$sha_file" | tr -d '\n\r')" > "$sha_file"
        printf "  $file_path" >> "$sha_file"

        echo "[INFO]: 验证文件完整性..."
        if [ ! -s "$sha_file" ] || ! sha256sum -c "$sha_file" >/dev/null 2>&1; then
            if [ "$attempt_times" = "3" ]; then
                echo "[ERROR]: tailscaled 文件三次下载均失败，可能原因：文件损坏或网络不稳定"
                echo "[ERROR]: 即将重启脚本，请重试"
                sleep 3
                rm -f "$file_path" "$sha_file"
                init
            else
                echo "[INFO]: tailscaled 文件校验不通过，正在尝试重新下载..."
                rm -f "$file_path" "$sha_file"
                sleep 3
            fi
        else
            echo "[INFO]: tailscaled 文件校验通过!"
            rm -f "$sha_file"
            break
        fi
    done

    # 设置可执行权限
    chmod +x "$file_path" 2>/dev/null

    # 创建安装模式标记
    echo "binary:${install_path}" > "$TAILSCALE_MODE_MARKER" 2>/dev/null || true

    # 在安装路径下创建 tailscale -> tailscaled 符号链接
    ln -sf "tailscaled" "${install_path}/tailscale" 2>/dev/null || true

    # 如果安装路径不是 /usr/sbin，在 /usr/sbin 下创建符号链接指向实际位置
    if [ "$install_path" != "/usr/sbin" ]; then
        ln -sf "${install_path}/tailscaled" "/usr/sbin/tailscaled" 2>/dev/null || true
        ln -sf "${install_path}/tailscale" "/usr/sbin/tailscale" 2>/dev/null || true
    fi

    # 安装依赖包（如果包管理器可用）
    if [ -n "$PACKAGE_MANAGER" ]; then
        echo "[INFO]: 安装依赖包..."
        local pkg_install_success=false
        local pkg_attempt_range="1 2 3"

        for pkg_attempt in $pkg_attempt_range; do
            echo "[INFO]: 依赖包安装尝试 $pkg_attempt/3"
            if [ "$PACKAGE_MANAGER" = "opkg" ]; then
                echo "[INFO]: 更新opkg包列表..."
                opkg update || continue
                echo "[INFO]: 安装依赖包: $PACKAGES_TO_CHECK"
                opkg install $PACKAGES_TO_CHECK || continue

                local all_installed=true
                for pkg in $PACKAGES_TO_CHECK; do
                    opkg list-installed | grep -q "^$pkg " || { all_installed=false; break; }
                done

                if $all_installed; then
                    pkg_install_success=true
                    echo "[INFO]: 所有依赖包安装成功"
                    break
                fi
            elif [ "$PACKAGE_MANAGER" = "apk" ]; then
                echo "[INFO]: 更新apk包列表..."
                apk update || continue
                echo "[INFO]: 安装依赖包: $PACKAGES_TO_CHECK"
                apk add --no-cache $PACKAGES_TO_CHECK || continue

                local all_installed=true
                for pkg in $PACKAGES_TO_CHECK; do
                    apk info | grep -q "^$pkg$" || { all_installed=false; break; }
                done

                if $all_installed; then
                    pkg_install_success=true
                    echo "[INFO]: 所有依赖包安装成功"
                    break
                fi
            fi
        done

        if ! $pkg_install_success; then
            echo "[WARNING]: 部分依赖包安装失败"
            echo "[WARNING]: 请手动安装: $PACKAGES_TO_CHECK"
            echo "[WARNING]: 缺少依赖可能导致 tailscale 运行异常"
        fi
    else
        echo "[WARNING]: 未检测到包管理器，请确保以下依赖已手动安装:"
        echo "[WARNING]:   $PACKAGES_TO_CHECK"
    fi

    # 修改 init.d 脚本中的二进制路径
    if [ "$install_path" != "/usr/sbin" ]; then
        echo "[INFO]: 更新init.d脚本中的二进制路径..."
        if [ -f "/etc/init.d/tailscale" ]; then
            sed -i "s|/usr/sbin/tailscaled|${install_path}/tailscaled|g" "/etc/init.d/tailscale" 2>/dev/null || true
        fi
    fi

    echo "[INFO]: 设置文件权限..."
    chmod +x "/etc/init.d/tailscale" 2>/dev/null || true
    chmod +x "/usr/sbin/tailscale" 2>/dev/null || true
    chmod +x "/usr/sbin/tailscaled" 2>/dev/null || true

    echo "[INFO]: 二进制安装完成!"
    echo "[INFO]: 正在启动tailscale服务..."

    /etc/init.d/tailscale enable 2>/dev/null || true
    /etc/init.d/tailscale start 2>/dev/null || true

    sleep 3

    # 尝试启动 tailscaled
    if [ -f "${install_path}/tailscaled" ]; then
        ${install_path}/tailscaled up &>/dev/null &
    fi

    sleep 2
    check_tailscale_install_status

    if [ "$TAILSCALE_INSTALL_STATUS" = "binary" ] && [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        if [ "$silent_install" != "true" ]; then
            echo "[INFO]: tailscale服务启动完成"
            echo ""
            echo "┌─ Tailscale安装&服务启动完成!!!"
            echo "│"
            echo "│ 安装路径: ${install_path}"
            echo "│ 现在您可以按照您希望的方式开始使用!"
            echo "│ 直接启动: tailscale up"
            echo "│ 安装后有任何无法使用的问题, 可以于:"
            echo "│ ${REPO_URL}/issues"
            echo "│ 提出反馈. 谢谢您的使用! /<3"
            echo "└─"
            echo ""
            echo "[INFO]: 正在重新初始化脚本, 请稍候..."
            init "" "false"
        fi
    else
        echo "[ERROR]: 二进制安装失败，请检查安装日志"
        exit 1
    fi
}

# 函数：临时安装切换到二进制安装
temp_to_binary() {
    binary_install "true"
}

# 函数：持久安装切换到二进制安装
persistent_to_binary() {
    binary_install "true"
}

# 函数：二进制安装切换到持久安装
binary_to_persistent() {
    persistent_install "true"
}

# 函数：二进制安装切换到临时安装
binary_to_temp() {
    temp_install "true"
}

# ──────────────────────────────────────────────
# Cron 自动更新
# ──────────────────────────────────────────────

# 函数：更简单的版本号比较 (返回 0 表示有新版本)
version_gt() {
    test "$(echo "$@" | tr " " "\n" | sort -V | tail -n 1)" = "$1"
}

# 函数：cron 检测更新（被 cron 脚本调用）
cron_check_update() {
    local old_version="$TAILSCALE_LOCAL_VERSION"
    local new_version="$TAILSCALE_LATEST_VERSION"

    if [ -z "$old_version" ] || [ "$old_version" = "none" ]; then
        echo "[$(date)] TAILSCALE_CRON: 未检测到已安装版本, 跳过更新检查" >> "$CRON_LOG"
        return 0
    fi

    if [ -z "$new_version" ]; then
        echo "[$(date)] TAILSCALE_CRON: 无法获取远程版本, 可能网络不可达" >> "$CRON_LOG"
        return 0
    fi

    echo "[$(date)] TAILSCALE_CRON: 本地版本=$old_version, 远程版本=$new_version" >> "$CRON_LOG"

    if [ "$old_version" = "$new_version" ]; then
        echo "[$(date)] TAILSCALE_CRON: 已是最新版本, 无需更新" >> "$CRON_LOG"
        return 0
    fi

    if version_gt "$new_version" "$old_version"; then
        echo "[$(date)] TAILSCALE_CRON: 发现新版本 $new_version (当前 $old_version), 开始自动更新..." >> "$CRON_LOG"
        # 根据当前安装模式自动选择更新方式
        case "$TAILSCALE_INSTALL_STATUS" in
            temp)
                temp_install "" "true" 2>&1 >> "$CRON_LOG"
                ;;
            persistent)
                persistent_install "" "true" 2>&1 >> "$CRON_LOG"
                ;;
            binary)
                binary_install "" "true" 2>&1 >> "$CRON_LOG"
                ;;
        esac
        echo "[$(date)] TAILSCALE_CRON: 更新完成(模式=$TAILSCALE_INSTALL_STATUS)" >> "$CRON_LOG"
    fi
}

# 函数：生成 cron 检查脚本
generate_cron_script() {
    cat > "$CRON_SCRIPT" << 'CRONEOF'
#!/bin/sh
# Tailscale 自动更新检查脚本 - 由 install.sh 生成
# 此脚本被 crond 定时调用

# 获取脚本路径 (install.sh 可能在不同位置)
SCRIPT_CANDIDATES="/usr/sbin/install.sh /tmp/install.sh /mnt/install.sh
$(dirname "$0")/install.sh"

for script in $SCRIPT_CANDIDATES; do
    if [ -f "$script" ]; then
        # 运行 cron-check (初始化 + 版本比较 + 自动更新)
        sh "$script" --cron-check
        exit $?
    fi
done

# 如果找不到 install.sh, 尝试直接下载版本信息并记录
LOG="/var/log/tailscale-update.log"
echo "[$(date)] TAILSCALE_CRON: 错误 - 找不到 install.sh" >> "$LOG"
exit 1
CRONEOF
    chmod +x "$CRON_SCRIPT"
}

# 函数：设置 crontab
cron_setup() {
    local interval="${1:-daily}"

    # 生成检查脚本
    generate_cron_script

    # 解析时间间隔
    local cron_time=""
    case "$interval" in
        hourly)    cron_time="0 * * * *" ;;
        daily)     cron_time="0 4 * * *" ;;
        weekly)    cron_time="0 4 * * 0" ;;
        monthly)   cron_time="0 4 1 * *" ;;
        */minutes) cron_time="*/$interval * * * *" ;;
        *)
            # 尝试作为分钟数解析
            if echo "$interval" | grep -q '^[0-9]\+$'; then
                cron_time="*/${interval} * * * *"
            else
                echo "[ERROR]: 未知间隔 '$interval', 使用 daily"
                cron_time="0 4 * * *"
            fi
            ;;
    esac

    # 写入 crontab
    local cron_line="${cron_time} ${CRON_ID} ${CRON_SCRIPT} >/dev/null 2>&1"

    # 检查是否已存在
    if grep -q "$CRON_ID" /etc/crontabs/root 2>/dev/null; then
        sed -i "/$CRON_ID/d" /etc/crontabs/root 2>/dev/null
        echo "[INFO]: 已移除旧的 cron 条目"
    fi

    echo "$cron_line" >> /etc/crontabs/root 2>/dev/null || {
        echo "[ERROR]: 无法写入 /etc/crontabs/root, 请检查权限"
        return 1
    }

    # 确保 crond 正在运行
    if ! pgrep crond >/dev/null 2>&1; then
        /etc/init.d/cron start 2>/dev/null || crond -b 2>/dev/null || true
    fi

    echo "[INFO]: cron 自动更新已设置 (间隔: $interval)"
    echo "[INFO]: 脚本: $CRON_SCRIPT"
    echo "[INFO]: 日志: $CRON_LOG"
    echo "[INFO]: 条目: $cron_line"
}

# 函数：移除 cron
cron_remove() {
    if grep -q "$CRON_ID" /etc/crontabs/root 2>/dev/null; then
        sed -i "/$CRON_ID/d" /etc/crontabs/root 2>/dev/null
        echo "[INFO]: cron 自动更新已移除"
    else
        echo "[INFO]: 未找到 cron 自动更新条目"
    fi
    rm -f "$CRON_SCRIPT" 2>/dev/null || true
}

# 函数：显示 cron 状态
cron_status() {
    echo "╔═══════════════════ Cron 自动更新 ═══════════════════╗"
    if grep -q "$CRON_ID" /etc/crontabs/root 2>/dev/null; then
        local entry
        entry=$(grep "$CRON_ID" /etc/crontabs/root)
        echo "  状态: 已启用"
        echo "  条目: $entry"
        echo "  脚本: $CRON_SCRIPT"
        echo "  日志: $CRON_LOG"
        if [ -f "$CRON_LOG" ]; then
            echo "  最近日志:"
            tail -5 "$CRON_LOG" 2>/dev/null | sed 's/^/    /'
        fi
    else
        echo "  状态: 未设置"
    fi
    echo "  说明: cron 会用当前安装模式自动更新 tailecale"
    echo "╚══════════════════════════════════════════════════════╝"
}

# 函数：下载器
downloader() {
    local attempt_range="1 2 3"
    local attempt_timeout=20

    local sha_file="/tmp/$TAILSCALE_FILE.sha256"
    local target_file=""
    local file_path=""

    if [ "$PACKAGE_MANAGER" = "opkg" ]; then
        target_file="$TAILSCALE_FILE.ipk"
        file_path="/tmp/$TAILSCALE_FILE.ipk"
    elif [ "$PACKAGE_MANAGER" = "apk" ]; then
        target_file="$TAILSCALE_FILE.apk"
        file_path="/tmp/$TAILSCALE_FILE.apk"
    fi

    echo "[INFO]: 开始下载tailscale包文件: $target_file"

    for attempt_times in $attempt_range; do
        echo "[INFO]: 下载尝试 $attempt_times/3"
        if ! wget -cO "$file_path" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/$target_file"; then
            if [ "$attempt_times" == "3" ]; then
                echo "[ERROR]: $target_file 三次下载均失败，可能原因：网络连接异常或代理不可用"
                echo "[ERROR]: 即将重启脚本，请检查网络连接后重试"
                sleep 3
                init
            fi
            echo "[INFO]: 下载失败，准备重试..."
            continue
        fi

        echo "[INFO]: 下载校验文件..."
        if [ "$PACKAGE_MANAGER" = "opkg" ]; then
            wget -cO "$sha_file" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/ipk.sha256"
        elif [ "$PACKAGE_MANAGER" = "apk" ]; then
            wget -cO "$sha_file" --timeout="$attempt_timeout" "${AVAILABLE_URL_HEAD}/${DEVICE_TARGET}/apk.sha256"
        fi

        printf "$(cat "$sha_file" | tr -d '\n\r')" > "$sha_file"
        printf "  $file_path\n" >> "$sha_file"

        echo "[INFO]: 验证文件完整性..."
        if [ ! -s "$sha_file" ] || ! sha256sum -c "$sha_file" >/dev/null 2>&1; then
            if [ "$attempt_times" == "3" ]; then
                echo "[ERROR]: tailscale 文件三次下载均失败，可能原因：文件损坏或网络不稳定"
                echo "[ERROR]: 即将重启脚本，请重试"
                sleep 3
                rm -f "$file_path" "$sha_file"
                init
            else
                echo "[INFO]: tailscale 文件校验不通过，正在尝试重新下载..."
                rm -f "$file_path" "$sha_file"
                sleep 3
            fi
        else
            echo "[INFO]: tailscale 文件校验通过!"
            rm -f "$sha_file"
            break
        fi
    done
}

# 函数：tailscale服务停止器
tailscale_stoper() {
    echo ""
    echo "[INFO]: 停止tailscale服务..."
    if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ]; then
        echo "[INFO]: 检测到临时安装模式"
        /etc/init.d/tailscale stop
        echo "[INFO]: 执行tailscale down..."
        /tmp/tailscale down --accept-risk=lose-ssh
        echo "[INFO]: 执行tailscale logout..."
        /tmp/tailscale logout
        echo "[INFO]: 禁用tailscale开机启动..."
        /etc/init.d/tailscale disable
    elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
        echo "[INFO]: 检测到持久安装模式"
        /etc/init.d/tailscale stop
        echo "[INFO]: 执行tailscale down..."
        /usr/sbin/tailscale down --accept-risk=lose-ssh
        echo "[INFO]: 执行tailscale logout..."
        /usr/sbin/tailscale logout
        echo "[INFO]: 禁用tailscale开机启动..."
        /etc/init.d/tailscale disable
    elif [ "$TAILSCALE_INSTALL_STATUS" = "binary" ]; then
        echo "[INFO]: 检测到二进制安装模式"
        /etc/init.d/tailscale stop 2>/dev/null || true
        echo "[INFO]: 执行tailscale down..."
        /usr/sbin/tailscale down --accept-risk=lose-ssh 2>/dev/null || true
        echo "[INFO]: 执行tailscale logout..."
        /usr/sbin/tailscale logout 2>/dev/null || true
        echo "[INFO]: 禁用tailscale开机启动..."
        /etc/init.d/tailscale disable 2>/dev/null || true
    fi
    echo "[INFO]: tailscale服务停止完成"
    echo ""
}

# 函数：初始化
init() {
    local show_init_progress_bar=$1
    local change_dns=$2

    local functions="check_package_manager check_device_target check_tailscale_install_status check_device_memory check_device_storage test_proxy get_tailscale_info"
    local function_count=7
    local total=$function_count
    local progress=0

    if [ "$show_init_progress_bar" != "false" ]; then

        if [ "$change_dns" != "false" ]; then
            #询问是否更改DNS
            read -n 1 -p "[WARNING]: 是否将系统DNS更改为(223.5.5.5,119.29.29.29)以提高解析速度? (y/N): " dns_choice
            if [ "$dns_choice" = "Y" ] || [ "$dns_choice" = "y" ]; then
                echo ""
                set_system_dns
                echo "[INFO]: 系统DNS已更改"
            fi
        fi

        echo ""

        printf "\r[INFO]初始化中: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"

        for function in $functions; do
            eval "$function"
            progress=$((progress + 1))
            percent=$((progress * 100 / function_count))
            bars=$((percent / 2))
            printf "\r[INFO]初始化中: [%-50s] %3d%%" "$(printf '=%.0s' $(seq 1 "$bars"))" "$percent"
        done

        printf "\r[INFO]  完成  : [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$bars"))" "$percent"
    else
        for function in $functions; do
            eval "$function"
        done
    fi
    echo ""
}

# 函数：退出
script_exit() {
    echo ""
    echo "┌─ THANKS!!!感谢您的信任与使用!!!"
    echo "│"
    echo "│ 如果该脚本对您有帮助, 您可以点一颗Star支持我!"
    echo "│ "$REPO_URL"/"
    echo "│ 安装后产生无法使用等情况, 您可以于:"
    echo "│ "$REPO_URL"/issues"
    echo "│ 提出反馈. 谢谢您的使用! /<3"
    echo "└─"
    exit 0
}


# 函数：显示基本信息
show_info() {
    echo "╔═════════════════════ 基 本 信 息 ═════════════════════╗"

    echo "   设备信息："
    echo "     - 当前设备TARGET：[${DEVICE_TARGET}]"
    echo "     - 可用 / 所有 存储空间：($DEVICE_STORAGE_AVAILABLE / $DEVICE_STORAGE_TOTAL) M"
    echo "     - 可用 / 所有 内存：($DEVICE_MEM_FREE / $DEVICE_MEM_TOTAL) M"
    echo "   "

    echo "   本地Tailscale信息："
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        echo "     - 安装状态: 已安装"
        if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ]; then
            echo "     - 安装模式: 临时安装"
            echo "     - 二进制路径: /tmp"
        elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
            echo "     - 安装模式: 持久安装"
            echo "     - 二进制路径: /usr/sbin"
        elif [ "$TAILSCALE_INSTALL_STATUS" = "binary" ]; then
            local binary_info_path="/usr/sbin"
            if [ -f "$TAILSCALE_MODE_MARKER" ]; then
                binary_info_path=$(cat "$TAILSCALE_MODE_MARKER" 2>/dev/null | cut -d':' -f2)
            fi
            echo "     - 安装模式: 二进制安装"
            echo "     - 二进制路径: ${binary_info_path}"
        fi
        echo "     - 版本: $TAILSCALE_LOCAL_VERSION"
    elif [ "$TAILSCALE_INSTALL_STATUS" = "unknown" ]; then
        echo "     - 安装状态: 异常"
        echo "     - 安装模式: 未知(存在tailscale文件, 但tailscale运行异常)"
        echo "     - 版本: 未知"
    else
        echo "     - 安装状态: 未安装"
        echo "     - 安装模式: 未安装"
        echo "     - 版本: 未安装"

    fi

    echo "   "
    echo "   最新Tailscale信息："
    echo "     - 版本: $TAILSCALE_LATEST_VERSION"
    echo "     - 文件大小: $TAILSCALE_FILE_SIZE M"
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        if [ "$TAILSCALE_LATEST_VERSION" != "$TAILSCALE_LOCAL_VERSION" ]; then
            echo "     - 有新版本可用, 您可以选择更新"
        else
            echo "     - 已是最新版本"
        fi
    fi

    echo "   "
    echo "   提示："
    if [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
        echo "     - 持久安装：可用"
    else
        echo "     - 持久安装：不可用"
    fi
    if [ "$TAILSCALE_TEMP_INSTALLABLE" = "true" ]; then
        echo "     - 临时安装：可用"
    else
        echo "     - 临时安装：不可用"
    fi
    if [ "$TAILSCALE_BINARY_INSTALLABLE" = "true" ] || [ -n "$PACKAGE_MANAGER" ]; then
        echo "     - 二进制安装：可用"
    else
        echo "     - 二进制安装：可用(需手动安装依赖)"
    fi
    if [ "$DEVICE_MEM_FREE" -lt 60 ]; then
        echo "     - 设备可用运行内存过低, Tailscale将：可能无法正常运行"
    elif [ "$DEVICE_MEM_FREE" -lt 120 ]; then
        echo "     - 设备可用运行内存较低, Tailscale将：可能运行卡顿"
    fi

    echo "   "
    echo "   代理："
    if [ "$USE_CUSTOM_PROXY" = "true" ]; then
        echo "     - GitHub代理: $AVAILABLE_URL_HEAD (自定义)"
    else
        echo "     - GitHub代理: $AVAILABLE_URL_HEAD (默认)"
    fi

    echo "╚═════════════════════ 基 本 信 息 ═════════════════════╝"
}


# Cron 菜单快捷函数
cron_setup_6h() {
    cron_setup "360"
}
cron_setup_daily() {
    cron_setup "daily"
}


option_menu() {
    # 显示菜单并获取用户输入
    while true; do
        local menu_items=""
        local menu_operations=""
        local option_index=1

        menu_items="$option_index).显示基本信息"
        menu_operations="show_info"
        option_index=$((option_index + 1))

        if [ "$IS_TAILSCALE_INSTALLED" = "true" ] && [ "$TAILSCALE_LATEST_VERSION" != "$TAILSCALE_LOCAL_VERSION" ]; then
            menu_items="$menu_items $option_index).更新"
            menu_operations="$menu_operations update"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
            menu_items="$menu_items $option_index).卸载"
            menu_operations="$menu_operations remove"
            option_index=$((option_index + 1))
        fi

        if [ "$FOUND_TAILSCALE_FILE" = "true" ] && [ "$IS_TAILSCALE_INSTALLED" = "unknown" ]; then
            menu_items="$menu_items $option_index).删除残留文件(已找到tailscale文件但tailscale运行异常)"
            menu_operations="$menu_operations remove_unknown_file"
            option_index=$((option_index + 1))
        fi

        if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ] && [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
            menu_items="$menu_items $option_index).切换至持久安装"
            menu_operations="$menu_operations temp_to_persistent"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "false" ] && [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
            menu_items="$menu_items $option_index).持久安装"
            menu_operations="$menu_operations persistent_install"
            option_index=$((option_index + 1))
        fi

        if [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
            menu_items="$menu_items $option_index).切换至临时安装"
            menu_operations="$menu_operations persistent_to_temp"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "false" ]; then
            menu_items="$menu_items $option_index).临时安装"
            menu_operations="$menu_operations temp_install"
            option_index=$((option_index + 1))
        fi

        # 二进制安装选项
        if [ "$TAILSCALE_INSTALL_STATUS" = "temp" ] || [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
            menu_items="$menu_items $option_index).切换至二进制安装"
            menu_operations="$menu_operations ${TAILSCALE_INSTALL_STATUS}_to_binary"
            option_index=$((option_index + 1))
        fi

        if [ "$IS_TAILSCALE_INSTALLED" = "false" ]; then
            menu_items="$menu_items $option_index).二进制安装"
            menu_operations="$menu_operations binary_install"
            option_index=$((option_index + 1))
        fi

        if [ "$TAILSCALE_INSTALL_STATUS" = "binary" ]; then
            if [ "$TAILSCALE_PERSISTENT_INSTALLABLE" = "true" ]; then
                menu_items="$menu_items $option_index).切换至持久安装"
                menu_operations="$menu_operations binary_to_persistent"
                option_index=$((option_index + 1))
            fi
            menu_items="$menu_items $option_index).切换至临时安装"
            menu_operations="$menu_operations binary_to_temp"
            option_index=$((option_index + 1))
        fi

        # Cron 自动更新选项
        if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
            if grep -q "$CRON_ID" /etc/crontabs/root 2>/dev/null; then
                menu_items="$menu_items $option_index).查看Cron状态"
                menu_operations="$menu_operations cron_status"
                option_index=$((option_index + 1))
                menu_items="$menu_items $option_index).移除Cron自动更新"
                menu_operations="$menu_operations cron_remove"
                option_index=$((option_index + 1))
            else
                menu_items="$menu_items $option_index).设置Cron自动更新(每6小时)"
                menu_operations="$menu_operations cron_setup_6h"
                option_index=$((option_index + 1))
                menu_items="$menu_items $option_index).设置Cron自动更新(每天)"
                menu_operations="$menu_operations cron_setup_daily"
                option_index=$((option_index + 1))
            fi
        fi
        if [ "$IS_TAILSCALE_INSTALLED" != "true" ] || ! grep -q "$CRON_ID" /etc/crontabs/root 2>/dev/null; then
            :
        fi

        menu_items="$menu_items $option_index).退出"
        menu_operations="$menu_operations exit"

        echo ""
        echo "┌──────────────────────── 菜 单 ────────────────────────┐"

        # 遍历选项列表，动态生成菜单
        for item in $menu_items; do
            echo "│       $item"
        done
        echo ""

        read -n 1 -p "│ 请输入选项(0 ~ $option_index): " choice
        echo ""
        echo ""

        # 判断输入是否合法
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
            echo "[WARNING]: 无效选项，请重试！"
            echo ""
            break
        fi
    done
}

show_help() {
    echo "Tailscale on OpenWrt installer script. $SCRIPT_VERSION"
    echo "  Repo: $REPO_URL"
    echo ""
    echo "  Usage:   $0 [options]"
    echo ""
    echo "  Options:"
    echo "      --help                    Show this help"
    echo "      --yes                     Skip all confirmation prompts"
    echo ""
    echo "  Install modes (mutually exclusive, pick one):"
    echo "      --persistent-install      Install via opkg/apk package manager"
    echo "      --temp-install            Install to /tmp (volatile)"
    echo "      --bin-install [path]      Install as binary directly (optional path)"
    echo "      --mode persistent|temp|binary [path]"
    echo "                                Unified mode selector"
    echo ""
    echo "  Install options:"
    echo "      --install-path <path>     Custom install path for binary mode"
    echo "      --custom-proxy            Use a custom GitHub proxy"
    echo ""
    echo "  Other actions:"
    echo "      --uninstall               Uninstall tailscale (use with --yes)"
    echo "      --update                  Update tailscale (use with --yes)"
    echo "      --cron-setup [interval]   Setup auto-update cron (daily/weekly/monthly/hours/Nmin)"
    echo "      --cron-remove             Remove auto-update cron"
    echo "      --cron-check              Check for update and install (called by cron)"
    echo ""
    echo "  Examples:"
    echo "      $0 --bin-install                          # Binary mode, default path"
    echo "      $0 --bin-install /mnt/usb                  # Binary mode, USB path"
    echo "      $0 --mode binary /mnt/usb --yes            # Same, no confirmations"
    echo "      $0 --persistent-install --yes               # Silent persistent install"
    echo "      $0 --uninstall --yes                        # Silent uninstall"
    echo "      $0 --temp-install                           # Temp install"
    echo "      $0 --cron-setup daily                       # Check daily at 4am"
    echo "      $0 --cron-setup hourly                      # Check every hour"
    echo "      $0 --cron-setup 30                          # Check every 30 minutes"
    echo "      $0 --cron-remove                            # Remove cron job"
}


# 读取参数
BIN_INSTALL="false"
PERSISTENT_INSTALL="false"
UPDATE_MODE="false"
UNINSTALL_MODE="false"
CRON_CHECK="false"
CRON_SETUP="false"
CRON_REMOVE="false"
CRON_SETUP_INTERVAL="daily"
prev_arg=""
for arg in "$@"; do
    case $arg in
    --help)
        show_help
        exit 0
        ;;
    --yes|-y)
        YES_MODE="true"
        ;;
    --tempinstall|--temp-install)
        TMP_INSTALL="true"
        ;;
    --persistent-install)
        PERSISTENT_INSTALL="true"
        ;;
    --bin-install)
        BIN_INSTALL="true"
        ;;
    --install-path)
        # 此参数在后续循环中处理
        ;;
    --mode)
        # 此参数在后续循环中处理
        ;;
    --uninstall)
        UNINSTALL_MODE="true"
        ;;
    --update)
        UPDATE_MODE="true"
        ;;
    --cron-check)
        CRON_CHECK="true"
        ;;
    --cron-setup)
        CRON_SETUP="true"
        ;;
    --cron-remove)
        CRON_REMOVE="true"
        ;;
    --custom-proxy)
        while true; do
            echo "╔═══════════════════════════════════════════════════════╗"
            echo "║ [WARNING]!!!请您确认以下信息:                         ║"
            echo "║                                                       ║"
            echo "║ 您正在自定义GitHub代理, 请您确保您的代理有效, 否则脚  ║"
            echo "║ 本将无法正常运行, 确保格式如下:                       ║"
            echo "║ https://example.com                                   ║"
            echo "║                                                       ║"
            echo "║ 如果您有可用代理, 您可以提出issues, 我会将该代理加入  ║"
            echo "║ 脚本, 这将帮助大家, 谢谢!!!                           ║"
            echo "║ "$REPO_URL"/issues  ║"
            echo "║                                                       ║"
            echo "╚═══════════════════════════════════════════════════════╝"
            read -p "请输入您想要使用的代理并按回车: " custom_proxy
            while true; do
                echo "[INFO]: 您自定义的代理是: $custom_proxy"
                read -n 1 -p "您确定使用该代理吗? (y/N): " choise
                if [ "$choise" == "y" ] || [ "$choise" == "Y" ]; then
                    USE_CUSTOM_PROXY="true"
                    PROXYS="$custom_proxy/${URL_HEAD}"
                    break 2
                else
                    break
                fi
            done
        done
        ;;
    *)
        # 检查是否为 --install-path / --mode 或 --bin-install 的参数值
        if [ "$prev_arg" = "--install-path" ]; then
            CUSTOM_INSTALL_PATH="$arg"
            BINARY_INSTALL_PATH="$arg"
        elif [ "$prev_arg" = "--mode" ]; then
            # --mode persistent|temp|binary [path]
            case "$arg" in
                persistent) PERSISTENT_INSTALL="true" ;;
                temp|tmp)   TMP_INSTALL="true" ;;
                binary)     BIN_INSTALL="true" ;;
                *)
                    echo "[ERROR]: Invalid mode '$arg'. Use: persistent, temp, or binary"
                    exit 1
                    ;;
            esac
            # 下一个参数可能是路径
            next_is_path=true
        elif [ "$prev_arg" = "--bin-install" ]; then
            # --bin-install 可接受可选路径参数
            CUSTOM_INSTALL_PATH="$arg"
            BINARY_INSTALL_PATH="$arg"
            BIN_INSTALL="true"
        elif [ "$prev_arg" = "--mode" ] || [ "$next_is_path" = "true" ]; then
            # --mode persistent/temp/binary 后的可选路径
            if [ -n "$arg" ] && ! echo "$arg" | grep -q "^-"; then
                CUSTOM_INSTALL_PATH="$arg"
                BINARY_INSTALL_PATH="$arg"
            fi
            next_is_path=false
        elif [ "$prev_arg" = "--cron-setup" ]; then
            CRON_SETUP_INTERVAL="$arg"
        else
            echo "[ERROR]: Unknown argument: $arg"
            show_help
            exit 1
        fi
        ;;
    esac
    prev_arg="$arg"
done

# 主程序

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
    check_package_manager
    check_device_target
    test_proxy
    get_tailscale_info
    temp_install "" "true"
    exit 0
fi

if [ "$PERSISTENT_INSTALL" = "true" ]; then
    check_package_manager
    check_device_target
    test_proxy
    get_tailscale_info
    persistent_install "" "true"
    exit 0
fi

if [ "$BIN_INSTALL" = "true" ]; then
    check_package_manager
    check_device_target
    test_proxy
    get_tailscale_info
    binary_install "" "true"
    exit 0
fi

if [ "$UPDATE_MODE" = "true" ]; then
    check_package_manager
    check_device_target
    check_tailscale_install_status
    test_proxy
    get_tailscale_info
    update
    exit 0
fi

if [ "$UNINSTALL_MODE" = "true" ]; then
    check_package_manager
    check_device_target
    check_tailscale_install_status
    if [ "$IS_TAILSCALE_INSTALLED" = "true" ]; then
        remove
    else
        echo "[INFO]: Tailscale 未安装, 无需卸载"
    fi
    exit 0
fi

if [ "$CRON_CHECK" = "true" ]; then
    check_package_manager
    check_device_target
    check_tailscale_install_status
    test_proxy
    get_tailscale_info
    cron_check_update
    exit 0
fi

if [ "$CRON_SETUP" = "true" ]; then
    cron_setup "$CRON_SETUP_INTERVAL"
    exit 0
fi

if [ "$CRON_REMOVE" = "true" ]; then
    cron_remove
    exit 0
fi

main
