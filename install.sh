#!/bin/sh

# 脚本信息
SCRIPT_VERSION="v1.08"
SCRIPT_DATE="2025/12/15"

# 基本配置
OPENWRT_TAILSCALE_REPO_URL="https://github.com/GuNanOvO/openwrt-tailscale"
OPENWRT_TAILSCALE_REPO="gunanovo/openwrt-tailscale"

# TAILSCALE 文件 URL
TAILSCALE_URL="${OPENWRT_TAILSCALE_REPO}/releases/latest"
# tailscale 文件 URL头
URL_PROXYS="https://ghfast.top/https://github.com
https://cf.ghproxy.cc/https://github.com
https://www.ghproxy.cc/https://github.com
https://gh-proxy.com/https://github.com
https://ghproxy.cc/https://github.com
https://ghproxy.cn/https://github.com
https://www.ghproxy.cn/https://github.com
https://github.com"
# init.d/tailscale 文件 URL
INIT_URL="/${OPENWRT_TAILSCALE_REPO}/blob/main/etc/init.d/tailscale"
# OpenWrt 可写存储分区，通常是 /overlay
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
# 使用自定义代理
USE_CUSTOM_PROXY="false"

# 最新tailscale版本
tailscale_latest_version=""

# tailscale是否已安装
is_tailscale_installed=false
# tailscale的安装状态（持久安装/临时安装）
tailscale_install_status="none"
# 是否查找到任何tailscale文件
found_tailscale_file=false
# tailscale版本号
tailscale_version=""

# 设备总运行内存
total_mem=""
# 设备可用运行内存
free_mem=""
# 剩余空间大小bytes
free_space=""
# 文件大小bytes
file_size=""
# 剩余空间大小mb
free_space_mb=""
# 文件大小mb
file_size_mb=""
# tailscale是否可以被永久安装，即存储空间是否足够安装
tailscale_persistent_installable=""

show_init_progress_bar="true"

# 函数：脚本信息
script_info() {
    echo "#╔╦╗┌─┐ ┬ ┬  ┌─┐┌─┐┌─┐┬  ┌─┐  ┌─┐┌┐┌  ╔═╗┌─┐┌─┐┌┐┌ ╦ ╦ ┬─┐┌┬┐  ╦ ┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐#"
    echo "# ║ ├─┤ │ │  └─┐│  ├─┤│  ├┤   │ ││││  ║ ║├─┘├┤ │││ ║║║ ├┬┘ │   ║ │││└─┐ │ ├─┤│  │  ├┤ ├┬┘#"
    echo "# ╩ ┴ ┴ ┴ ┴─┘└─┘└─┘┴ ┴┴─┘└─┘  └─┘┘└┘  ╚═╝┴  └─┘┘└┘ ╚╩╝ ┴└─ ┴   ╩ ┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─#"
    echo "┌────────────────────────────────────────────────────────────────────────────────────────┐"
    echo "│ 一个用于在OpenWrt上安装Tailscale或更新Tailscale或...的一个脚本。                       │"
    echo "│ 项目地址: "$OPENWRT_TAILSCALE_REPO_URL"                                │"
    echo "│ 脚本版本: "$SCRIPT_VERSION"                                                                        │"
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

# 函数：获取系统架构
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
            echo "   当前设备的架构是: [${arch_}${endianness}]              "
            echo "   脚本暂不支持您的设备                                 "
            echo "                                                        "
            echo "╚═══════════════════════════════════════════════════════╝"

            exit 1
            ;;
    esac
}

