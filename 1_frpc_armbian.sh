#!/bin/bash
# for aarch64/arm64 and amd64/x86_64
# Armbian中crontab $PATH=/usr/bin:/bin
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
frpclog=/tmp/frpc.log
[ -f $frpclog ] || echo $(date +"%F %T") > $frpclog

# 添加计划任务： 
# 5 5 * * * [ $(date +\%u) -eq 6 ] && /sbin/reboot
# 20 * * * * [ $(date +\%k) -eq 5 ] && killall -q frpc ; sleep 8 && bash /opt/frpc/frpc.sh

# ----- 填写服务端的IP/域名、端口号、认证密码 ---------------------------
server_addr=x.x.x.x
token=xx
server_port=7000
name=10gtek_n1

frpc=/opt/frpc/frpc
frpcini=/opt/frpc/frpc.ini
frpc_name=${frpc##*/}

ttyd=/opt/frpc/ttyd
ttyd_port=7800

base_arch=$(uname -m)
case $base_arch in
	x86_64)
		frpc_url="http://frp2.xiongxinyi.cn:37511/file/frp/frpc_linux_amd64"
		ttyd_url="http://frp2.xiongxinyi.cn:37511/file/frp/ttyd_linux.x86_64"
	;;
	aarch64)
		frpc_url="http://frp2.xiongxinyi.cn:37511/file/frp/frpc_linux_arm64"
		ttyd_url="http://frp2.xiongxinyi.cn:37511/file/frp/ttyd_linux.aarch64"
	;;
	mips)
		frpc_url="http://frp2.xiongxinyi.cn:37511/file/frp/frpc_linux_mipsle"
		ttyd_url="http://frp2.xiongxinyi.cn:37511/file/frp/ttyd_linux.mipsle"
	;;
esac

if [ -z "$(pidof ${ttyd##*/})" ] ; then
  [ -z "$($ttyd -v)" ] && rm -f $ttyd && wget -c -O $ttyd $ttyd_url
  chmod 555 $ttyd
  $ttyd -p $ttyd_port -m 5 -d 0 /bin/login &
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
user = $name
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
END
fi

ping -c2 -w5 114.114.114.114 && \
  if [ -z "$(pidof $frpc_name)" ] ; then
    echo "$(date +"%F %T") $frpc_name was not runing ; start $frpc_name ..." >> $frpclog
    exec $frpc -c $frpcini &
  else
    echo "$(date +"%F %T") $frpc_name is runing, Don't do anything !" >> $frpclog
  fi
