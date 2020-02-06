#!/bin/bash
# 简单的适用于可启动的脚本，示例: frp、filebrowser、ttyd
# 需求：1、执行文件和配置文件已存在

# 请输入完整路径
exePath="/opt/frp/frpc" && exeName=${exePath##*/}
confPath="/opt/frp/frpc.ini"
exeCommand="$exePath -c $confPath" 

log="/tmp/${exeName}.log"

cd $(dirname $exePath)
# 判断执行文件是否存在，且有执行权限
if [ -f "$exePath" -a -n "$exePath" ]; then
	[ -x $exePath ] || chmod +x $exePath
else
	echo "$(date +"%F %T") $exePath file does not exist ! ! !" >> $log 
	exit
fi	

if [ -n "$confPath" -a ! -f $confPath ];then
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
