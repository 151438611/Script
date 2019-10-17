#!/bin/bash
# n2n edge for Linux amd64、arm64、mipsle , unsupport Openwrt ,需要安装ifconfig命令，使用root用户运行
# 超级节点 supernode -l port &

# 设置 supernode 超级节点信息
supernode_ip_port=frp.xiongxinyi.cn:8000
# 设置 edge 节点信息
vmnic_name=n2nEdge
community_name=n2n
ipadd=10.0.0.x
netmask=255.255.255.0
# 是否加密(加密后仅密码一致的节点可互相通信) --- 会影响速度，不建议使用此选项
N2N_KEY=	

log=/tmp/n2n_log.txt
[ -f $log ] || echo $(date +"%F %T") > $log

down_url="http://frp.xiongxinyi.cn:30100/file/"
hw_type=$(uname -m)
case $hw_type in 
	x86_64)
		edge="/usr/sbin/edge"
		down_url="${down_url}n2n/edge_linux_amd64"
	;;
	aarch64)
		edge="/usr/sbin/edge"
		down_url="${down_url}n2n/edge_linux_arm64"
	;;
	mips)
		if [ -n "$(grep -i padavan /proc/version)" ]; then
			edge="/etc/storage/bin/edge"
			down_url="${down_url}n2n/edge_padavan_mipsle"
		else
			edge="/etc/edge"
			down_url="${down_url}n2n/edge_openwrt_mips"
		fi
	;;
esac
addIPRoutes() {
	# 传入$1为目标主机/网段、$2为网关地址
	[ -z "$1" -o -z "$2" ] && echo "传入目标地址或网关地址为空，添加路由规则失败 ，请重新检查 ！！！" 
	destIP=$1
	gw=$2
	# 判断IP是否有效，将IP地址转成列表 --- 此命令仅适用于x86_64的Linux系统，在Padavan中无法运行，停用判断
	#destIP1=(${destIP//\./ })	
	#if [ "${destIP1[0]}" -lt 255 -a "${destIP1[1]}" -lt 255 -a "${destIP1[2]}" -lt 255 -a "${destIP1[3]}" -lt 255 ]; then
	# 如果IP的最后一位为0表示一个网段，如果不是0表示一个主机
	#[ "${destIP1[3]}" -eq 0 ] && destIP="${destIP}/24"
	#[ -n "$(ip route | grep $)"]
	#else
	#	echo "传入目标地址不是有效的IP地址，添加路由规则失败 ，请重新检查 ！！！" 
	#fi
	if [ -z "$(echo ${destIP}$gw | tr -d [0-9] | grep -E "......|.../...")" ]; then
		echo "传入目标地址或网关地址无效，添加路由规则失败 ，请重新检查 ！！！"
		return
	fi
	[ -n "$(ip route | grep $destIP)" ] || ip route add $destIP via $gw
}

addIptables() {
	[ -z "$(iptables -vnL INPUT | grep "Chain INPUT" | grep -i ACCEPT)" ] && \
	[ -z "$(iptables -vnL INPUT | grep $vmnic_name)" ] && \
	iptables -A INPUT -i $vmnic_name -j ACCEPT
	[ -z "$(iptables -vnL FORWARD | grep "Chain FORWARD" | grep -i ACCEPT)" ] && \
	[ -z "$(iptables -vnL FORWARD | grep $vmnic_name)" ] && \
	iptables -A FORWARD -i $vmnic_name -j ACCEPT
	# for wzt_VmwareDebian
	#ip0=10.0.0.0/24
	#[ -n "$(iptables -t nat -vnL | grep $ip0)" ] || \
	#	iptables -t nat -A POSTROUTING -s $ip0 -d 192.168.3.0/24 -j SNAT --to-source 192.168.3.177
	#ip1=192.168.75.0/24
	#addIPRoutes $ip1 10.0.0.75
	#[ -n "$(iptables -t nat -vnL | grep $ip1)" ] || \
	#	iptables -t nat -A POSTROUTING -d $ip1 -j SNAT --to-source 10.0.0.15
	#ip2=192.168.5.0/24
	#addIPRoutes $ip2 10.0.0.5
	#[ -n "$(iptables -t nat -vnL | grep $ip2)" ] || \
	#	iptables -t nat -A POSTROUTING -d $ip2 -j SNAT --to-source 10.0.0.15
	#ip3=192.168.84.1
	#addIPRoutes $ip3 10.0.0.5
	#[ -n "$(iptables -t nat -vnL | grep $ip3)" ] || \
	#	iptables -t nat -A POSTROUTING -d $ip3 -j SNAT --to-source 10.0.0.15
	# 需要在gxk2_05路由器上开启 iptables -t nat -A POSTROUTING -d 192.168.84.1 -j SNAT --to-source 192.168.84.240
	
	# for jh_YoukuL1
	#ip4=192.168.75.0/24
	#[ -n "$(iptables -t nat -vnL | grep $ip4)" ] || \
	#	iptables -t nat -A POSTROUTING -d $ip4 -j SNAT --to-source 192.168.75.200
	
	# for szK2P_20
	#ip4=192.168.3.0/24
	#addIPRoutes $ip2 10.0.0.15
	#[ -n "$(iptables -t nat -vnL | grep $ip4)" ] || \
	#	iptables -t nat -A POSTROUTING -d $ip4 -j SNAT --to-source 192.168.75.200
}

if [ ! -x $edge ]; then
	rm -f $edge
	wget -c -t 3 -T 10 -O $edge $down_url
	chmod 555 $edge
fi

ping -c 2 -w 3 114.114.114.114 && \
if [ -n "$(pidof ${edge##*/})" ]; then
	echo "$(date +"%F %T")	${edge##*/} $ipadd is runing , Don't do anything !" >> $log
else
	[ $N2N_KEY ] && \
	$edge -r -d $vmnic_name -c $community_name -a $ipadd -s $netmask -l $supernode_ip_port -k $N2N_KEY || \
	$edge -r -d $vmnic_name -c $community_name -a $ipadd -s $netmask -l $supernode_ip_port
	sleep 3
	addIptables
	echo "$(date +"%F %T")	${edge##*/} $ipadd was not runing ; start ${edge##*/} ..." >> $log
fi
