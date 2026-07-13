#!/bin/bash
# ============================================================
# OpenWrt QEMU 启动脚本
# 在 dev container 中启动一个 OpenWrt x86_64 QEMU 虚拟机
#
# 用法:
#   openwrt-qemu start   - 启动 OpenWrt 虚拟机
#   openwrt-qemu stop    - 停止 OpenWrt 虚拟机
#   openwrt-qemu ssh     - SSH 连接 (需先配置一次)
#   openwrt-qemu console - 串口控制台连接
#   openwrt-qemu status  - 查看状态
#   openwrt-qemu setup   - 一键配置 SSH 访问(仅首次)
# ============================================================
set -euo pipefail

# === 配置 ===
FW_BASE="/workspace/tmp/ib/bin/targets/x86/64/openwrt-24.10.4-x86-64-generic-ext4-combined.img"
QCOW2_OVERLAY="/workspace/tmp/ib/bin/targets/x86/64/openwrt-overlay.qcow2"
ISO="/workspace/tmp/qemu_test/scripts.iso"
SSH_PORT=2222
CONSOLE_PORT=4444
QEMU_PIDFILE="/tmp/openwrt-qemu.pid"
SSH_KEY="/home/vscode/.ssh/openwrt_qemu"

# === 函数 ===

# 检查依赖
check_deps() {
    for cmd in qemu-system-x86_64 qemu-img ssh expect; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "ERROR: $cmd not found"
            exit 1
        fi
    done
    if [ ! -f "$FW_BASE" ]; then
        echo "ERROR: Firmware image not found at $FW_BASE"
        exit 1
    fi
}

# 创建 qcow2 overlay (写时复制, 保护原始镜像)
create_overlay() {
    if [ ! -f "$QCOW2_OVERLAY" ]; then
        echo "Creating qcow2 overlay (backed by base image)..."
        qemu-img create -f qcow2 -F raw -b "$FW_BASE" "$QCOW2_OVERLAY" 2>&1
        echo "Overlay created: $QCOW2_OVERLAY"
    else
        echo "Overlay already exists: $QCOW2_OVERLAY"
    fi
}

# 启动 QEMU
start_qemu() {
    if [ -f "$QEMU_PIDFILE" ] && kill -0 "$(cat "$QEMU_PIDFILE")" 2>/dev/null; then
        echo "OpenWrt QEMU is already running (PID: $(cat "$QEMU_PIDFILE"))"
        return 0
    fi

    create_overlay

    echo "Starting OpenWrt QEMU..."
    echo "  SSH port:  $SSH_PORT (host:${SSH_PORT} -> guest:22)"
    echo "  Console:   telnet 127.0.0.1 $CONSOLE_PORT"
    echo ""

    # Start QEMU with:
    # - qcow2 overlay (writes go to overlay, base stays clean)
    # - User-mode networking with SSH port forwarding
    # - TCP serial console for management
    # - ISO with install scripts attached
    nohup qemu-system-x86_64 -m 256 -nographic \
        -drive file="$QCOW2_OVERLAY",format=qcow2,if=ide \
        -cdrom "$ISO" \
        -nic user,hostfwd=tcp::${SSH_PORT}-:22 \
        -serial tcp:127.0.0.1:${CONSOLE_PORT},server,nowait \
        -pidfile "$QEMU_PIDFILE" \
        &>/tmp/openwrt-qemu.log &

    local pid=$!
    echo "QEMU PID: $pid"
    echo "$pid" > "$QEMU_PIDFILE"

    # 等待启动
    echo "Waiting for boot..."
    for i in $(seq 1 60); do
        if grep -q "br-lan.*forwarding\|root@OpenWrt" /tmp/openwrt-qemu.log 2>/dev/null; then
            echo "System booted after ${i}s"
            break
        fi
        sleep 2
    done

    echo ""
    echo "=== OpenWrt QEMU is running ==="
    echo "  SSH:       ssh -p $SSH_PORT root@127.0.0.1"
    echo "  Console:   $0 console"
    echo "  First-time SSH setup: $0 setup"
    echo "  Stop:      $0 stop"
}

# 停止 QEMU
stop_qemu() {
    if [ -f "$QEMU_PIDFILE" ]; then
        local pid
        pid=$(cat "$QEMU_PIDFILE")
        echo "Stopping OpenWrt QEMU (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        rm -f "$QEMU_PIDFILE"
        echo "Stopped."
    else
        echo "OpenWrt QEMU is not running."
    fi
}

# SSH 连接
ssh_connect() {
    if [ ! -f "$SSH_KEY" ]; then
        echo "SSH key not found. Run '$0 setup' first to configure SSH access."
        exit 1
    fi
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i "$SSH_KEY" -p "$SSH_PORT" root@127.0.0.1 "$@"
}

# 串口控制台
console_connect() {
    if ! command -v socat &>/dev/null; then
        echo "ERROR: socat not found. Install it first."
        exit 1
    fi
    echo "Connecting to serial console (Ctrl+A+D to detach)..."
    echo "Or just Ctrl+C to exit."
    socat -,raw,echo=0 TCP:127.0.0.1:$CONSOLE_PORT
}

# 状态
check_status() {
    if [ -f "$QEMU_PIDFILE" ] && kill -0 "$(cat "$QEMU_PIDFILE")" 2>/dev/null; then
        local pid
        pid=$(cat "$QEMU_PIDFILE")
        echo "OpenWrt QEMU: RUNNING (PID: $pid)"
        echo "  SSH port:       $SSH_PORT"
        echo "  Console port:   $CONSOLE_PORT"
        echo "  Log:            /tmp/openwrt-qemu.log"
        if [ -f "$SSH_KEY" ]; then
            echo "  SSH configured: YES"
        else
            echo "  SSH configured: NO (run '$0 setup')"
        fi
        return 0
    else
        echo "OpenWrt QEMU: NOT RUNNING"
        return 1
    fi
}

