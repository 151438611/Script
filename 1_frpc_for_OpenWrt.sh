#!/bin/bash
# support OpenWrt
# 默认frpc连接frps失败10次后,客户端frpc会自动关闭退出;此脚本用于定时检查frpc. 版本: frp_0.21.0
cron="/etc/crontabs/root" ; startup="/etc/rc.local" ; frpc_sh="http://xiongxinyi.cn:2015/tools/frp/frpc.sh"
if [ $(grep -c $(basename $0) $startup) -eq 0 ] ; then
  sed -i /^exit/d $startup
  echo "sleep 40 ; wget -P /tmp/ $frpc_sh && mv -f /tmp/frpc.sh /etc/ ; sh /etc/frpc.sh" >> $startup
  echo "exit 0" >> $startup
fi
grep -qi reboot $cron || echo "5 5 * * * [ -n \"\$(date +%d | grep -E \"10|20|28\")\" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot" >> $cron
grep -qi $(basename $0) $cron || echo "10 * * * * [ \$(date +%k) -eq 6 ] && killall -q frpc ; sh /etc/frpc.sh" >> $cron
name=$(uci get system.@system[0].hostname) ; lanip=$(uci get network.lan.ipaddr) && i=$(echo $lanip | cut -d . -f 3)

# -----1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr="frp.xiongxinyi.cn" ; token="administrator"  ; subdomain="${name:0:2}$i" 
# -----2、frpc的下载地址、frpcini设置临时配置(默认/tmp/重启自动更新)还是永久保存配置(/etc/storage/，需取消注释#)-----
frpc_url1=http://14.116.146.30:11111/file/frp/frpc_linux_mips && md5_frpc1=756a5320f75b98b12f5bea1846f8d3fa
frpc_url2=http://14.116.146.30:12222/file/frp/frpc_linux_mips && md5_frpc2=756a5320f75b98b12f5bea1846f8d3fa
md5_frpc="$md5_frpc1 $md5_frpc2"

frpcini="/tmp/frpc.ini" ; frpc="/tmp/frpc"
frpcini="/etc/frpc.ini" 

# -------------------------- frpc ----------------------------------------------------
download_frpc() {
  rm -f $frpc ; wget -O $frpc $frpc_url1 &
  sleep 60 ; killall -q frpc wget
  [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc1" ] && rm -f $frpc && wget -O $frpc $frpc_url2
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
use_encryption = false
use_compression = false
END
fi

ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof frpc)" ] ; then
   $frpc -c $frpcini &
fi
