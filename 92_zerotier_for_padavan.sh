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
[ -z "$z_one" -o -z "$z_cli" ] && log_er "zerotier does no exist !"

# 2、判断 zerotier-one 主程序已启动; sleep是为了启动需要时间
[ -z "$(pidof zerotier-one)" ] && $z_one -d && sleep 5

# 3、判断 zerotier-cli 加入虚拟网络成功
vm_network=$($z_cli listnetworks)
vm_nic=$(echo "$vm_network" | awk 'NR == 2 && $6 == "OK" {print $8}')
[ -z "$vm_nic" ] && log_er "$z_cli is not join Network ID !"
vm_ip=$(echo "$vm_network" | awk 'NR == 2 && $6 == "OK" {print $9}')

# 4、判断 iptables 是否添加 zerotier 新增的虚拟网卡规则
iptables_all=$(iptables -nvL INPUT --line-number)
# $iptables_all 中前二行是标题和格式，实际 iptables_num 规则数量需要减 2
iptables_num=$(echo "$iptables_all" | wc -l)
if [ -z "$(echo "$iptables_all" | grep -i $vm_nic)" ]; then
	iptables -I INPUT $((iptables_num - 1)) -i $vm_nic -j ACCEPT
	# 因 $iptables_num 中有2行非规则，所以新增序号只需要减1即可
fi

log_ok "Zerotier join Network_ID success, VM_IP: $vm_ip"
