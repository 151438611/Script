#!/bin/bash
# jh75---toshiba_udisk for kodexplorer and netac_udisk_backup for swap

cron="/etc/storage/cron/crontabs/$(nvram get http_username)" 
grep -qi $(basename $0) $cron || echo "35 3 * * * sh /etc/storage/bin/$(basename $0)" >> $cron
rsynclog="/tmp/rsync.log" ; echo "" >> $rsynclog

# toshiba_udisk is source_udisk ;--backup to-->; netac_udisk is dest_udisk
netac_udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
toshiba_udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | tail -n1)
[ "$netac_udisk" = "$toshiba_udisk" ] && echo "$(date +"%F %T") someone udisk is Invalid !---exit" >> $rsynclog && exit

src_dir1="$toshiba_udisk/data"
src_dir2="$toshiba_udisk/tmp"
backup_dir="$netac_udisk/backup" ; [ -d "$backup_dir" ] || mkdir -p $backup_dir

rsync_fun() {
# $1表示备份的源目录 , $2表示备份的目的目录
  /opt/bin/rsync -trv $1 $2
  [ $? -ne 0 ] && echo "$(date +"%F %T") rsync $1 fail！" >> $rsynclog || echo "$(date +"%F %T") rsync $1 success !" >> $rsynclog
}
# =================== start rsync file ====================================
rsync_fun $src_dir1 $backup_dir/
rsync_fun $src_dir2 $backup_dir/
