#!/bin/bash
# 因crontab中直接运行mysqldump命令不生效，使用脚本操作正常

mysql_user=root
mysql_password=root
mysql_host=localhost
databases="product os"

for db in $databases
do
  /usr/bin/mysqldump -u$mysql_user -p$mysql_password -h $mysql_host --events --master-data=2 -x -F -B $db > /opt/mysqldump_$db_$(date +%Y%m%d).sql
done
