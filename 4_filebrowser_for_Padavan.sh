#!/bin/bash
# for Padavan 

user=$(nvram get http_username) ; cron=/etc/storage/cron/crontabs/$user ; startup=/etc/storage/started_script.sh
grep -qi $(basename $0) $startup || echo "sleep 5 ; sh /etc/storage/bin/$(basename $0)" >> $startup
grep -qi $(basename $0) $cron || echo "40 * * * * [ \$(date +%k) -eq 5 ] && killall -q filebrowser ; sleep 8 && sh /etc/storage/bin/$(basename $0)" >> $cron

# ----- filebrowser_mipsle的下载地址 ------------------------------------
fb_url="http://opt.cn2qq.com/opt-file/filemanager" && md5_fb="957c409aba8623ff6a5b6ed4b8b6045d"
port=2019

udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
[ -z "$udisk" ] && echo "U_disk is not exist !" >> /tmp/filebrowser.log && exit

filebrowser="$udisk/filebrowser" && dir_fb=$(dirname $filebrowser)
[ -d "$dir_fb" ] || mkdir -p $dir_fb 

download_fb() {
  rm -f $frpc ; curl -o $filebrowser $fb_url
}
cd $dir_fb
#[ -f "$filebrowser" ] && [ "$(md5sum $filebrowser | cut -d " " -f 1)" = "$md5_fb" ] || download_fb 
[ -f "$filebrowser" ] || download_fb 
chmod 555 $filebrowser

[ -z "$(pidof filebrowser)" ] && \
if [ -f "$dir_fb/filebrowser.json" ] ; then
  $filebrowser &
else
  $filebrowser -p $port -l stderr &
fi
