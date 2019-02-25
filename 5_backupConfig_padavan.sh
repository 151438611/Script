#!/bin/bash
# for 定时备份脚本、配置文件到存储目录

cron=/etc/storage/cron/crontabs/$(nvram get http_username)
bin_dir=/etc/storage/bin
cp -f $cron $bin_dir/crontab.txt

cd $bin_dir 
tar -zcvf /tmp/conf_backup_$(nvram get computer_name).tgz *.*
rm -f $bin_dir/crontab.txt
