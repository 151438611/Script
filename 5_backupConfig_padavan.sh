#!/bin/bash
# 备份/etc/storage目录下的脚本文件

cd /etc/storage/
tar -zcvf /tmp/conf_backup_$(nvram get computer_name).tgz *.sh bin cron
