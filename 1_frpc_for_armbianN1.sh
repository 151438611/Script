#!/bin/sh
#
# armbian中crontab $PATH=/usr/bin:/bin
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
frpclog=/tmp/frpc.log ; [ -f $frpclog ] || echo $(date +"%F %T") > $frpclog

cron=/var/spool/cron/crontabs/root
grep -qi reboot $cron || echo -e "\n5 5 * * * [ \$(date +\\%u) -eq 6 ] && /sbin/reboot" >> $cron
cron_frpc="15 * * * * [ \$(date +\\%k) -eq 5 ] && killall -q frpc ; sleep 8 && sh /opt/frp/$(basename $0)"
grep -qi $(basename $0) $cron || echo -e "\n$cron_frpc" >> $cron

# -----1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr="frp.xiongxinyi.cn"
token="administrator"
name="10gtek_n1"
subdomain="kodexplorer"

frpc="/opt/frp/frpc"
frpcini="/opt/frp/frpc.ini"
frpc_url="http://frp.xiongxinyi.cn:11111/file/frp/frpc_linux_arm64 && md5_frpc1=291c0207eb0e0a8d7bab963963a63326"

ttyd="/opt/frp/ttyd"
ttyd_url="http://frp.xiongxinyi.cn:11111/file/frp/ttyd_linux.aarch64"
if [ -z "$(pidof ttyd)" ] ; then
  [ -f "$ttyd" ] || wget -O $ttyd $ttyd_url
  chmod 755 $ttyd
  $ttyd -p 7682 -m 5 -d 1 /bin/login &
fi

download_frpc() {
  rm -f $frpc
  wget -O $frpc $frpc_url &
  sleep 60 ; killall -q wget
}
[ "$(md5sum $frpc | cut -d " " -f 1)" = "$md5_frpc1" ] || download_frpc
chmod 755 $frpc

if [ ! -f "$frpcini" ] ; then
cat << END > $frpcini
[common]
server_addr = $server_addr
server_port = 7000
protocol = tcp
token = $token
user = $name
pool_count = 8
tcp_mux = true
login_fail_exit = true

admin_addr = 0.0.0.0
admin_port = 7400
admin_user = admin
admin_pwd = admin
#log_file = $frpclog
#log_max_days = 3
log_level = warn

# --- SSH_port:22 / Telnet_port:23 / RemoteDesktop_port:3389 / VNC:5900 ---
[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = false
use_compression = true

[$subdomain]
type = tcp
local_ip = 127.0.0.1
local_port = 80
remote_port = 0
use_encryption = false
use_compression = true
END
fi

ping -c2 -w5 114.114.114.114 && \
  if [ -z "$(pidof ${frpc##*/})" ] ; then
    echo "$(date +"%F %T") frpc was not runing ; start frpc ..." >> $frpclog
    exec $frpc -c $frpcini &
  else
    echo "$(date +"%F %T") frpc is runing, Don't do anything !" >> $frpclog
  fi
