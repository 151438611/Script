#!/bin/bash
# 将 hwnas 挂载到sz20_k2p路由器的目录 /tmp/hwnas 下, 使用 rsync 将 U盘 中的文件备份到 hwnas 中保存

cron="/etc/storage/cron/crontabs/$(nvram get http_username)" 
grep -qi $(basename $0) $cron || echo "35 3 * * * sh /etc/storage/bin/$(basename $0)" >> $cron
rsynclog="/tmp/rsync.log" ; echo "" >> $rsynclog

udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
[ -z "$udisk" ] && echo "$(date +"%F %T") udisk is Invalid !---exit" >> $rsynclog && exit
src_dir1="$udisk/data"
src_dir2="$udisk/tmp"

mount_dir="$udisk/hwnas" ; [ -d "$mount_dir" ] || mkdir -p $mount_dir
backup_dir="$mount_dir/udisk_backup"
if [ -z "$(mount | grep 192.168.20.200)" ] ; then
  mount -t cifs -o username=admin,password=administrator //192.168.20.200/Public $mount_dir 
  [ $? -ne 0 ] && echo "$(date +"%F %T") mount hwnas fail !---exit" >> $rsynclog && exit
fi

rsync_fun() {
# $1表示备份的源目录
  /opt/bin/rsync -trv $1 $backup_dir/
  [ $? -ne 0 ] && echo "$(date +"%F %T") rsync $1 fail！" >> $rsynclog || echo "$(date +"%F %T") rsync $1 success !" >> $rsynclog
}
# =================== start rsync file ====================================
rsync_fun $src_dir1
rsync_fun $src_dir2
