#!/bin/sh
# for K3_root , ARM cpu
user_name=$(nvram get http_username) ; crontab=/etc/crontabs/$user_name
frpc_sh=http://14.116.146.30:11111/file/frp/frpc_K3root.sh ; frpc_name=$(basename $0)
startup_frpc="sleep 50 ; wget -P /tmp/ $frpc_sh && mv -f /tmp/$(basename $frpc_sh) /opt/$frpc_name ; sh /opt/$frpc_name"
grep -qi "$frpc_name" /opt/started_script.sh || echo "$startup_frpc" >> /opt/started_script.sh

cron_reboot="5 5 * * * [ -n \"\$(date +%d | grep 5)\" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot"
grep -qi "reboot" $crontab || echo "$cron_reboot" >> $crontab

cron_frpc="15 * * * * [ \$(date +%k) -eq 5 ] && killall -q frpc ; sh /opt/$frpc_name"
grep -qi "$frpc_name" $crontab || echo "$cron_frpc" >> $crontab

host_name=$(nvram get product)
lanip=$(nvram get lan_ipaddr) && i=$(echo $lanip | cut -d . -f 3)

# ----- 1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr=frp.xiongxinyi.cn ; token=administrator ; subdomain=$host_name$i

# ----- 2、frpc的下载地址、frpcini设置临时配置(默认/tmp/)还是永久保存配置(/etc/)----------------
frpc_url1=http://14.116.146.30:11111/file/frp/frpc_linux_arm && md5_frpc1=cf0ec5bc1e22acff89ce8363cf2d2880
frpc_url2=http://14.116.146.30:12222/file/frp/frpc_linux_arm && md5_frpc2=cf0ec5bc1e22acff89ce8363cf2d2880
md5_frpc="$md5_frpc1 $md5_frpc2 "
frpc=/opt/frpc ; frpcini="/opt/frpc.ini" 

#echo -------------------------- frpc ---------------------------------------------------
download_frpc() {
  rm -f $frpc ; wget -O $frpc $frpc_url1 &
  sleep 60 ; killall -q frpc wget
  [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc" ] && rm -f $frpc && wget -O $frpc $frpc_url2
}
frpc_md5sum=$(md5sum $frpc | cut -d " " -f 1)
[ -n "$(echo "$md5_frpc" | grep ${frpc_md5sum:-null})" ] || download_frpc
chmod 755 $frpc 
#echo ------------------------- frpc.ini --------------------------------
if [ ! -f "$frpcini" ] ; then
cat << END > $frpcini
[common]
server_addr = $server_addr
server_port = 7000
protocol = tcp
token = $token
user = $host_name
pool_count = 8
tcp_mux = true
login_fail_exit = true
# ----- SSH:22 Telnet:23 RemoteDesktop:3389 VNC:5900 -----
[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = $ssh_port
use_encryption = false
use_compression = true

[$subdomain]
type = tcp
local_ip = $lanip
local_port = 22
remote_port = $ssh_port
use_encryption = false
use_compression = true
END
fi
#echo ------------------------- start frpc ----------------------
ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof frpc)" ] ; then
      logger -t frpc "frpc is not running ; starting frpc......"
      $frpc -c $frpcini &
else  logger -t frpc "frpc is running ; Don't do everything !"
fi
