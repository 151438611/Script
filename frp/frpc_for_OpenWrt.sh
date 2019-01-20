#!/bin/bash
# support OpenWrt
# 默认frpc连接frps失败10次后,客户端frpc会自动关闭退出;此脚本用于定时检查frpc. 版本: frp_0.21.0
cron="/etc/crontabs/root" ; startup="/etc/rc.local" ; frpc_sh="http://xiongxinyi.cn:2015/tools/frp/frpc.sh"
if [ $(grep -ci "frpc.sh" $startup) -eq 0 ] ; then
  sed -i /^exit/d $startup
  echo "sleep 60 ; wget -P /tmp/ $frpc_sh && mv -f /tmp/frpc.sh /etc/ ; sh /etc/frpc.sh" >> $startup
  echo "exit 0" >> $startup
fi
grep -qi "reboot" $cron || echo "5 5 * * * [ \$(date +%e) = 1 -o \$(date +%e) = 15 ] && reboot || ping -c2 -w5 114.114.114.114 || reboot" >> $cron
grep -qi "frpc.sh" $cron || echo "10 * * * * [ \$(date +%k) -eq 7 ] && killall frpc ; sh /etc/frpc.sh" >> $cron
name=$(uci get system.@system[0].hostname) ; lanip=$(uci get network.lan.ipaddr) && i=$(echo $lanip | cut -d . -f 3)

# -----1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr="" ; token="" ; ssh_remote_port=$(date +1%M%S) ; subdomain="${name:0:2}$i" 
# -----2、是否添加Telnet(远程桌面)、简单的http_file文件服务: 0表示不开启，1表示开启 ; 如果开启后面的参数都需要更改-----
telnet_enable=0 ; if [ $telnet_enable -eq 1 ] ; then telnet_local_ip=192.168.11.10 ; telnet_local_port=23 ; telnet_remote_port=0 ; fi
# -----3、frpc的下载地址、frpcini设置临时配置(默认/tmp/重启自动更新)还是永久保存配置(/etc/storage/，需取消注释#)-----
frpc_url1=http://xiongxinyi.cn:2015/tools/frp/frpc_mips && md5_frpc1=
frpc_url2=http://14.116.146.30:11111/file/frp/frpc_mips && md5_frpc2=
md5_frpc="$md5_frpc1 $md5_frpc2"

frpcini="/tmp/frpc.ini" ; frpc="/tmp/frpc"
#frpcini="/etc/frpc.ini" 

# -------------------------- frpc ----------------------------------------------------
download_frpc() {
  rm -f $frpc ; wget -O $frpc $frpc_url &
  sleep 60 ; killall -q frpc wget curl
  [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc" ] && rm -f $frpc && wget -O $frpc $frpc_url_bak
}
[ -f "$frpc" ] && frpc_md5sum=$(md5sum $frpc | cut -d " " -f 1) && \
[ -n "$(echo "$md5_frpc" | grep ${frpc_md5sum:-null})" ] || download_frpc ; chmod 555 $frpc
# ------------------------- frpc.ini --------------------------------------------------
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
# ----- SSH_port:22 / Telnet_port:23 / Windows_RemoteDesktop_port:3389 -----
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
#custom_domains = 
END
  if [ $telnet_enable -eq 1 ] ; then 
echo -e "# ----- Telnet:23 / RemoteDesktop:3389 Tunnel config ----- " >> $frpcini
echo -e "[telnet] \ntype = tcp \nlocal_ip = $telnet_local_ip " >> $frpcini
echo -e "local_port = $telnet_local_port \nremote_port = $telnet_remote_port " >> $frpcini
echo -e "use_encryption = false \nuse_compression = false \n" >> $frpcini
  fi
fi
ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof frpc)" ] ; then
   $frpc -c $frpcini &
fi