# 函数：检测是否已经安装过tailscale
check_tailscale_install_status() {
    # 检查 tailscale version 是否有输出并提取版本号
    if command -v tailscale >/dev/null 2>&1; then
        version_output=$(tailscale version 2>/dev/null)
        if [ -n "$version_output" ]; then
            # 从输出中提取版本号
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

# 函数：检查剩余存储空间（单位：bytes）
get_free_space() {
    # 检查 MOUNT_POINT 是否定义
    if [ -z "$MOUNT_POINT" ]; then
        echo "错误: MOUNT_POINT 未定义"
        exit 1
    fi

    # 使用 df -k 获取以 KB（1024 字节）为单位的剩余空间
    free_space_kb=$(df -Pk "$MOUNT_POINT" | awk 'NR==2 {print $(NF-2)}')
    
    #获取设备总运行内存
    total_mem=$(expr $(free | grep Mem | awk '{print $2}') / 1024)
    #获取设备可用运行内存
    free_mem=$(expr $(free | grep Mem | awk '{print $7}') / 1024)

    # 检查输出是否有效
    if [ -z "$free_space_kb" ] || ! echo "$free_space_kb" | grep -q '^[0-9]\+$'; then
        echo "错误: 无法获取 $MOUNT_POINT 的剩余空间"
        exit 1
    fi

    # 将 KB 转换为 bytes（1KB = 1024 bytes）
    free_space=$((free_space_kb * 1024))
    free_space_mb=$(expr $free_space / 1024 / 1024)
}

# 函数：获取 GitHub 文件大小（单位：bytes）
get_tailscale_info() {
    # 先简单wget一下releases的版本，以此确定可用的代理头
    # 尝试3次
    attempt_range="1 2 3"
    # 超时时间（秒）
    attempt_timeout=10
    
    if [ "$NO_TINY" == "true" ]; then
        TAILSCALE_FILE="tailscaled-linux-${arch}-normal"
    else
        TAILSCALE_FILE="tailscaled-linux-${arch}"
    fi

    if [ "$USE_CUSTOM_PROXY" == "true" ]; then

        attempt_url="$available_proxy/$TAILSCALE_URL/download/build-info.txt"
        tailscale_latest_version=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "Version: " | awk '{print $2}')
        file_size=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "$TAILSCALE_FILE " | awk '{print $2}')

        if [ -z "$tailscale_latest_version" ] && [ -z "$file_size" ]; then
            echo ""
            echo "您的自定义代理不可用, 脚本退出..."
            exit 1
        fi

    else
        for attempt_times in $attempt_range; do
            for attempt_proxy in $URL_PROXYS; do
                attempt_url="$attempt_proxy/$TAILSCALE_URL/download/build-info.txt"
                tailscale_latest_version=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "Version: " | awk '{print $2}')
                file_size=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | grep "$TAILSCALE_FILE " | awk '{print $2}')

                if [ -n "$tailscale_latest_version" ] && [ -n "$file_size" ]; then
                    available_proxy="$attempt_proxy"
                    break 2
                fi

            done
        done
    fi
    
    if [ -z "$file_size" ] || ! [[ "$file_size" =~ ^[0-9]+$ ]]; then
        echo "错误: 无法获取tailscale大小"
        echo "1. 确保网络连接正常"
        echo "2. 重试"
        echo "3. 报告开发者"
        exit 1
    else
        # 比较并判断是否可以持久安装tailscale
        if [ "$free_space" -gt "$file_size" ]; then
            tailscale_persistent_installable=true
        else
            tailscale_persistent_installable=false
        fi
    fi

    file_size_mb=$(expr $file_size / 1024 / 1024)
}

# 函数：更新
update() {
    echo "正在更新..."
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
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 您正在执行更新Tailscale, Tailscale需要重启, 如果您当 ║"
        echo "║ 当前正在通过Tailscale连接至设备有可能断开与设备的连接 ║"
        echo "║ 请您确认您的操作, 避免造成失! 感谢您的使用!         ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        read -n 1 -p "确认重启tailscale吗? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            /etc/init.d/tailscale stop
            /etc/init.d/tailscale start
            break
        else
            echo "取消重启tailscale, 您稍后可自行通过命令 /etc/init.d/tailscale stop && /etc/init.d/tailscale start 来重启tailscale服务"
            break
        fi
    done
}

