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
        echo "[ERROR]: 未找到支持的包管理器，脚本退出。"
        exit 1
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
        # 持久化场景：usr/sbin 下有文件
        TAILSCALE_INSTALL_STATUS="persistent"
        IS_TAILSCALE_INSTALLED="true"
    else
        IS_TAILSCALE_INSTALLED="false"
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

            # remove指定目录的 tailscale 或 tailscaled 文件
            local directories="/etc/init.d /etc /etc/config /usr/bin /usr/sbin /tmp /var/lib"
            local binaries="tailscale tailscaled"

            echo "[INFO]: 清理tailscale相关文件..."
            # remove指定目录的 tailscale 或 tailscaled 文件
            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        echo "[INFO]: 删除文件: $dir/$bin"
                        rm -rf $dir/$bin
                        echo "[INFO]: 已删除文件: $dir/$bin"
                    fi
                done
            done

            echo "[INFO]: 删除tailscale虚拟网卡..."
            ip link delete tailscale0
            echo "[INFO]: tailscale卸载完成"
            script_exit
        else
            echo "[INFO]: 取消卸载"
            break
        fi
    done
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
        elif [ "$TAILSCALE_INSTALL_STATUS" = "persistent" ]; then
            echo "     - 安装模式: 持久安装"
        fi
        echo "     - 版本: $TAILSCALE_LOCAL_VERSION"
    elif [ "$IS_TAILSCALE_INSTALLED" = "unknown" ]; then
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
    echo "  Usage:   "
    echo "      --help: Show this help"
    echo "      --custom-proxy: Custom github proxy"

}


# 读取参数
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
        echo "[ERROR]: Unknown argument: $arg"
        show_help
        ;;
    esac
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

main