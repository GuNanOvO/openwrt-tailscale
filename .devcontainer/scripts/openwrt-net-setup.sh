#!/bin/bash
# Configure OpenWrt guest for internet access + SSH
# Run after starting QEMU

expect -c 'set timeout 40
spawn socat -,raw,echo=0 TCP:127.0.0.1:4444
send "\r"
expect -re {root@[^:]+:[^#]*#}

puts "=== 1/5: WAN DHCP ==="
send "uci delete network.lan.ifname 2>/dev/null\r"
expect -re {root@[^:]+:[^#]*#}
send "uci delete network.lan.device 2>/dev/null\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set network.wan=interface\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set network.wan.proto=dhcp\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set network.wan.device=eth0\r"
expect -re {root@[^:]+:[^#]*#}
send "uci commit network\r"
expect -re {root@[^:]+:[^#]*#}

puts "=== 2/5: Restart network ==="
send "ifdown wan 2>/dev/null; ifup wan 2>&1\r"
expect -re {root@[^:]+:[^#]*#}
sleep 8

puts "=== 3/5: DNS ==="
send "echo nameserver 10.0.2.3 > /etc/resolv.conf; echo DNS_DONE\r"
expect -re {root@[^:]+:[^#]*#}

puts "=== 4/5: Firewall SSH rule ==="
send "uci add firewall rule\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set firewall.@rule[-1].name=SshWan\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set firewall.@rule[-1].src=wan\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set firewall.@rule[-1].target=ACCEPT\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set firewall.@rule[-1].proto=tcp\r"
expect -re {root@[^:]+:[^#]*#}
send "uci set firewall.@rule[-1].dest_port=22\r"
expect -re {root@[^:]+:[^#]*#}
send "uci commit firewall\r"
expect -re {root@[^:]+:[^#]*#}
send "/etc/init.d/firewall restart 2>&1\r"
expect -re {root@[^:]+:[^#]*#}
sleep 3

puts "=== 5/5: Verify ==="
send "ip addr show eth0 | grep inet\r"
expect -re {root@[^:]+:[^#]*#}
send "ping -c 1 -W 3 223.5.5.5 2>&1\r"
expect -re {root@[^:]+:[^#]*#}
send "echo SETUP_COMPLETE\r"
expect -re {root@[^:]+:[^#]*#}
exit
'

echo ""
echo "=== Testing SSH ==="
sleep 3
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i /home/vscode/.ssh/openwrt_qemu \
    -p 2222 root@127.0.0.1 \
    "echo SSH_WORKS && uname -a && ping -c 1 -W 3 223.5.5.5 2>&1 | grep packets" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo " QEMU OpenWrt fully configured!"
    echo "============================================"
    echo "  SSH:   ssh -p 2222 root@127.0.0.1"
    echo "  Quick: qemu-ssh"
    echo "  Internet: OK"
fi
