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

addIptables() {
	[ -z "$(iptables -vnL INPUT | grep "Chain INPUT" | grep -i ACCEPT)" ] && \
	[ -z "$(iptables -vnL INPUT | grep $vmnic_name)" ] && \
	iptables -A INPUT -i $vmnic_name -j ACCEPT
	[ -z "$(iptables -vnL FORWARD | grep "Chain FORWARD" | grep -i ACCEPT)" ] && \
	[ -z "$(iptables -vnL FORWARD | grep $vmnic_name)" ] && \
	iptables -A FORWARD -i $vmnic_name -j ACCEPT
	# for VmwareDebian
	#[ -n "$(route -n | grep 192.168.75.)" ] || ip route add 192.168.75.0/24 via 10.0.0.75
	#[ -n "$(iptables -t nat -vnL | grep 192.168.75.)" ] || \
	#	iptables -t nat -A POSTROUTING -d 192.168.75.0/24 -j SNAT --to-source 10.0.0.15
	
	#[ -n "$(route -n | grep 192.168.5.)" ] || ip route add 192.168.5.1 via 10.0.0.5
	#[ -n "$(iptables -t nat -vnL | grep 192.168.5.)" ] || \
	#	iptables -t nat -A POSTROUTING -d 192.168.5.1 -j SNAT --to-source 10.0.0.15
}

if [ ! -x $edge ]; then
	rm -f $edge
	wget -O $edge $down_url
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
