#!/bin/bash
# for arm64 Armbian 
# 使用rsync来定时备份config 配置文件
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
cron=/var/spool/cron/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n40 1 * * * sh /opt/$(basename $0)" >> $cron
rsynclog=/tmp/rsync.log ; echo "" >> $rsynclog

src0=/etc/rc.local
src1=/etc/profile
src2=/etc/vim/vimrc
src3=/etc/php
src4=/etc/nginx
src5=/etc/apt
src6=
src7=
src8=
src9=
src10=/opt
source="$src0 $src1 $src2 $src3 $src4 $src5 $src6 $src7 $src8 $src9 $src10"
dest=/media/sda1/data/config_bak && [ -d "$dest" ] || mkdir -p $dest

rsync_fun() {
# $1表示备份的源文件/目录src , $2表示备份的目的目录dest
  rsync -tqr --delete $1 $2
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
sh /opt/mount.sh
bak_dir=/media/nfs/armbian_backup
bak_dir_tmp=/media/Rsync_Dir
if [ -d $bak_dir ] ; then
  cd /media/sda1/
  tar -zcvf ${bak_dir}/backup$(date +%Y%m%d).tgz --exclude photo data
  [ `echo $?` -eq 0 ] && echo "$(date +"%F %T") backup to $bak_dir success ! " >> $rsynclog
  sleep 60 && find $bak_dir -type f -name "backup*" -ctime +5 -exec rm -f {} \; 
  cp -ur /media/sda1/data/document $bak_dir_tmp
else
  echo -e "\n$(date +"%F %T") $bak_dir is not exist , rsync backup to $bak_dir failse !" >> $rsynclog
fi
