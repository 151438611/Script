#!/bin/sh
# 使用rsync来定时备份config 配置文件
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

cron=/var/spool/cron/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n35 3 * * * sh /opt/$(basename $0)" >> $cron
rsynclog=/tmp/rsync.log ; echo "" >> $rsynclog

src0=/etc/rc.local
src1=/etc/nginx
src2=/etc/php
src3=
src4=
src5=/opt/frp/frpc.ini
src6=/opt/frp/frpc.sh
src7=/opt/rsync.sh
src8=
src9=

source="$src0 $src1 $src2 $src3 $src4 $src5 $src6 $src7 $src8 $src9"
dest=/media/sda1/Data/Config_bak ; [ -d "$dest" ] || mkdir -p $dest

rsync_fun() {
# $1表示备份的源文件/目录src , $2表示备份的目的目录dest
  rsync -tr $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") rsync success $1" >> $rsynclog || echo "$(date +"%F %T") rsync fail--- $1" >> $rsynclog
}

# === start rsync file/dir ==============
for src in $source
 do
   rsync_fun $src $dest
 done
rsync -tr $cron $dest/crontab.txt

if [ -n "$(date +%e | grep -E "1|8|15|22")" ] ; then
  cd $dest && tar -zcvf ../Script/N1_armbian_Conf_backup.tgz * --exclude *.tgz
fi

chown -R www-data.www-data /media/sda1
