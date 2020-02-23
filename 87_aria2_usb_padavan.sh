#!/bin/bash
# 适用于内置aria2软件的padavan固件,例如:荒野无灯的K2P_USB, Youku-L1 Padavan固件
# Youku_L1 示例:

aria2_bin=$(which aria2c)
aria2_dir=/media/AiCard_01/aria2
aria2_conf=${aria2_dir}/aria2.conf
aria2_session=${aria2_dir}/aria2.session
ariaNg=${aria2_dir}/ariaNg.html

FileDirNotExist() {
	# $1 表示文件或目录不存在,退出
	echo $1
	exit 1
}

[ $aria2_bin ] || FileDirNotExist "aria2_bin does not exist !!!"
[ -f $aria2_conf ] || FileDirNotExist "$aria2_conf does not exist !!!"
[ -f $ariaNg ] || FileDirNotExist "$ariaNg does not exist !!!"
[ -f $aria2_session ] || touch $aria2_session

[ -z "$(mount | grep www)" ] && \
{ mount -o bind /media/AiCard_01/aria2/ariaNg.html /www/Advanced_Extensions_koolproxy.asp || FileDirNotExist "$ariaNg mount failed !!!" ; }

[ $(pidof ${aria2_bin##*/}) ] || \
{ $aria2_bin -D --conf-path=$aria2_conf || FileDirNotExist "$aria2_bin start failed !!!" ; }

echo "$aria2_bin start success , and $ariaNg mount success ; Open WebGUI ."