# 函数：卸载
remove() { 
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 您正在执行卸载Tailscale, 卸载后,您所有依托于Tailscale ║"
        echo "║ 的服务都将失效, 如果您当前正在通过Tailscale连接至设备 ║"
        echo "║ 则有可能断开与设备的连接, 请您确认您的操作, 避免造成  ║"
        echo "║ 损失! 感谢您的使用!                                   ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        read -n 1 -p "确认卸载tailscale吗? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            # remove指定目录的 tailscale 或 tailscaled 文件
            directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
            binaries="tailscale tailscaled"

            # remove指定目录的 tailscale 或 tailscaled 文件
            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        rm -rf $dir/$bin
                        echo "已删除文件: $dir/$bin"
                    fi
                done
            done

            ip link delete tailscale0
            script_exit
            break
        else
            echo "取消卸载"
            break
        fi
    done
}

# 函数：清理未知文件
remove_unknown_file() {
    while true; do
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 您正在执行删除Tailscale残留文件,如果这些文件为您自行  ║"
        echo "║ 创建,则不应该被删除,请您取消该操作!                   ║"
        echo "║ 请您确认您的操作, 避免造成损失!                       ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"

        # remove指定目录的 tailscale 或 tailscaled 文件
        directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
        binaries="tailscale tailscaled"

        # 使用 for 循环遍历目录和文件
        for dir in $directories; do
            for bin in $binaries; do
                if [ -f "$dir/$bin" ]; then
                    echo "找到文件: $dir/$bin"
                fi
            done
        done

        read -n 1 -p "确认删除残留文件吗? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            # remove指定目录的 tailscale 或 tailscaled 文件
            directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
            binaries="tailscale tailscaled"

            # 使用 for 循环遍历目录和文件
            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        rm -rf $dir/$bin
                        echo "已删除文件: $dir/$bin"
                    fi
                done
            done

            ip link delete tailscale0
            
            echo "已删除所有残留文件, 重启脚本..."
            sleep 2
            exec "$0" "$@"

            break
        else
            echo "取消删除残留文件"
            break
        fi
    done
}