# 一键 SSH 配置 (通过串口配置防火墙)
setup_ssh() {
    check_status || { echo "Start QEMU first with '$0 start'"; exit 1; }

    # 等待系统就绪
    echo "Waiting for system to be ready..."
    sleep 3

    # 生成 SSH key (如果没有)
    if [ ! -f "$SSH_KEY" ]; then
        mkdir -p "$(dirname "$SSH_KEY")"
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
        echo "SSH key generated: $SSH_KEY"
    fi

    echo ""
    echo "=== Configuring OpenWrt firewall for SSH access ==="
    echo "Connecting via serial console..."
    echo ""

    export CONSOLE_PORT="$CONSOLE_PORT"
    export SSH_KEY_FILE="$SSH_KEY"

    expect << 'SETUP'
        set timeout 60
        set console_port $env(CONSOLE_PORT)
        set ssh_key_file $env(SSH_KEY_FILE)

        # 读取公钥
        set fh [open "$ssh_key_file.pub" r]
        set pubkey [read -nonewline $fh]
        close $fh

        # 连接串口
        spawn socat -,raw,echo=0 TCP:127.0.0.1:$console_port

        # 系统可能已启动完毕, 发送回车触发新提示符
        send "\r"
        expect {
            timeout { puts "ERROR: Console timeout (system may still be booting)"; exit 1 }
            -re {root@[^:]+:[^#]*#} { }
        }

        puts "1/3: Adding firewall rule for SSH from WAN..."
        send "uci add firewall rule\r"
        expect -re {root@[^:]+:[^#]*#}
        send "uci set firewall.@rule\[-1\].name='Allow-SSH-WAN'\r"
        expect -re {root@[^:]+:[^#]*#}
        send "uci set firewall.@rule\[-1\].src='wan'\r"
        expect -re {root@[^:]+:[^#]*#}
        send "uci set firewall.@rule\[-1\].target='ACCEPT'\r"
        expect -re {root@[^:]+:[^#]*#}
        send "uci set firewall.@rule\[-1\].proto='tcp'\r"
        expect -re {root@[^:]+:[^#]*#}
        send "uci set firewall.@rule\[-1\].dest_port='22'\r"
        expect -re {root@[^:]+:[^#]*#}
        send "uci commit firewall\r"
        expect -re {root@[^:]+:[^#]*#}
        send "/etc/init.d/firewall restart 2>&1\r"
        expect -re {root@[^:]+:[^#]*#}

        puts "2/3: Adding SSH public key..."
        send "mkdir -p /etc/dropbear\r"
        expect -re {root@[^:]+:[^#]*#}
        send "echo '$pubkey' >> /etc/dropbear/authorized_keys\r"
        expect -re {root@[^:]+:[^#]*#}

        puts "3/3: Verifying SSH is listening..."
        send "ss -tlnp 2>/dev/null | grep :22\r"
        expect -re {root@[^:]+:[^#]*#}

        puts ""
        puts "=== Setup complete! ==="
        puts "You can now SSH: ssh -p 2222 -i $ssh_key_file root@127.0.0.1"

        send "sync\r"
        expect -re {root@[^:]+:[^#]*#}
SETUP

    # 测试 SSH 连接
    echo ""
    echo "Testing SSH connection..."
    sleep 3
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i "$SSH_KEY" -p "$SSH_PORT" root@127.0.0.1 "echo SSH_OK" 2>/dev/null; then
        echo ""
        echo "========================================"
        echo " SSH setup successful!"
        echo "========================================"
        echo "  Quick SSH:  openwrt-qemu ssh"
        echo "  Full SSH:   ssh -p $SSH_PORT -i $SSH_KEY root@127.0.0.1"
    else
        echo ""
        echo "WARNING: SSH test failed."
        echo "You may need to log in via serial console manually:"
        echo "  $0 console"
        echo ""
        echo "Then add the firewall rule manually:"
        echo '  uci add firewall rule'
        echo "  uci set firewall.@rule[-1].name='Allow-SSH-WAN'"
        echo "  uci set firewall.@rule[-1].src='wan'"
        echo "  uci set firewall.@rule[-1].target='ACCEPT'"
        echo "  uci set firewall.@rule[-1].proto='tcp'"
        echo "  uci set firewall.@rule[-1].dest_port='22'"
        echo "  uci commit firewall"
        echo "  /etc/init.d/firewall restart"
    fi
}

# === 主逻辑 ===

case "${1:-help}" in
    start)
        check_deps
        start_qemu
        ;;
    stop)
        stop_qemu
        ;;
    ssh)
        shift
        ssh_connect "$@"
        ;;
    console)
        console_connect
        ;;
    status)
        check_status
        ;;
    setup)
        setup_ssh
        ;;
    help|*)
        echo "Usage: $0 {start|stop|ssh|console|status|setup}"
        echo ""
        echo "Commands:"
        echo "  start    - Start OpenWrt QEMU virtual machine"
        echo "  stop     - Stop OpenWrt QEMU"
        echo "  ssh      - SSH into OpenWrt (after setup)"
        echo "  console  - Connect to serial console"
        echo "  status   - Check if OpenWrt is running"
        echo "  setup    - One-time SSH configuration (firewall + SSH key)"
        ;;
esac
