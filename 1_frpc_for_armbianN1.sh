#!/bin/sh
#
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

cron=/var/spool/cron/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n15 * * * * [ \$(date +\\%k) -eq 5 ] && /usr/bin/killall frpc ; sleep 8 && sh /opt/frp/$(basename $0)" >> $cron
grep -qi reboot $cron || echo -e "\n5 5 * * * [ \$(date +\\%u) -eq 6 ] && /sbin/reboot" >> $cron

# -----1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr=frp.xiongxinyi.cn ; token=administrator
name=armbian_N1 ; subdomain=kodexplorer

frpc=/opt/frp/frpc ; frpcini=/opt/frp/frpc.ini
frpc_url=http://14.116.146.30:11111/file/frp/frpc_linux_arm64 && md5_frpc=1610d1011fece9d806c8e3ba5dd2ad8f

ttyd=/opt/ttyd ; ttyd_url=http://14.116.146.30:11111/file/frp/ttyd_linux.aarch64
if [ -z $(pidof ttyd) ] ; then
  [ -f "$ttyd" ] || wget -O $ttyd $ttyd_url ; chmod 555 $ttyd
  $ttyd -p 5000 -m 5 -d 1 /bin/login &
fi

download_frpc() {
  rm -f $frpc ; wget -O $frpc $frpc_url &
  sleep 60 ; killall -q wget
}
[ "$(md5sum $frpc | cut -d " " -f 1)" = "$md5_frpc" ] || download_frpc ; chmod 555 $frpc

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
# ----- SSH_port:22 / Telnet_port:23 / RemoteDesktop_port:3389 -----
[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = false
use_compression = true
# ------------ http Tunnel config ------------
[$subdomain]
type = tcp
local_ip = 127.0.0.1
local_port = 80
remote_port = 0
use_encryption = false
use_compression = true
END
fi

ip_addr=$(ifconfig eth0 | awk '/inet/ && /netmask/ && /broadcast/{print $2}')
old_addr=$(awk '$0~"local_ip = 192.168" {print $3}' $frpcini | head -n1)
[ -n "$ip_addr" -a -n "$old_addr" ] && [ "$ip_addr" != "$old_addr" ] && sed -i 's/'"$old_addr"'/'"$ip_addr"'/g' $frpcini

if [ -z "$(pidof frpc)" ] ; then
  $frpc -c $frpcini &
  echo "$(date +"%F %T") frpc was not runing ; start frpc ..." >> /tmp/frpc.log
else
  echo "$(date +"%F %T") frpc is runing, Don't do anything !" >> /tmp/frpc.log
fi

