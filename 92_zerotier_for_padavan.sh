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
iptables_input=$(iptables -nvL INPUT)
iptables_forward=$(iptables -nvL FORWARD)
iptables_nat=$(iptables -t nat -nvL POSTROUTING)
# 添加 iptables INPUT 规则
[ -z "$(echo "$iptables_input" | awk '$6 == "'$vm_nic'" {print $6}')" ] && \
iptables -A INPUT -i $vm_nic -j ACCEPT
# 添加 iptables FORWARD 规则
[ -z "$(echo "$iptables_forward" | awk '$6 == "'$vm_nic'" {print $6}')" ] && \
iptables -A FORWARD -i $vm_nic -j ACCEPT
[ -z "$(echo "$iptables_forward" | awk '$7 == "'$vm_nic'" {print $7}')" ] && \
iptables -A FORWARD -o $vm_nic -j ACCEPT
# 添加 iptables nat 规则
[ -z "$(echo "$iptables_nat" | awk '$7 == "'$vm_nic'" {print $7}')" ] && \
iptables -t nat -A POSTROUTING -o $vm_nic -j MASQUERADE

# 5、判断 route 是否添加路由策略
dest_net=192.168.3.0
dest_host1=192.168.1.250
dest_host2=192.168.1.122
gw=192.168.168.10

route_rules=$(route -n)
[ -z "$(echo "$route_rules" | awk '$1 == "'$dest_net'" && $2 == "'$gw'" {print $1}')" ] && \
route add -host ${dest_net}/24 gw $gw
[ -z "$(echo "$route_rules" | awk '$1 == "'$dest_host1'" && $2 == "'$gw'" {print $1}')" ] && \
route add -host $dest_host1 gw $gw
[ -z "$(echo "$route_rules" | awk '$1 == "'$dest_host2'" && $2 == "'$gw'" {print $1}')" ] && \
route add -host $dest_host2 gw $gw

log_ok "Zerotier join Network_ID success, VM_IP: $vm_ip"
