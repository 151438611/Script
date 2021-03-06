#!/bin/sh
# n2n_v2 for Linux amd64、arm64、mipsel ,需要安装ifconfig命令，使用root用户运行
# openwrt默认没有加载tun kernel module,需要重新编译安装
# 注意事项: 所有的edge命令参数位置必须一致,不一致有可能无法连通; 示例: edge -c xx -d xx和 edge -d -c 则无法连通
# 超级节点命令: supernode -l port &

export PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# 设置 supernode 超级节点信息
supernode_host="n2n.xxy1.ltd"
supernode_port=8000
# 设置 edge 节点信息
ipadd=10.5.5.x
#netmask=255.255.255.0
vmnic_name=edge
community_name=n2nEdge
# 是否加密(加密后仅密码一致的节点可互相通信) --- 会影响速度，不建议使用此选项
N2N_KEY=	

log=/tmp/n2n_log.txt
[ -f $log ] || echo $(date +"%F %T") > $log

base_url="http://frp.xxy1.ltd:35100/file/vpn_proxy/n2n"

if [ -n "$(grep -i padavan /proc/version)" ] ; then
	os_type=padavan
elif [ -n "$(grep -Ei "openwrt|lede" /proc/version)" ] ; then
	os_type=openwrt
else 
	os_type=linux
fi

case $(uname -m) in 
	x86_64)
		edge="/usr/sbin/edge"
		down_url="${base_url}/edge_n2n_v2_linux_amd64"
	;;
	aarch64)
		edge="/usr/sbin/edge"
		down_url="${base_url}/edge_n2n_v2_linux_arm64"
	;;
	mips)
		if [ "$os_type" = padavan ] ; then 
			edge="/etc/storage/bin/edge"
			down_url="${base_url}/edge_n2n_v2_linux_mipsel"
		elif [ "$os_type" = openwrt ] ; then 
			edge="/usr/sbin/edge"
			down_url="${base_url}/edge_n2n_v2_linux_mips"
		fi
	;;
	*)
		echo "This is unsupport device !!!" | tee -a $log
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
	iptables -I FORWARD -o $vmnic_name -j ACCEPT
	
	# for all routers
	[ -z "$(iptables -t nat -vnL POSTROUTING | grep -Ei "${vmnic_name}|${ipadd}")" ] && \
	iptables -t nat -A POSTROUTING -o $vmnic_name -d ${ipadd%.*}.0/24 -j SNAT --to-source $ipadd
	
	# 适用于 jhK2P_75，映射81端口到海康E24H摄像头的web上
	#[ -z "$(iptables -t nat -vnL PREROUTING | grep -Ei "${vmnic_name}|${ipadd}")" ] && \
	#iptables -t nat -A PREROUTING -p tcp -i ${vmnic_name} -d ${ipadd} --dport 81 -j DNAT --to 192.168.75.128:80
	
	# 适用于 jhK2P_75 / gxK2_57，映射82端口到 192.168.1.1 光猫web上
	#[ -z "$(iptables -t nat -vnL PREROUTING | grep -Ei "${vmnic_name}|${ipadd}")" ] && \
	#iptables -t nat -A PREROUTING -p tcp -i ${vmnic_name} -d ${ipadd} --dport 82 -j DNAT --to 192.168.1.1:80
	#[ -z "$(iptables -t nat -vnL POSTROUTING | grep -i 10.5.5.0/24)" ] && \
	#iptables -t nat -A POSTROUTING -s 10.5.5.0/24 -d 192.168.1.1 -j SNAT --to 192.168.1.11
}

if [ ! -x $edge ]; then
	rm -f $edge
	wget -c -T 10 -O $edge $down_url
	chmod +x $edge
fi

ping -w 3 114.114.114.114 && \
if [ -n "$(pidof $(basename $edge))" ]; then
	echo "$(date +"%F %T")	$edge $ipadd is runing , Don't do anything !" >> $log
else
	[ $N2N_KEY ] && \
	$edge -d $vmnic_name -c $community_name -a $ipadd -Er -k $N2N_KEY -l $supernode_host:$supernode_port || \
	$edge -d $vmnic_name -c $community_name -a $ipadd -Er -A1 -l $supernode_host:$supernode_port
	echo "$(date +"%F %T")	$edge $ipadd was not runing ; start $edge ..." >> $log
fi && sleep 3 && addIptables


# ============= 临时使用 ====================
tmp_use=0
if [ $tmp_use -eq 1 ]; then
	id_rsa_public="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxYepQiOrFXyRsAy5tLmzhIw+Wpgssh5YUZ+zDq5GKpySVrlSGYOJEqFI3JOSYImW+TGUCRnZQNBipYdULd7an4fNDPBx4ZwPXotVrQwwWEkf8p6NPCnGVHqj+cwOYdgm6Oj8LP3W9djqA+6ojkpIk6h+KBp0D4rKVR1mmpBYrQ9Ty0dd7nH1qxwdUYSVV2xT1pc8/70r2OVjSAstEhItzFvNFGIl5X9e5VIgtZyKplWub4+R6bMBKY+M/ZAmzqLw5jAWVJv2Iu2YFeQgv105fFbBAobvkvxy8VdMFCalbl5UqTXMEjg+ZDH4eiGtR2mk7TsDdF7aIU6OIbSOoaTAqQ== rsa 2048-022219"
	[ -d ~/.ssh ] || { mkdir -p ~/.ssh && chmod 700 ~/.ssh; }
	[ -f ~/.ssh/authorized_keys ] || { touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys; }
	grep -q "$id_rsa_public" ~/.ssh/authorized_keys || \
		echo "$id_rsa_public" >> ~/ssh/authorized_keys

	[ -f /etc/edge.sh ] || cp -f $0 /etc/
	chattr +i /etc/edge.sh $edge
	grep -q edge /etc/rc.local || echo "bash /etc/edge.sh" >> /etc/rc.local
	chmod +x /etc/rc.local
fi
