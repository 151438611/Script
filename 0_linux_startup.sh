#!/bin/bash
# 简单的适用于可启动的脚本，示例: frp、filebrowser、ttyd、edge、supernode ......
# 需求：1、执行文件已存在 ；示例：
# frp : frpc -c frpc.ini &
# ttyd : ttyd -p 7800 -m 5 -d 0 /bin/login &
# filebrowser : filebrowser -a 0.0.0.0 -p 8081 -d /media/sda1/filebrowser.db -l /tmp/filebrowser.log &
# n2n v2.8 supernode: supernode -l 8000 & 
# n2n v2.9 supernode: supernode -p 8000 & 
# n2n edge: edge -Er -A1 -d n2nEdge -c n2n -a 10.0.0.41 -s 255.255.255.0 -l frp.xxy1.ltd:8000


# 请输入文件绝对路径
exePath="/opt/frpc/frpc" && exeName=${exePath##*/}
confPath="/opt/frpc/frpc.ini"
exeCommand="$exePath -c $confPath"

log="/tmp/${exeName}.log"
cd $(dirname $exePath)
# 判断执行文件是否存在，且有执行权限
if [ -f "$exePath" -a -n "$exePath" ]; then
	[ -x $exePath ] || chmod +x $exePath
else
	echo "$(date +"%F %T") $exePath file does not exist ! ! !"
	exit
fi	

if [ -n "$confPath" -a ! -f $confPath ]; then
	echo "$(date +"%F %T") $confPath file does not exist ! ! !"
	exit
fi
# 判断执行进程是否存在
if [ -n "$(pidof $exeName)" ]; then
	echo "$(date +"%F %T") $exeName is runing, Don't do anything !" >> $log
else 
	echo "$(date +"%F %T") $exeName was not runing ; start $exeName ... " >> $log
	exec $exeCommand &
fi
