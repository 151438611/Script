#!/bin/sh
# for Padavan ,support filebrowser 2.0.x
# FileBrowser v2.0.x 使用方法
#1 ./filebrowser -d ./filebrowser.db config init  初始化数据库配置文件
#2 ./filebrowser -d ./filebrowser.db config set -p 2019 -l /tmp/filebrowser.log
#3 ./filebrowser -d ./filebrowser.db users add username passwd --perm.admin  添加管理员帐号
#4 ./filebrowser -d ./filebrowser.db &  后台启动软件

cron=/etc/storage/cron/crontabs/admin
startup=/etc/storage/started_script.sh
grep -qi $(basename $0) $startup || echo "sh /etc/storage/bin/$(basename $0)" >> $startup

cron_filebrowser="40 * * * * [ \$(date +%k) -eq 5 ] && killall -q filebrowser ; sh /etc/storage/bin/$(basename $0)"
grep -qi $(basename $0) $cron || echo "$cron_filebrowser" >> $cron

udisk=$(mount | awk '/dev/ && /media/ {print $3}' | head -n1)
[ -z "$udisk" ] && echo "U_disk is not exist , exit !" >> /tmp/filebrowser.log && exit
# ----- filebrowser_mipsle的下载地址 ------------------------------------
fb_url=http://opt.cn2qq.com/opt-file/filemanager && md5_fb=f205afc55118007e22e64dd063655a1f
filebrowser="$udisk/filebrowser" ; port=2019
dir_fb=$(dirname $filebrowser)
[ -d "$dir_fb" ] || mkdir -p $dir_fb 
[ -f "$filebrowser" ] || wget -O $filebrowser $fb_url
chmod 755 $filebrowser

cd $dir_fb
[ -z "$(pidof filebrowser)" ] && \
if [ -f "$dir_fb/filebrowser.json" ] ; then
  $filebrowser &
else
  $filebrowser -p $port -d $dir_fb/filebrowser.db -l /tmp/filebrowser.log &
fi
