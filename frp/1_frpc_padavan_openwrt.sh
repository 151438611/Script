#!/bin/sh
#################################################################
# FILE NAME: frpc.sh
# DESCRIPTION: support ARM64、X86_64、Padavan_mipsle(K2、K2P、YoukuL1)、Openwrt_mips(TP-Link WR941v6、WR841v7还未测试) Linux
#				Padavan和Openwrt系统可自动下载frpc和创建默认的frpc.ini，建议事先创建frpc.ini配置文件
# MODIFICATION HISTORY:
# NAME		DATE	  Description
# ========	========  ===========================================
# Jun		20200314  Created
#################################################################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
main_url="http://frp.xxy1.ltd:35100/file/frp/"
main_url_bak="http://frp.xxy1.ltd:35300/file/frp/"

# ----- 1、填写服务端的IP/域名、认证密码 -----------------------
server_addr=frp.xxy1.ltd
server_port=7777
token=xxxx
user_name=
[ "$user_name" ] || user_name=frpc_$(md5sum /proc/meminfo | cut -c 1-4)

grep -qi padavan /proc/version && os_version=Padavan
grep -qEi "openwrt|lede" /proc/version && os_version=Openwrt

log_fun() {
	log=/tmp/${frpc##*/}.log
	[ -f $log ] || echo $(date +"%F %T") > $log
	[ "$1" ] && echo "$1" >> $log
}
download_frpc_fun() {
	killall -q ${frpc##*/}
	rm -f $frpc
	wget -c -t 2 -T 10 -O $frpc $download_frpc || wget -c -t 2 -T 10 -O $frpc $download_frpc_b
	chmod +x $frpc
	[ "$($frpc -v)" ] || {
		rm -f $frpc
		wget -c -t 2 -T 10 -O $frpc $download_frpc_bak
		chmod +x $frpc
	}
}

frpc_ini_fun() {
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

if [ $os_version = Padavan -a $(uname -m) = mips ]; then
	download_sh="${main_url}frpc_padavan.sh"
	download_frpc="${main_url}frpc_linux_mipsle"
	download_frpc_bak="http://opt.cn2qq.com/opt-file/frpc"
	download_frpc_b="${main_url_bak}frpc_linux_mipsle"

	udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
	frpc=${udisk:=/tmp}/frpc
	frpc_ini=/etc/storage/bin/frpc.ini
	frpc_sh=/etc/storage/bin/frpc.sh
	
	cron=/etc/storage/cron/crontabs/$(nvram get http_username)
	startup=/etc/storage/started_script.sh

	# 开启从wan口访问路由器和ssh服务(默认关闭)，即从上级路由直接访问下级路由或ssh服务
	#[ $(nvram get misc_http_x) -eq 0 ] && nvram set misc_http_x=1 && nvram set misc_httpport_x=80 && nvram commit
	[ $(nvram get sshd_wopen) -eq 0 ] && nvram set sshd_wopen=1 && nvram set sshd_wport=22 && nvram commit
	[ $(nvram get sshd_enable) -eq 0 ] && nvram set sshd_enable=1 && nvram commit
elif [ $os_version = Openwrt -a $(uname -m) = mips ]; then
	# 暂时没有投入使用 --- 此功能待以后有需求时再修改
	download_sh="${main_url}frpc_openwrt_mips.sh"
	download_frpc="${main_url}frpc_linux_mips"
	download_frpc_bak="${main_url_bak}frpc_linux_mips"
	
	udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
	frpc=${udisk:=/tmp}/frpc
	frpc_ini=/etc/frpc.ini
	frpc_sh=/etc/frpc.sh

	cron=/etc/crontabs/root
	startup=/etc/rc.local

elif [ $(uname -m) = aarch64 -o $(uname -m) = x86_64 ]; then
	frpc=/opt/frp/frpc
	frpc_ini=/opt/frp/frpc.ini
	[ -x $frpc -a -f $frpc_ini ] || { log_fun "$frpc or $frpc_ini does not exist !!!"; exit; }
else 
	log_fun "!!! Router or OS is Unsupported device , exit !!!"
	exit
fi

if [ "$os_version" = Padavan -o "$os_version" = Openwrt ]; then
	cron_reboot="5 5 * * * [ \$(date +%u) -eq 1 ] && /sbin/reboot || ping -c2 -w5 114.114.114.114 || /sbin/reboot"
	cron_sh="20 * * * * sh $frpc_sh"
	startup_cmd="wget -O /tmp/frpc.sh $download_sh && sh /tmp/frpc.sh"
	grep -q reboot $cron || echo "$cron_reboot" >> $cron
	grep -q "$frpc_sh" $cron || echo "$cron_sh" >> $cron
	grep -q "$download_sh" $startup || echo "$startup_cmd" >> $startup
fi

$frpc -v || download_frpc_fun
[ -f $frpc_ini ] || frpc_ini_fun
[ -x $frpc ] && [ -f $frpc_ini ] || { log_fun "$frpc or $frpc_ini does not exist !!!"; exit; }

# ------------------------- start frpc ---------------------
ping -c2 -w5 114.114.114.114 && \
  if [ -z "$(pidof ${frpc##*/})" ]; then
    log_fun "$(date +"%F %T") $frpc was not runing ; start $frpc ..."
    exec $frpc -c $frpc_ini &
  else 
    log_fun "$(date +"%F %T") $frpc is runing , Don't do anything !" 
  fi

