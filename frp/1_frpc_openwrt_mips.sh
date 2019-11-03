#!/bin/bash
#################################################################
# FILE NAME: frpc.sh
# DESCRIPTION: frpc for Padavan
# MODIFICATION HISTORY:
# NAME		  DATE	    Description
# ========	========  ===========================================
# Jun	      20180808  Created.
#################################################################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

download_url="http://frp.xiongxinyi.cn:30100/file/"
log=/tmp/frpc.log
[ -f $log ] || echo $(date +"%F %T") > $log

# ------------------------- add crontab、startup、enable SSH -----------------------
bin_dir=/etc
[ -d "$bin_dir" ] || mkdir -p $bin_dir
sh_name=$(basename $0)
cron=/etc/crontabs/root
startup=/etc/rc.local
sh_url=${download_url}frp/frpc_openwrt_mips.sh

cron_reboot="5 5 * * * ping -c2 -w5 114.114.114.114 || /sbin/reboot"
grep -qi "reboot" $cron || echo "$cron_reboot" >> $cron
cron_sh="20 * * * * sh $bin_dir/$sh_name"
grep -qi $sh_name $cron || echo "$cron_sh" >> $cron
startup_sh="sleep 30 ; wget -P /tmp $sh_url && mv -f /tmp/$(basename $sh_url) $bin_dir/$sh_name ; sh $bin_dir/$sh_name"
grep -qi $sh_name $startup || echo "$startup_sh" >> $startup

# 开启从wan口访问路由器和ssh服务(默认关闭)，即从上级路由直接访问下级路由或ssh服务
[ "$(uci get firewall.@defaults[0].input)" != ACCEPT ] && uci set firewall.@defaults[0].input=ACCEPT && uci commit firewall

# ----- 填写服务端的IP/域名、认证密码即可-----------------------------------
server_addr=x.x.x.x
token=xxx
server_port=7000

# ----- ttyd、frpc的下载地址、frpcini设置临时配置(默认/tmp/)还是永久保存配置(/etc/storage/) ------
frpc_url1=${download_url}frp/frpc_linux_mips

udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
udisk=${udisk:=/tmp}
frpc=$udisk/frpc && frpc_name=${frpc##*/}
frpcini=$bin_dir/frpc.ini

# -------------------------- frpc -----------------------------
download_frpc() {
  killall -q $frpc_name
  rm -f $frpc
  wget -c -t 3 -T 10 -O $frpc $frpc_url1 &
  chmod +x $frpc
  if [ -z "$($frpc -v)" ]; then
    rm -f $frpc
    wget -c -t 3 -T 10 -O $frpc $frpc_url2
  fi 
}
 $frpc -v || download_frpc
chmod +x $frpc

# ------------------------- frpc.ini -------------------------
if [ ! -f "$frpcini" ]; then
  lanip=$(uci get network.lan.ipaddr) && i=$(echo $lanip | cut -d . -f 3)
  host_name=$(uci get system.@system[0].hostname)
  subdomain=${host_name}$i
cat << END > $frpcini
[common]
server_addr = $server_addr
server_port = $server_port
token = $token
user = $host_name
protocol = tcp
pool_count = 8
admin_addr = 127.0.0.1
admin_port = 7400
admin_user = admin
admin_pwd = admin
log_level = error
#log_max_days = 3
#log_file = $frpclog
tcp_mux = true
login_fail_exit = true

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = false
use_compression = false

[$subdomain]
type = tcp
local_ip = $lanip
local_port = 80
remote_port = 0
END

fi
# ------------------------- start frpc ---------------------
ping -c2 -w5 114.114.114.114 && \
  if [ -z "$(pidof $frpc_name)" ] ; then
    echo "$(date +"%F %T") $frpc_name was not runing ; start $frpc_name ..." >> $log
    exec $frpc -c $frpcini &
  else 
    echo "$(date +"%F %T") $frpc_name is runing , Don't do anything !" >> $log
  fi

