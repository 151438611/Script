#!/bin/sh
# for K3_root , ARM cpu
# ----无时间测试，暂无法使用---停用
user_name=$(nvram get http_username)
crontab=/etc/crontabs/$user_name
frpc_name=$(basename $0)
frpc_sh=http://frp.xiongxinyi.cn:11111/file/frp/frpc_k3root.sh

startup_frpc="sleep 50 ; wget -P /tmp/ $frpc_sh && mv -f /tmp/$(basename $frpc_sh) /opt/$frpc_name ; sh /opt/$frpc_name"
grep -qi "$frpc_name" /opt/started_script.sh || echo "$startup_frpc" >> /opt/started_script.sh
cron_reboot="5 5 * * * [ -n \"\$(date +%d | grep 5)\" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot"
grep -qi "reboot" $crontab || echo "$cron_reboot" >> $crontab
cron_frpc="15 * * * * [ \$(date +%k) -eq 5 ] && killall -q frpc ; sh /opt/$frpc_name"
grep -qi "$frpc_name" $crontab || echo "$cron_frpc" >> $crontab

lanip=$(nvram get lan_ipaddr) && i=$(echo $lanip | cut -d . -f 3)
host_name=$(nvram get product)
# ----- 1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr="frp.xiongxinyi.cn"
token="administrator"
subdomain=${host_name}$i

# ----- 2、frpc的下载地址、frpcini设置临时配置(默认/tmp/)还是永久保存配置(/etc/)----------------
frpc_url1="http://frp.xiongxinyi.cn:11111/file/frp/frpc_linux_arm" && md5_frpc1="af0e1a938ba6ddb62fe72bad8dc0a1eb"
frpc_url2="http://frp.xiongxinyi.cn:12222/file/frp/frpc_linux_arm" && md5_frpc2="af0e1a938ba6ddb62fe72bad8dc0a1eb"
md5_frpc="$md5_frpc1 $md5_frpc2"
frpc="/opt/frpc" && frpc_name=${frpc##*/}
frpcini="/opt/frpc.ini" 

download_frpc() {
  killall -q $frpc_name
  rm -f $frpc
  wget -O $frpc $frpc_url1 &
  sleep 60 ; killall -q wget
  [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc" ] && rm -f $frpc && wget -O $frpc $frpc_url2
}
frpc_md5sum=$(md5sum $frpc | cut -d " " -f 1)
[ -n "$(echo "$md5_frpc" | grep ${frpc_md5sum:-null})" ] || download_frpc
chmod 755 $frpc 

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
admin_addr = 0.0.0.0
admin_port = 7400
admin_user = admin
admin_pwd = admin
#log_file = $frpclog
#log_max_days = 3
log_level = warn

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
