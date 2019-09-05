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
frpclog=/tmp/frpc.log
[ -f $frpclog ] || echo $(date +"%F %T") > $frpclog
download_url=http://frp2.xiongxinyi.cn:37511/file/

# ------------------------- add crontab、startup、enable SSH -----------------------
bin_dir=/etc/storage/bin
[ -d "$bin_dir" ] || mkdir -p $bin_dir
sh_name=$(basename $0)
user_name=$(nvram get http_username)
cron=/etc/storage/cron/crontabs/$user_name
startup=/etc/storage/started_script.sh
sh_url=${download_url}frp/frpc_padavan.sh

cron_reboot="5 5 * * * [ -n \"\$(date +%d | grep 5)\" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot"
grep -qi "reboot" $cron || echo "$cron_reboot" >> $cron
cron_sh="20 * * * * /bin/bash $bin_dir/$sh_name"
grep -qi $sh_name $cron || echo "$cron_sh" >> $cron
startup_sh="sleep 30 ; wget -P /tmp $sh_url && mv -f /tmp/$(basename $sh_url) $bin_dir/$sh_name ; sh $bin_dir/$sh_name"
grep -qi $sh_name $startup || echo "$startup_sh" >> $startup

# 开启从wan口访问路由器和ssh服务(默认关闭)，即从上级路由直接访问下级路由或ssh服务
#[ $(nvram get misc_http_x) -eq 0 ] && nvram set misc_http_x=1 && nvram set misc_httpport_x=80 && nvram commit
[ $(nvram get sshd_wopen) -eq 0 ] && nvram set sshd_wopen=1 && nvram set sshd_wport=22 && nvram commit
[ $(nvram get sshd_enable) -eq 0 ] && nvram set sshd_enable=1 && nvram commit

# ----- 填写服务端的IP/域名、认证密码即可-----------------------------------
server_addr=x.x.x.x
token=xxx
server_port=7000
# ----- 是否开启ttyd(web_ssh)、Telnet(或远程桌面)、简单的http_file文件服务; 0表示不开启，1表示开启 -----
ttyd_enable=0
if [ $ttyd_enable -eq 1 ]; then ttyd=/tmp/ttyd; ttyd_port=7800; fi 

# ----- ttyd、frpc的下载地址、frpcini设置临时配置(默认/tmp/)还是永久保存配置(/etc/storage/) ------
ttyd_url=${download_url}frp/ttyd_linux.mipsel
frpc_url1=${download_url}frp/frpc_linux_mipsle
frpc_url2=http://opt.cn2qq.com/opt-file/frpc

udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
udisk=${udisk:=/tmp}
frpc=$udisk/frpc && frpc_name=${frpc##*/}
frpcini=$bin_dir/frpc.ini

# -------------------------- ttyd -----------------------------
download_ttyd() {
  killall -q ttyd
  rm -f $ttyd
  wget -c -O $ttyd $ttyd_url
  chmod +x $ttyd
}
if [ $ttyd_enable -eq 1 ] ; then 
  [ -f $ttyd ] || download_ttyd
  if [ -z "$(pidof ttyd)" ] ; then
      $ttyd -p $ttyd_port -m 3 -d 0 /bin/login &
  fi
fi

# -------------------------- frpc -----------------------------
download_frpc() {
  killall -q $frpc_name
  rm -f $frpc
  wget -c -O $frpc $frpc_url1 &
  sleep 60
  killall -q wget
  chmod +x $frpc
  frpc_ver=$($frpc -v)
  if [ -z "$frpc_ver" ]; then
    wget -c -O $frpc $frpc_url &
    sleep 60
    killall -q wget
    frpc_ver=$($frpc -v)
    if [ -z "$frpc_ver" ]; then
      rm -f $frpc
      wget -c -O $frpc $frpc_url2
    fi
  fi 
}
 $frpc -v || download_frpc
chmod +x $frpc

# ------------------------- frpc.ini -------------------------
if [ ! -f "$frpcini" ]; then
  lanip=$(nvram get lan_ipaddr) && i=$(echo $lanip | cut -d . -f 3)
  host_name=$(nvram get computer_name)
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

[ $ttyd_enable -eq 1 ] && \
cat << END >> $frpcini
[ttyd]
type = tcp
local_ip = 127.0.0.1
local_port = $ttyd_port
remote_port = 0
END

fi
# ------------------------- start frpc ---------------------
ping -c2 -w5 114.114.114.114 && \
  if [ -z "$(pidof $frpc_name)" ] ; then
    echo "$(date +"%F %T") $frpc_name was not runing ; start $frpc_name ..." >> $frpclog
    exec $frpc -c $frpcini &
  else 
    echo "$(date +"%F %T") $frpc_name is runing , Don't do anything !" >> $frpclog
  fi

