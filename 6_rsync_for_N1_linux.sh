#!/bin/sh
# 

cron=/etc/cron/crontabs/root
grep -qi $(basename $0) $cron || echo "35 3 * * * sh /usr/local/apps/$(basename $0)" >> $cron
rsynclog=/tmp/rsync.log ; echo "" >> $rsynclog

# /etc
rc_local=/etc/rc.local
# script
frpcini=/usr/local/apps/frp/frpc.ini
frpcsh=/usr/local/apps/frp/frpc.sh
rsyncsh=/usr/local/apps/rsync.sh
# /opt
#nginx_conf=/opt/etc/nginx/nginx.conf
#phpini=/opt/etc/php.ini
#php_fpm_conf=/opt/etc/php-fpm.conf
#www_conf=/opt/etc/php7-fpm.d/www.conf

source="$cron $rc_local $frpcini $frpcsh $rsyncsh $nginx_conf $phpini $php_fpm_conf $www_conf"
backup_dir=/media/sda1/Data/Config_bak ; [ -d "$backup_dir" ] || mkdir -p $backup_dir

rsync_fun() {
# $1表示备份的源文件/目录 , $2表示备份的目的目录
  /usr/bin/rsync -tr $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") rsync success $1" >> $rsynclog || echo "$(date +"%F %T") rsync fail--- $1" >> $rsynclog
}
# =================== start rsync file/dir ====================================
for src in $source
do
  rsync_fun $src $backup_dir
done

# ===temp use===
[ -n "$(date +%e | grep -E "1|8|15|22")" ] && tar -zcf $backup_dir/opt_all.tgz /opt --exclude kodexplorer --exclude tmp
