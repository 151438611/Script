#!/bin/bash
# for Padavan ,support filebrowser 2.0.x
# FileBrowser v2.0.x 使用方法
#1 ./filebrowser -d ./filebrowser.db config init  初始化数据库配置文件
#2 ./filebrowser -d ./filebrowser.db config set -p 2019 -l /tmp/filebrowser.log
#3 ./filebrowser -d ./filebrowser.db users add username passwd --perm.admin  添加管理员帐号
#4 ./filebrowser -d ./filebrowser.db &  后台启动软件

# 请输入完整路径
exePath="/opt/filebrowser" && exeName=$(basename $exePath)
confPath=""
exeCommand="$exePath -a 0.0.0.0 -d /media/sda1/filebrowser.db -p 81 -l /tmp/filebrowser.log"

log="/tmp/${exeName}.log"
cd $(dirname $exePath)
# 判断执行文件是否存在，且有执行权限
if [ -f "$exePath" ]; then
	[ -x "$exePath" ] || chmod +x $exePath
else
	echo "$(date +"%F %T") $exePath file does not exist ! ! !" >> $log 
	exit
fi	

if [ -n "$confPath" -a ! -f $confPath ]; then
	echo "$(date +"%F %T") $confPath file does not exist ! ! !" >> $log
	exit
fi
# 判断执行进程是否存在
if [ -n "$(pidof $exeName)" ]; then
	echo "$(date +"%F %T") $exeName is runing, Don't do anything !" >> $log
else 
	echo "$(date +"%F %T") $exeName was not runing ; start $exeName ... " >> $log
	exec $exeCommand &
fi
