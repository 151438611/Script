#!/bin/bash
# 因crontab中直接运行mysqldump不生效，使用脚本操作正常

mysql_user=root
mysql_password=root
databases="product os"

for db in $databases
do

  /usr/bin/mysqldump -u$mysql_user -p$mysql_password --events --master-data=2 -x -F -B $db > /opt/${db}_mysqldump_$(date +%Y%m%d).sql

done
