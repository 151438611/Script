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
wget -T 3 -O /dev/null $main_url 2> /dev/null || main_url="http://frp.xxy1.ltd:35300/file/frp/"

if [ -n "$(grep -Ei "MT7620|MT7621" /proc/cpuinfo)" ] ; then
	hardware_type=mipsle
elif [ -n "$(grep -i ARMv7 /proc/cpuinfo)" ] ; then
	hardware_type=arm
elif [[ -n "$(grep -i ARMv8 /proc/cpuinfo)" && "$(uname -m)" = aarch64 ]] ; then
	hardware_type=arm64
elif [ -n "$(grep -i AR7241 /proc/cpuinfo)" ] ; then
	hardware_type=mips
elif [ "$(uname -m)" = x86_64 ] ; then
	hardware_type=amd64
fi

log=/tmp/frpc.log
[ -f $log ] || echo "$(date +"%F %T") First start" > $log

download_frpc_fun() {
	killall -q $(basename $frpc)
	rm -f $frpc
	wget -c -t 2 -T 10 -O $frpc $download_frpc
	chmod +x $frpc
	[ "$($frpc -v)" ] || {
		killall -q wget
		rm -f $frpc
		wget -c -t 2 -T 10 -O $frpc $download_frpc_bak
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
local_ip = 192.168.1.1
local_port = 80
remote_port = 0
END
}
if [ "$hardware_type" = mipsle ] ; then
	# 适用于K2、K2P_A1、YoukuL1路由器Padavan_OS
	download_frpc="${main_url}frpc_linux_${hardware_type}"
	download_frpc_bak="http://opt.cn2qq.com/opt-file/frpc"
	
	frpc_ini=/etc/storage/bin/frpc.ini
	frpc_sh=/etc/storage/bin/frpc.sh
	cron=/etc/storage/cron/crontabs/$(nvram get http_username)
	startup=/etc/storage/started_script.sh	
	# 开启从wan口访问路由器和ssh服务(默认关闭)，即从上级路由直接访问下级路由或ssh服务
	#[ $(nvram get misc_http_x) -eq 0 ] && { nvram set misc_http_x=1 ; nvram set misc_httpport_x=80 ; nvram commit ; }
	[ $(nvram get sshd_wopen) -eq 0 ] && { 
		nvram set sshd_wopen=1 ; nvram set sshd_wport=22 ; nvram commit
		}
	[ $(nvram get sshd_enable) -eq 0 ] && { nvram set sshd_enable=1 ; nvram commit ; }
elif [ "$hardware_type" = arm ] ; then
	# K2P-B1版本CPU为BCM47189，为ARM
	download_frpc="${main_url}frpc_linux_${hardware_type}"
	download_frpc_bak=
	frpc_ini=/tmp/media/data/frp.ini
	frpc_sh=/tmp/media/data/frpc.sh
	cron=/tmp/media/data/cron_file
	startup=/tmp/media/data/auto_file
elif [[ "$hardware_type" = arm64 || "$hardware_type" = amd64 ]] ; then
	# 适用于N1和X86_64架构的Linux设备
	download_frpc="${main_url}frpc_linux_${hardware_type}"
	download_frpc_bak=
	frpc=/opt/frp/frpc
	frpc_ini=/opt/frp/frpc.ini
	frpc_sh=/opt/frp/frpc.sh
	[ -d $(dirname $frpc_ini) ] || mkdir -p $(dirname $frpc_ini)
elif [ "$hardware_type" = mips ] ; then
	# 适用于TP-Link WR941v6、WR841v7,暂时没有投入使用，未测试
	download_frpc="${main_url}frpc_linux_${hardware_type}"
	download_frpc_bak=
	frpc_ini=/etc/frpc.ini
	frpc_sh=/etc/frpc.sh
	cron=/etc/crontabs/root
	startup=/etc/rc.local
else 
	echo "!!! Router or OS is Unsupported device , exit !!!" >> $log ; exit
fi

download_sh="${main_url}frpc.sh"
[ -f $frpc_sh ] || { wget -O $frpc_sh $download_sh && chmod +x $frpc_sh ; }

if [ -n "$(echo $hardware_type | grep -Ei "mipsle|mips|arm")" ] ; then
	udisk=$(mount | awk '$1~"/dev/" && $3~"^/media/"{print $3}' | head -n1)
	frpc=${udisk:=/tmp}/frpc
	cron_reboot="5 5 * * 1,5 /sbin/reboot"
	cron_sh="20 * * * * sh $frpc_sh"
	[ $(which curl) ] && startup_cmd="curl $download_sh | sh" || startup_cmd="wget -O /tmp/frpc.sh $download_sh && sh /tmp/frpc.sh"
	grep -q reboot $cron || echo "$cron_reboot" >> $cron
	grep -q "$frpc_sh" $cron || echo "$cron_sh" >> $cron
	grep -q "$download_sh" $startup || echo "$startup_cmd" >> $startup
fi

$frpc -v || download_frpc_fun
[ -f $frpc_ini ] || frpc_ini_fun
[ -x $frpc ] && [ -f $frpc_ini ] || { echo "$frpc or $frpc_ini does not exist !!!" >> $log ; exit ; }

# ------------------------- start frpc ---------------------
ping -c 2 114.114.114.114 && \
  if [ -z "$(pidof $(basename $frpc))" ] ; then
    echo "$(date +"%F %T") $frpc was not runing ; start $frpc ..." >> $log 
    exec $frpc -c $frpc_ini &
  else 
    echo "$(date +"%F %T") $frpc is runing , Don't do anything !" >> $log 
  fi
