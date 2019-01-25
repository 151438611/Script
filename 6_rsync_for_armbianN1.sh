#!/bin/sh
# 使用rsync来定时备份config 配置文件
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

cron=/var/spool/cron/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n35 3 * * * sh /opt/$(basename $0)" >> $cron
rsynclog=/tmp/rsync.log ; echo "" >> $rsynclog

src0=/etc/rc.local
src1=
src2=
src3=
src4=/etc/samba/smb.conf
src5=/opt/frp
src6=
src7=/opt/rsync.sh
src8=/opt/mount_smb.sh
src9=/opt/sendmail.sh
src10=
src11=

source="$src0 $src1 $src2 $src3 $src4 $src5 $src6 $src7 $src8 $src9 $src10 $src11"
dest=/media/sda1/data/config_bak ; [ -d "$dest" ] || mkdir -p $dest

rsync_fun() {
# $1表示备份的源文件/目录src , $2表示备份的目的目录dest
  rsync -tvr $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") rsync success $1" >> $rsynclog || echo "$(date +"%F %T") rsync fail--- $1" >> $rsynclog
}

# === start rsync ==============
for src in $source
 do
   rsync_fun $src $dest
 done
   rsync_fun $cron $dest/crontab.txt

if [ -n "$(date +%u | grep 5)" ] ; then
  cd $dest && tar -zcvf ../script/conf_backup_armbian_n1.tgz *
fi

chown -R armbian.armbian /media/sda1

# ===== temp use =================
sh /opt/mount_smb.sh
if [ -n "$(mount | grep 10gtek)" ] ; then
  cd /media/sda1/
  tar -zcvf /media/10gtek/backup$(date +%Y%m%d).tgz --exclude photo data
  [ `echo $?` -eq 0 ] && echo "$(date +"%F %T") backup to 10gtek success ! " >> $rsynclog
  sleep 60 && find /media/10gtek -type f -name "backup*" -ctime +5 -exec rm -f {} \; 
else
  echo -e "\n$(date +"%F %T") 10gtek is not mount , rsync backup to 10gtek failse !" >> $rsynclog
fi
