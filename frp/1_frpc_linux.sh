#!/bin/sh
#################################################################
# FILE NAME: frpc.sh
# DESCRIPTION: support ARM64、X86_64、Padavan_mipsle(K2、K2P_A1/B1、YoukuL1)、Openwrt_mips(TP-Link WR941v6、WR841v7还未测试) Linux
#	Padavan和Openwrt系统可自动下载frpc和创建默认的frpc.ini，建议事先创建frpc.ini配置文件
# MODIFICATION HISTORY:
# NAME		DATE	  Description
# =====		========  ===========================================
# Jun		20200314  Created
#################################################################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
main_url="http://frp.xxy1.ltd:35100/file/frp/"
main_url_bak="http://frp.xxy1.ltd:35300/file/frp/"
wget -q -O /dev/null $main_url || main_url=$main_url_bak

log=/tmp/frpc.log
[ -f $log ] || echo "$(date +"%F %T") First start" > $log

download_frpc_fun() {
	killall -q $(basename $frpc)
	rm -f $frpc
	wget -t 2 -T 8 -O $frpc $download_frpc
	chmod +x $frpc
	[ "$($frpc -v)" ] || {
		killall -q wget
		rm -f $frpc
		wget -t 2 -T 8 -O $frpc ${download_frpc_bak:-$download_frpc}
		chmod +x $frpc
	}
}
frpc_ini_fun() {
	# ----- 1、填写服务端的IP/域名、认证密码 -----------------------
	server_addr=frp.xxy1.ltd
	server_port=7777
	token=xxxx
	user_name=
	[ "$user_name" ] || user_name=frpc_$(md5sum /proc/meminfo | cut -c 1-4)
	lan_ip=
	
	cat << END > $frpc_ini
[common]
server_addr = $server_addr
server_port = $server_port
token = $token
user = $user_name
protocol = tcp
pool_count = 8
admin_addr = 0.0.0.0
admin_port = 7400
admin_user = admin
admin_pwd = admin
log_level = error
#log_max_days = 3
#log_file = /tmp/frpc.log
tcp_mux = true
login_fail_exit = true

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = false
use_compression = false

[web]
type = tcp
local_ip = ${lan_ip:-192.168.1.1}
local_port = 80
remote_port = 0
END
}

if [ "$(uname -m)" = x86_64 ] ; then
	hw_type=amd64
elif [ "$(uname -m)" = aarch64 ] ; then
	hw_type=arm64
elif [ -n "$(grep -i ARMv7 /proc/cpuinfo)" ] ; then
	hw_type=arm
elif [ -n "$(grep -Ei "MT7620|MT7621" /proc/cpuinfo)" ] ; then
	hw_type=mipsle
elif [ -n "$(grep -i AR7241 /proc/cpuinfo)" ] ; then
	hw_type=mips
else
	hw_type=unknow
fi

if [ -n "$(grep -i padavan /proc/version)" ] ; then
	os_type=padavan
elif [ -n "$(grep -i openwrt /proc/version)" ] ; then
	os_type=openwrt
else 
	os_type=linux
fi

download_frpc="${main_url}frpc_linux_${hw_type}"
case $hw_type in
	amd64|arm64)
	# 适用于N1和x86_64架构的Linux设备
		download_frpc_bak="${main_url_bak}frpc_linux_${hw_type}"
		frpc=/opt/frp/frpc
		frpc_ini=/opt/frp/frpc.ini
		frpc_sh=/opt/frp/frpc.sh
		[ -d $(dirname $frpc_ini) ] || mkdir -p $(dirname $frpc_ini)
	;;
	arm)
		# K2P-B1版本CPU为BCM47189，为ARM
		download_frpc_bak="${main_url_bak}frpc_linux_${hw_type}"
		#frpc=/tmp/frpc
		frpc_ini=/tmp/media/data/frp.ini
		frpc_sh=/tmp/media/data/frpc.sh
		cron=/tmp/media/data/cron_file
		startup=/tmp/media/data/auto_file
	;;
	mips)
		# 适用于TP-Link WR941v6、WR841v7,暂时没有投入使用，未测试
		download_frpc_bak="${main_url_bak}frpc_linux_${hw_type}"
		#frpc=/tmp/frpc
		frpc_ini=/etc/frpc.ini
		frpc_sh=/etc/frpc.sh
		cron=/etc/crontabs/root
		startup=/etc/rc.local
	;;
	mipsle)
		download_frpc_bak="http://opt.cn2qq.com/opt-file/frpc"
		if [ "$os_type" = padavan ] ; then
			# 适用于K2、K2P_A1、YoukuL1路由器Padavan_OS
			#frpc=/tmp/frpc
			frpc_ini=/etc/storage/bin/frpc.ini
			frpc_sh=/etc/storage/bin/frpc.sh
			cron=/etc/storage/cron/crontabs/admin
			startup=/etc/storage/started_script.sh	
			# 开启从wan口访问路由器和ssh服务(默认关闭)，即从上级路由直接访问下级路由或ssh服务
			[ $(nvram get sshd_wopen) -eq 0 ] && { 
				nvram set sshd_wopen=1 ; nvram set sshd_wport=22 ; nvram commit
				}
			[ $(nvram get sshd_enable) -eq 0 ] && { nvram set sshd_enable=1 ; nvram commit ; }
		elif [ "$os_type" = openwrt ] ; then
			#frpc=/tmp/frpc
			frpc_ini=/etc/frpc.ini
			frpc_sh=/etc/frpc.sh
			cron=/etc/crontabs/root
			startup=/etc/rc.local
		fi
	;;
	*)
		echo "!!! Router or OS is Unsupported device , exit !!!" >> $log
		exit 1
	;;
esac

download_sh="${main_url}frpc.sh"
[ -f $frpc_sh ] || { wget -O $frpc_sh $download_sh && chmod +x $frpc_sh ; }

if [ -n "$(echo $hw_type | grep -Ei "mipsle|mips|arm$")" ] ; then
	udisk=$(mount | awk '$1~"/dev/" && $3~"^/media/"{print $3}' | head -n1)
	frpc=${udisk:=/tmp}/frpc
fi
[ $cron ] && {
	cron_reboot="5 5 * * 1,5 /sbin/reboot"
	cron_sh="20 * * * * sh $frpc_sh"
	grep -q reboot $cron || echo "$cron_reboot" >> $cron
	grep -q "$frpc_sh" $cron || echo "$cron_sh" >> $cron
}
[ $startup ] && {
	[ $(which curl) ] && startup_cmd="curl $download_sh | sh" || startup_cmd="wget -q -O - $download_sh | sh"
	grep -q "$download_sh" $startup || echo "$startup_cmd" >> $startup
}

$frpc -v || download_frpc_fun
[ -f $frpc_ini ] || frpc_ini_fun
[ -x $frpc ] && [ -f $frpc_ini ] || { echo "$frpc or $frpc_ini does not exist !!!" >> $log ; exit 1 ; }

# ------------------------- start frpc ---------------------
ping -c 2 223.5.5.5 && \
  if [ -z "$(pidof $(basename $frpc))" ] ; then
    echo "$(date +"%F %T") $frpc was not runing ; start $frpc ..." >> $log 
    exec $frpc -c $frpc_ini &
  else 
    echo "$(date +"%F %T") $frpc is runing , Don't do anything !" >> $log 
  fi
