#!/bin/bash
# for Armbian N1
# Armbian中crontab $PATH=/usr/bin:/bin
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
frpclog=/tmp/frpc.log
[ -f $frpclog ] || echo $(date +"%F %T") > $frpclog

cron=/var/spool/cron/crontabs/root
grep -qi reboot $cron || echo -e "\n5 5 * * * [ \$(date +\\%u) -eq 6 ] && /sbin/reboot" >> $cron
cron_frpc="15 * * * * [ \$(date +\\%k) -eq 5 ] && killall -q frpc ; sleep 8 && sh /opt/frpc/$(basename $0)"
grep -qi $(basename $0) $cron || echo -e "\n$cron_frpc" >> $cron

# ----- 填写服务端的IP/域名、端口号、认证密码 ---------------------------
server_addr=x.x.x.x
token=xx
server_port=7000
name=10gtek_n1

frpc=/opt/frpc/frpc && frpc_name=${frpc##*/}
frpcini=/opt/frpc/frpc.ini
frpc_url=http://frp2.xiongxinyi.cn:37511/file/frp/frpc_linux_arm64

ttyd=/opt/frpc/ttyd
ttyd_port=7800
ttyd_url=http://frp2.xiongxinyi.cn:37511/file/frp/ttyd_linux.aarch64

if [ -z "$(pidof ${ttyd##*/})" ] ; then
  [ -z "$($ttyd -v)" ] && rm -f $ttyd && wget -c -O $ttyd $ttyd_url
  chmod 555 $ttyd
  $ttyd -p $ttyd_port -m 5 -d 1 /bin/login &
fi

download_frpc() {
  killall -q $frpc_name
  rm -f $frpc
  wget -c -O $frpc $frpc_url &
  sleep 60
  killall -q wget
}
$frpc -v || download_frpc
chmod 555 $frpc

if [ ! -f "$frpcini" ] ; then
cat << END > $frpcini
[common]
server_addr = $server_addr
server_port = $server_port
token = $token

protocol = tcp
user = $name
pool_count = 8
tcp_mux = true
login_fail_exit = true

admin_addr = 127.0.0.1
admin_port = 7400
admin_user = admin
admin_pwd = admin
#log_file = $frpclog
#log_max_days = 3
log_level = error

# --- SSH_port:22 Telnet_port:23 RemoteDesktop_port:3389 VNC:5900 ---
[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = false
use_compression = false

END
fi

ping -c2 -w5 114.114.114.114 && \
  if [ -z "$(pidof $frpc_name)" ] ; then
    echo "$(date +"%F %T") $frpc_name was not runing ; start $frpc_name ..." >> $frpclog
    exec $frpc -c $frpcini &
  else
    echo "$(date +"%F %T") $frpc_name is runing, Don't do anything !" >> $frpclog
  fi
