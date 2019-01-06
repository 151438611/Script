#!/bin/sh
# 

cron=/etc/cron/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n35 3 * * * sh /usr/local/apps/$(basename $0)" >> $cron
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
dest=/media/sda1/Data/Config_bak ; [ -d "$dest" ] || mkdir -p $dest

rsync_fun() {
# $1表示备份的源文件/目录 , $2表示备份的目的目录
  /usr/bin/rsync -tr $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") rsync success $1" >> $rsynclog || echo "$(date +"%F %T") rsync fail--- $1" >> $rsynclog
}

# === start rsync file/dir ==============
for src in $source
do
  rsync_fun $src $dest
done

# === temp use ==============
if [ -n "$(date +%e | grep -E "1|8|15|22")" ] ; then
  tar -zcf $backup_dir/opt_all.tgz /opt --exclude kodexplorer --exclude tmp
  cd $dest && tar -zcf szN1_Conf_backup.tgz * --exclude *.tgz --exclude *.tar.gz
fi

mv $dest/$(basename $cron) $dest/crontab.txt
