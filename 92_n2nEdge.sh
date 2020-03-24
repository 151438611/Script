#!/bin/bash
# n2n edge for Linux amd64、arm64、mipsle ,需要安装ifconfig命令，使用root用户运行
# openwrt默认没有加载tun kernel module,需要重新编译安装
# 注意事项: 所有的edge命令参数位置必须不一致,不一致有可能无法连通; 示例: edge -c -d 和 edge -d -c则无法连通
# 超级节点 supernode -l port &

# 设置 supernode 超级节点信息
supernode_ip_port=n2n.xxy1.ltd:10086
# 设置 edge 节点信息
vmnic_name=edge
community_name=n2nEdge
ipadd=10.5.5.x
netmask=255.255.255.0
# 是否加密(加密后仅密码一致的节点可互相通信) --- 会影响速度，不建议使用此选项
N2N_KEY=	

log=/tmp/n2n_log.txt
[ -f $log ] || echo $(date +"%F %T") > $log

base_url="http://frp.xxy1.ltd:35100/file/n2n"
if [ -n "$(grep -Ei "MT7620|MT7621" /proc/cpuinfo)" ] ; then
	hw_type=mipsle
elif [ -n "$(grep -i ARMv7 /proc/cpuinfo)" ] ; then
	hw_type=arm
elif [[ -n "$(grep -i ARMv8 /proc/cpuinfo)" && "$(uname -m)" = aarch64 ]] ; then
	hw_type=arm64
elif [ -n "$(grep -i AR7241 /proc/cpuinfo)" ] ; then
	hw_type=mips
elif [ "$(uname -m)" = x86_64 ] ; then
	hw_type=amd64
fi
case $hw_type in 
	amd64)
		edge="/usr/sbin/edge"
		down_url="${base_url}/edge_linux_amd64"
	;;
	arm64)
		edge="/usr/sbin/edge"
		down_url="${base_url}/edge_linux_arm64"
	;;
	mipsle)
		edge="/etc/storage/bin/edge"
		down_url="${base_url}/edge_padavan_mipsle"
	;;
	mips)
		edge="/etc/edge"
		down_url="${base_url}/edge_openwrt_mips"
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
}

if [ ! -x $edge ]; then
	rm -f $edge
	wget -c -t 3 -T 10 -O $edge $down_url
	chmod +x $edge
fi

ping -c 2 114.114.114.114 && \
if [ -n "$(pidof $(basename $edge))" ]; then
	echo "$(date +"%F %T")	$edge $ipadd is runing , Don't do anything !" >> $log
else
	[ $N2N_KEY ] && \
	$edge -r -d $vmnic_name -c $community_name -a $ipadd -s $netmask -l $supernode_ip_port -k $N2N_KEY || \
	$edge -r -d $vmnic_name -c $community_name -a $ipadd -s $netmask -l $supernode_ip_port
	sleep 3
	addIptables
	echo "$(date +"%F %T")	$edge $ipadd was not runing ; start $edge ..." >> $log
fi