# 函数：持久安装
persistent_install() {
    confirm2persistent_install=$1
    if [ "$confirm2persistent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 使用持久安装时, 请您确认您的openwrt的剩余空间至少大于 ║"
        echo "║ "$file_size_mb", 推荐大于$(expr $file_size_mb \* 3)M.                                       ║"
        echo "║ 安装时产生任何错误, 您可以于:                         ║"
        echo "║ "$OPENWRT_TAILSCALE_REPO_URL"/issues  ║"
        echo "║ 提出反馈. 谢谢您的使用! /<3                           ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "确认采用持久安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            return
        fi
    fi 
    echo ""
    echo "正在持久安装..."
    downloader
    mv -f /tmp/tailscaled /usr/bin
    ln -sv /usr/bin/tailscaled /usr/bin/tailscale
    echo "持久安装完成!"
    tailscale_starter
    echo "正在重新初始化脚本, 请稍候..."
    init "" "false"

}

# 函数：临时安装切换到持久安装
temp_to_persistent() {
    confirm2persistent_install=$1
    if [ "$confirm2persistent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 使用持久安装时, 请您确认您的openwrt的剩余空间至少大于 ║"
        echo "║ "$file_size_mb", 推荐大于$(expr $file_size_mb \* 3)M.                                       ║"
        echo "║ 安装时产生任何错误, 您可以于:                         ║"
        echo "║ "$OPENWRT_TAILSCALE_REPO_URL"/issues  ║"
        echo "║ 提出反馈. 谢谢您的使用! /<3                           ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "确认采用持久安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            return
        fi
    fi
    echo ""
    echo "正在持久安装..."
    tailscale_stoper
    rm -rf /tmp/tailscale
    rm -rf /tmp/tailscaled
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    persistent_install "true"
}

# 函数：临时安装
temp_install() { 
    confirm2temp_install=$1
    if [ "$confirm2temp_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 临时安装是将tailscale文件置于/tmp目录, /tmp目录会在重 ║"
        echo "║ 启设备后清空. 如果该脚本在重启后重新下载tailscale失败 ║"
        echo "║ 则tailscale将无法正常使用, 您所有依托于tailscale的服  ║"
        echo "║ 务都将失效, 请您明悉并确定该讯息, 以免造成损失. 谢谢! ║"
        echo "║ 如果可以持久安装，推荐您采取持久安装方式!             ║"
        echo "║ 安装时产生任何错误, 您可以于:                         ║"
        echo "║ "$OPENWRT_TAILSCALE_REPO_URL"/issues  ║"
        echo "║ 提出反馈. 谢谢您的使用! /<3                           ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "确认采用临时安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            return
        fi
    fi
    echo ""
    echo "正在临时安装..." 
    downloader
    ln -sv /tmp/tailscaled /tmp/tailscale
    if [ "$NO_TINY" == "true" ]; then
        echo "$TMP_TAILSCALE" > /usr/bin/tailscale
        echo "$TMP_NORMAL_TAILSCALED" > /usr/bin/tailscaled
    else
        echo "$TMP_TAILSCALE" > /usr/bin/tailscale
        echo "$TMP_TAILSCALED" > /usr/bin/tailscaled
    fi
    echo "临时安装完成!"
    tailscale_starter
    echo "正在重新初始化脚本, 请稍候..."
    init "" "false"
}

# 函数：持久安装切换到临时安装
persistent_to_temp() {
    confirm2temp_install=$1
    if [ "$confirm2temp_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!!请您确认以下信息:                           ║"
        echo "║                                                       ║"
        echo "║ 临时安装是将tailscale文件置于/tmp目录, /tmp目录会在重 ║"
        echo "║ 启设备后清空. 如果该脚本在重启后重新下载tailscale失败 ║"
        echo "║ 则tailscale将无法正常使用, 您所有依托于tailscale的服  ║"
        echo "║ 务都将失效, 请您明悉并确定该讯息, 以免造成损失. 谢谢! ║"
        echo "║ 如果可以持久安装，推荐您采取持久安装方式!             ║"
        echo "║ 安装时产生任何错误, 您可以于:                         ║"
        echo "║ "$OPENWRT_TAILSCALE_REPO_URL"/issues  ║"
        echo "║ 提出反馈. 谢谢您的使用! /<3                           ║"
        echo "║                                                       ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "确认采用临时安装方式安装tailscale吗? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            return
        fi

    fi 
    echo ""
    echo "正在切换到临时安装..."
    tailscale_stoper
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    temp_install "true"
}

# 函数：下载器
downloader() {
    # 尝试3次
    attempt_range="1 2 3"
    # 超时时间（秒）
    attempt_timeout=20
    for attempt_times in $attempt_range; do
        wget -cO "/tmp/$TAILSCALE_FILE" "$available_proxy/$TAILSCALE_URL/download/$TAILSCALE_FILE"
        wget -cO /tmp/checksums.txt "$available_proxy/$TAILSCALE_URL/download/checksums.txt"
        grep -E "  ${TAILSCALE_FILE}\$" /tmp/checksums.txt > "/tmp/$TAILSCALE_FILE.sha256"
        if ! sha256sum -c "/tmp/$TAILSCALE_FILE.sha256"; then
            if [ "$attempt_times" == "3" ]; then
                echo "tailscale 文件三次下载均失败, 即将重启脚本, 请重试!"
                exit
            else
                echo "tailscale 文件校验不通过, 正在尝试重新下载!"
            fi
        else
            echo "tailscale 文件校验通过!"
            mv "/tmp/$TAILSCALE_FILE" "/tmp/tailscaled"
            break
        fi
    done

    wget -cO /etc/init.d/tailscale "$available_proxy/$INIT_URL"
}

# 函数：tailscale服务启动器
tailscale_starter() {
    echo ""
    echo "正在启动tailscale服务..."
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
    if [ "$TMP_INSTALL" == "true" ]; then
        tailscale up
    fi
    echo "tailscale服务启动完成"
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║ Tailscale安装&服务启动完成!!!                         ║"
    echo "║                                                       ║"
    echo "║ 现在您可以按照您希望的方式开始使用!                   ║"
    echo "║ 直接启动: tailscale up                                ║"
    echo "║ 安装后有任何无法使用的问题, 可以于:                   ║"
    echo "║ "$OPENWRT_TAILSCALE_REPO_URL"/issues  ║"
    echo "║ 提出反馈. 谢谢您的使用! /<3                           ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
}

# 函数：tailscale服务停止器
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

# 函数：初始化
init() {
    show_init_progress_bar=$1
    change_dns=$2

    #获取系统架构 #检查是否安装过 #获取磁盘剩余空间 #获取tailscale文件大小
    local functions="get_system_arch check_tailscale_install_status get_free_space get_tailscale_info"
    local function_count=4
    local total=$function_count
    local progress=0
    
    if [ "$show_init_progress_bar" != "false" ]; then

        if [ "$change_dns" != "false" ]; then
            #询问是否更改DNS
            read -n 1 -p "是否将系统DNS更改为(223.5.5.5,119.29.29.29)以提高解析速度? (y/N): " dns_choice 
            if [ "$dns_choice" = "Y" ] || [ "$dns_choice" = "y" ]; then
                echo ""
                set_system_dns
                echo "系统DNS已更改"
            fi
        fi

        echo ""

        # 0%进度条
        printf "\r初始化中: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
        
        for function in $functions; do
            eval "$function"
            progress=$((progress + 1))
            percent=$((progress * 100 / function_count))
            bars=$((percent / 2))
            printf "\r初始化中: [%-50s] %3d%%" "$(printf '=%.0s' $(seq 1 "$bars"))" "$percent"
        done
    
        # 100%进度条
        printf "\r  完成  : [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$bars"))" "$percent"
    else
        for function in $functions; do
            eval "$function"
        done
    fi
    echo ""

}

# 函数：退出
script_exit() {
        echo "┌───────────────────────────────────────────────────────┐"
        echo "│ THANKS!!!感谢您的信任与使用!!!                        │"
        echo "│                                                       │"
        echo "│ 如果该脚本对您有帮助, 您可以点一颗Star支持我!         │"
        echo "│ "$OPENWRT_TAILSCALE_REPO_URL"/        │"
        echo "│ 安装后产生无法使用等情况, 您可以于:                   │"
        echo "│ "$OPENWRT_TAILSCALE_REPO_URL"/issues  │"
        echo "│ 提出反馈. 谢谢您的使用! /<3                           │"
        echo "│                                                       │"
        echo "└───────────────────────────────────────────────────────┘"
        exit 0
}

# 函数：显示基本信息
show_info() {
    echo "╔═════════════════════ 基 本 信 息 ═════════════════════╗"

    echo "   当前设备架构：[${arch}]"
    if [ "$is_tailscale_installed" = "true" ]; then
        echo "   Tailscale安装状态: 已安装"
        if [ "$tailscale_install_status" = "temp" ]; then
            echo "   Tailscale安装模式: 临时安装"
        elif [ "$tailscale_install_status" = "persistent" ]; then
            echo "   Tailscale安装模式: 持久安装"
        fi
        echo "   Tailscale版本: $tailscale_version"
    else 
        if [ "$is_tailscale_installed" = "unknown" ]; then
            echo "   Tailscale安装模式: 未知(存在tailscale文件, 但tailscale运行异常)"
            echo "   Tailscale版本: 未知"
        else
            echo "   Tailscale安装状态: 未安装"
            echo "   Tailscale版本: 未安装"
        fi
    fi

    echo "   Tailscale最新版本: $tailscale_latest_version"
    echo "   Tailscale文件大小: $file_size B / $(expr $file_size / 1024 / 1024) M" 
    echo "   剩余存储空间：$free_space B / $(expr $free_space / 1024 / 1024) M"
    # 比较并判断
    if [ "$free_space" -gt "$file_size" ]; then
        echo "   剩余空间足以持久安装Tailscale"
    else
        echo "   剩余空间不足以持久安装Tailscale"
    fi

    echo "   设备 可用/全部 内存：$free_mem MB / $total_mem MB"
    if [ "$free_mem" -lt 60 ]; then
        echo "   设备运行内存过低, 可能导致tailscale无法正常运行"
    elif [ "$free_mem" -lt 120 ]; then
        echo "   设备运行内存较低, 可能导致tailscale运行卡顿"
    fi

    if [ "$USE_CUSTOM_PROXY" = "true" ]; then
        echo "   GitHub代理: $custom_proxy (自定义)"
    else
        echo "   GitHub代理: $available_proxy"
    fi

    if [ "$is_tailscale_installed" = "true" ]; then
        if [ $tailscale_latest_version != $tailscale_version ]; then
            echo "   Tailscale有新版本可用, 您可以选择更新"
        else
            echo "   Tailscale已是最新版本"
        fi
    fi
    echo "╚═════════════════════ 基 本 信 息 ═════════════════════╝"
}

option_menu() {
    # 显示菜单并获取用户输入
    while true; do
        menu_items=""
        menu_operations=""
        option_index=1

        menu_items="$option_index).显示基本信息"
        menu_operations="show_info"
        option_index=$((option_index + 1))

        if [ "$is_tailscale_installed" = "true" ] && [ $tailscale_latest_version != $tailscale_version ]; then
            menu_items="$menu_items $option_index).更新"
            menu_operations="$menu_operations update"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "true" ]; then
            menu_items="$menu_items $option_index).卸载"
            menu_operations="$menu_operations remove"
            option_index=$((option_index + 1))
        fi

        if [ "$found_tailscale_file" = "true" ] && [ "$is_tailscale_installed" = "unknown" ]; then
            menu_items="$menu_items $option_index).删除残留文件(已找到tailscale文件但tailscale运行异常)"
            menu_operations="$menu_operations remove_unknown_file"
            option_index=$((option_index + 1))
        fi

        if [ "$tailscale_install_status" = "temp" ] && [ "$tailscale_persistent_installable" = "true" ]; then
            menu_items="$menu_items $option_index).切换至持久安装"
            menu_operations="$menu_operations temp_to_persistent"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "false" ] && [ "$tailscale_persistent_installable" = "true" ]; then
            menu_items="$menu_items $option_index).持久安装"
            menu_operations="$menu_operations persistent_install"
            option_index=$((option_index + 1))
        fi

        if [ "$tailscale_install_status" = "persistent" ]; then
            menu_items="$menu_items $option_index).切换至临时安装"
            menu_operations="$menu_operations persistent_to_temp"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "false" ]; then
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
            echo "无效选项，请重试！"
            echo ""
            break
        fi
    done
}

