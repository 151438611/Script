#!/bin/bash
# for 定时备份脚本、配置文件到存储目录

rc_local=/etc/rc.local
cron=/etc/cron/crontabs/root
nginx_conf=/opt/etc/nginx/nginx.conf
phpini=/opt/etc/php.ini
php_fpm_conf=/opt/etc/php-fpm.conf
www_conf=/opt/etc/php7-fpm.d/www.conf

sourse="$rc_local $cron $nginx_conf $phpini $php_fpm_conf $www_conf "
dest_dir=/media/sda1/Data/Config_bak ; [ -d "$dest_dir" ] || mkdir -p $dest_dir

func_backupConfig() {
  cp -f $1 $2
}

for sour in $sourse
do
  func_backupConfig $sour $dest_dir
done
