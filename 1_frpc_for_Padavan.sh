#!/bin/sh
# for Padavan
# ------------------------- add crontab、startup、enable SSH -----------------------
bin_dir="/etc/storage/bin" ; [ -d "$bin_dir" ] || mkdir -p $bin_dir
user_name=$(nvram get http_username)
cron="/etc/storage/cron/crontabs/$user_name"
startup="/etc/storage/started_script.sh" ; 
frpc_sh="http://14.116.146.30:11111/file/frp/frpc_padavan.sh"

cron_reboot="5 5 * * * [ -n \"\$(date +%d | grep 5)\" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot"
grep -qi "reboot" $cron || echo -e "\n$cron_reboot" >> $cron

cron_frpc="20 * * * * [ \$(date +%k) -eq 5 ] && killall -q frpc ; sleep 8 && sh $bin_dir/$(basename $0)"
grep -qi $(basename $0) $cron || echo -e "\n$cron_frpc" >> $cron

startup_frpc="sleep 30 ; wget -P /tmp/ $frpc_sh && mv -f /tmp/$(basename $frpc_sh) $bin_dir/$(basename $0) ; sh $bin_dir/$(basename $0)"
grep -qi $(basename $0) $startup || echo -e "\n$startup_frpc" >> $startup

# 开启从wan口访问路由器和ssh服务(默认关闭)，即从上级路由直接访问下级路由或ssh服务
#[ $(nvram get misc_http_x) -eq 0 ] && nvram set misc_http_x=1 && nvram set misc_httpport_x=80 && nvram commit
[ $(nvram get sshd_wopen) -eq 0 ] && nvram set sshd_wopen=1 && nvram set sshd_wport=22 && nvram commit
[ $(nvram get sshd_enable) -eq 0 ] && nvram set sshd_enable=1 && nvram commit
host_name=$(nvram get computer_name)
lanip=$(nvram get lan_ipaddr) && i=$(echo $lanip | cut -d . -f 3)
udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1) ; udisk=${udisk:=/tmp}

# -----1、填写服务端的IP/域名、认证密码即可---------------------------
server_addr="frp.xiongxinyi.cn" ; token="administrator"  ; subdomain="${host_name:0:2}$i"

# -----2、是否开启ttyd(web_ssh)、Telnet(或远程桌面)、简单的http_file文件服务; 0表示不开启，1表示开启 ------------
ttyd_enable=0
if [ $ttyd_enable -eq 1 ] ; then ttyd_local_port=7682 ; fi 
http_file_enable=0
if [ $http_file_enable -eq 1 ] ; then http_file_path=$udisk ; http_file_port=$(date +1%M%S) ; fi

# -----3、ttyd、frpc的下载地址、frpcini设置临时配置(默认/tmp/)还是永久保存配置(/etc/storage/)----------------
ttyd_url="http://14.116.146.30:11111/file/frp/ttyd_linux_mipsle"  && md5_ttyd=d1484e8e97adf6c2ca9cc1067c9cded6
frpc_url1="http://14.116.146.30:11111/file/frp/frpc_linux_mipsle" && md5_frpc1=2bced9b3084f251b3fd2ca42cc472f6c
frpc_url2="http://14.116.146.30:12222/file/frp/frpc_linux_mipsle" && md5_frpc2=2bced9b3084f251b3fd2ca42cc472f6c
frpc_url3="http://opt.cn2qq.com/opt-file/frpc" && md5_frpc3=964c16fbe3edaa12674cee9b1c41f0f0
md5_frpc="$md5_frpc1 $md5_frpc2 $md5_frpc3 df4538b0ccd828457af33b2e599ea87a"
frpc="$udisk/frpc" ; frpcini="$bin_dir/frpc.ini" 

# -------------------------- ttyd ----------------------------------------
download_ttyd() {
  killall -q ttyd ; rm -f $ttyd
  wget -O $ttyd $ttyd_url
  chmod 755 $ttyd
}
if [ $ttyd_enable -eq 1 ] ; then 
  ttyd=$(which ttyd) ; [ ! -x "${ttyd:=$bin_dir/ttyd}" ] && download_ttyd
  if [ -z "$(pidof ttyd)" ] ; then
      $ttyd -p $ttyd_local_port -r 10 -m 3 -d 1 /bin/login &
  fi
fi
# -------------------------- frpc -----------------------------------------
download_frpc() {
  rm -f $frpc ; wget -O $frpc $frpc_url1 &
  sleep 60 ; killall -q frpc wget
  if [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc1" ] ; then
    rm -f $frpc ; wget -O $frpc $frpc_url2 &
    sleep 60 ; killall -q wget
    if [ "$(md5sum $frpc | cut -d " " -f 1)" != "$md5_frpc2" ] ; then
      rm -f $frpc ; wget -O $frpc $frpc_url3
    fi
  fi 
}

frpc_md5sum=$(md5sum $frpc | cut -d " " -f 1)
[ -n "$(echo "$md5_frpc" | grep ${frpc_md5sum:-null})" ] || download_frpc
chmod 755 $frpc
# ------------------------- frpc.ini -----------------------------------
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
# ----- SSH:22 Telnet:23 RemoteDesktop:3389 VNC:5900 -----
[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = false
use_compression = true
# ---------------- http Tunnel config -------------------- 
[$subdomain]
type = tcp
local_ip = $lanip
local_port = 80
remote_port = 0
use_encryption = false
use_compression = true
END

  if [ $ttyd_enable -eq 1 ] ; then 
echo -e "[ttyd] \ntype = tcp \nlocal_ip = 127.0.0.1 " >> $frpcini
echo -e "local_port = $ttyd_local_port \nremote_port = 0 " >> $frpcini
echo -e "use_encryption = false \nuse_compression = true \n" >> $frpcini
  fi 
  if [ $http_file_enable -eq 1 ] ; then
echo -e "# ----- http_file Tunnel config --- use:http://x.x.x.x:file_port/file/ ----- " >> $frpcini
echo -e "[http_file] \ntype = tcp \nremote_port = $http_file_port \nplugin = static_file " >> $frpcini
echo -e "plugin_local_path = $http_file_path \nplugin_strip_prefix = file " >> $frpcini
echo -e "plugin_http_user = \nplugin_http_passwd = \n" >> $frpcini
  fi
fi
# ------------------------- start frpc ---------------------------------
ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof frpc)" ] ; then
     logger -t frpc "frpc is not running ; starting frpc......"
     $frpc -c $frpcini &
else logger -t frpc "frpc is running ; Don't do anything !"
fi
