#！/bin/bash
# add route and iptable rules

addRoutes() {
	# $1:dest_ip/mask ; $2:gateway
	if [ -n "$1" -a -n "$2" ]; then
		[ -z "$(ip route | grep $1)" ] && \
		ip route add $1 via $2
	else 
		echo "addRoutes 传入的参数为空,添加路由表失败！！！"
	fi

}
addIptables() {
	# $1:dest_ip/mask ; $2:net_ip
	if [ -n "$1" -a -n "$2" ]; then
		[ -z "$(iptables -t nat -vnL POSTROUTING | grep $1)" ] && \
		iptables -t nat -A POSTROUTING -d $1 -j SNAT --to $2
	else 
		echo "addIptables 传入的参数为空,添加防火墙失败！！！"
	fi
}

# for szk2p_20
#addRoutes 192.168.5.0/24 10.1.1.5
#addRoutes 192.168.75.0/24 10.1.1.75
#addRoutes 192.168.3.0/24 10.1.1.15
#addIptables 192.168.5.0/24 10.1.1.20
#addIptables 192.168.75.0/24 10.1.1.20
#addIptables 192.168.3.0/24 10.1.1.20
#addIptables 10.1.1.0/24 10.1.1.20

# for wztVmwareDebian
addRoutes 192.168.5.0/24 10.1.1.5
addRoutes 192.168.75.0/24 10.1.1.75
addRoutes 192.168.20.0/24 10.1.1.20
addIptables 192.168.5.0/24 10.1.1.15
addIptables 192.168.75.0/24 10.1.1.15
addIptables 192.168.20.0/24 10.1.1.15
addIptables 10.1.1.0/24 10.1.1.15
