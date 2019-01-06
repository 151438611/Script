#!/bin/bash
# 将 hwnas 挂载到sz20_k2p路由器的目录 /tmp/hwnas 下, 使用 rsync 将 U盘 中的文件备份到 hwnas 中保存

cron=/etc/storage/cron/crontabs/$(nvram get http_username) 
grep -qi $(basename $0) $cron || echo "35 3 * * * sh /etc/storage/bin/$(basename $0)" >> $cron
rsync_cmd=/opt/bin/rsync
rsynclog=/tmp/rsync.log ; echo "" >> $rsynclog

udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
[ -z "$udisk" ] && echo "$(date +"%F %T") udisk is Invalid !---exit" >> $rsynclog && exit
src0=$udisk/data
src1=$udisk/tmp
src2=
source="$src0 $src1 $src2"

mount_dir=/media/hwnas ; [ -d "$mount_dir" ] || mkdir -p $mount_dir
mount_src=//192.168.20.200/Public
if [ -z "$(mount | grep "$mount_src on $mount_dir")" ] ; then
  mount -t cifs -o username=admin,password=administrator $mount_src $mount_dir 
  [ $? -ne 0 ] && echo "$(date +"%F %T") mount hwnas fail !---exit" >> $rsynclog && exit
fi

fun_rsync() {
# $1表示备份的源目录 $2表示备份的目的目录
  $rsync_cmd -trv $1 $2
  [ $? -ne 0 ] && echo "$(date +"%F %T") rsync $1 fail！" >> $rsynclog || echo "$(date +"%F %T") rsync $1 success !" >> $rsynclog
}

dest="$mount_dir/udisk_backup" ; [ -d "$dest" ] || mkdir -p $dest
# === start rsync file =========
for src in source
do
  fun_rsync $src $dest
done
