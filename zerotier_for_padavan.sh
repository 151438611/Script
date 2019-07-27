#/bin/bash

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

[ -z "$z_one" -o -z "$z_cli" ] && log_er "zerotier does no exist !"

[ -z "$(pidof zerotier-one)" ] && $z_one -d 
sleep 3
vm_network=$($z_cli listnetworks)
vm_nic=$(echo "$vm_network" | awk 'NR == 2 && $6 == "OK" {print $8}')
[ -z "$vm_nic" ] && log_er "$z_cli is not join Network ID !"
vm_ip=$(echo "$vm_network" | awk -F , 'NR == 2 {print $2}')

iptables_all=$(iptables -L INPUT -n --line-number -v)
iptables_num=$(echo "$iptables_all" | wc -l)
# $iptables_num 中前二行是标题，实际iptables规则需要减 2

if [ -z "$(echo "$iptables_all" | grep -i $vm_nic)" ]; then
	iptables -I INPUT $((iptables_num - 1)) -i $vm_nic -j ACCEPT
	# 因$iptables_num中有2行非规则，所以新增序号只需要减1即可
fi

log_ok "Zerotier join Network_ID success, VM_IP: $vm_ip"