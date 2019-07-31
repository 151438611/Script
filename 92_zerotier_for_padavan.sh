#/bin/bash
# script for Padavan
# zerotier安装步骤：1、插U盘，格式为ext4，安装entware ；2、 opkg install zerotier
# 先启动zerotier-one -d 再加入网络 zerotier-cli join network_ID 再添加防火墙规则

export PATH=/opt/bin:/opt/sbin:$PATH
z_one=$(which zerotier-one)
z_cli=$(which zerotier-cli)
z_log=/tmp/zerotier.log

log_ok() {
	echo "$(date +"%F %T") $1" >> $z_log
}
log_er() {
	echo "$(date +"%F %T") $1" >> $z_log
	exit 1
}
# 1、判断已安装 zerotier 软件
[ -z "$z_one" ] && log_er "zerotier does no exist !"

# 2、判断 zerotier-one 主程序已启动; sleep是为了启动需要时间
[ -z "$(pidof zerotier-one)" ] && $z_one -d && sleep 5

# 3、判断 zerotier-cli 加入虚拟网络成功
vm_network=$($z_cli listnetworks)
vm_nic=$(echo "$vm_network" | awk 'NR == 2 && $6 == "OK" {print $8}')
[ -z "$vm_nic" ] && log_er "$z_cli is not join Network ID !"
vm_ip=$(echo "$vm_network" | awk 'NR == 2 && $6 == "OK" {print $9}')

# 4、判断 iptables 是否添加 zerotier 规则
iptables_input=$(iptables -nvL INPUT --line-number)
iptables_forward=$(iptables -nvL FORWARD --line-number)
iptables_nat=$(iptables -t nat -nvL POSTROUTING --line-number)

# 添加入站规则
if [ -z "$(echo "$iptables_input" | awk '$7 == "'$vm_nic'" {print $7}')" ]; then
	iptables_input_num=$(echo "$iptables_input" | awk 'END {print $1}')
	iptables -I INPUT $((iptables_input_num + 1)) -i $vm_nic -j ACCEPT
fi
# 添加转发规则
iptables_forward_num=$(echo "$iptables_forward" | awk 'END {print $1}')
[ -z "$(echo "$iptables_forward" | awk '$7 == "'$vm_nic'" {print $7}')" ] && \
iptables -I FORWARD $((iptables_forward_num + 1)) -i $vm_nic -j ACCEPT
[ -z "$(echo "$iptables_forward" | awk '$8 == "'$vm_nic'" {print $8}')" ] && \
iptables -I FORWARD $((iptables_forward_num + 1)) -o $vm_nic -j ACCEPT
# 添加nat规则
if [ -z "$(echo "$iptables_nat" | awk '$8 == "'$vm_nic'" {print $8}')" ]; then
	iptables_nat_num=$(echo "$iptables_nat" | awk 'END {print $1}')
	iptables -t nat -I POSTROUTING $((iptables_nat_num + 1)) -o $vm_nic -j MASQUERADE
fi

log_ok "Zerotier join Network_ID success, VM_IP: $vm_ip"
