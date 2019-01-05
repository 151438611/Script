#!/bin/sh
# 

cron=/etc/cron/crontabs/root
grep -qi $(basename $0) $cron || echo "35 3 * * * sh /usr/local/apps/$(basename $0)" >> $cron
rsynclog=/tmp/rsync.log ; echo "" >> $rsynclog

# /etc
src0=$cron
src1=/etc/rc.local
# script
src2=/usr/local/apps/frp/frpc.ini
src3=/usr/local/apps/frp/frpc.sh
src4=/usr/local/apps/rsync.sh
# /opt
#src5=/opt/etc/nginx/nginx.conf
#src6=/opt/etc/php.ini
#src7=/opt/etc/php-fpm.conf
#src8=/opt/etc/php7-fpm.d/www.conf

source="$src0 $src1 $src2 $src3 $src4 $src5 $src6 $src7 $src8 $src9"
backup_dir=/media/sda1/Data/Config_bak ; [ -d "$backup_dir" ] || mkdir -p $backup_dir

rsync_fun() {
# $1表示备份的源文件/目录 , $2表示备份的目的目录
  /usr/bin/rsync -tr $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") rsync success $1" >> $rsynclog || echo "$(date +"%F %T") rsync fail--- $1" >> $rsynclog
}
# =================== start rsync file ====================================
for src in $source
do
  rsync_fun $src $backup_dir
done

# ===temp use===
[ -n "$(date +%e | grep -E "1|8|15|22")" ] && tar -zcf $backup_dir/opt_all.tgz /opt --exclude kodexplorer --exclude tmp