show_help() {
    echo "Tailscale on OpenWrt installer script. $SCRIPT_VERSION"
    echo ""$OPENWRT_TAILSCALE_REPO_URL""
    echo "  Usage:   "
    echo "      --help: Show this help"
    echo "      --notiny: Use uncompressed version "
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
            echo "║ WARNING!!!请您确认以下信息:                           ║"
            echo "║                                                       ║"
            echo "║ 您正在自定义GitHub代理, 请您确保您的代理有效, 否则脚  ║"
            echo "║ 本将无法正常运行, 确保格式如下:                       ║"
            echo "║ https://example.com                                   ║"
            echo "║                                                       ║"
            echo "║ 如果您有可用代理, 您可以提出issues, 我会将该代理加入  ║"
            echo "║ 脚本, 这将帮助大家, 谢谢!!!                           ║"
            echo "║ "$OPENWRT_TAILSCALE_REPO_URL"/issues  ║"
            echo "║                                                       ║"
            echo "╚═══════════════════════════════════════════════════════╝"
            read -p "请输入您想要使用的代理并按回车: " custom_proxy
            while true; do
                echo "您自定义的代理是: $custom_proxy"
                read -n 1 -p "您确定使用该代理吗? (y/N): " choise
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
    set_system_dns
    get_system_arch 
    get_tailscale_info
    update
    exit 0
fi

main