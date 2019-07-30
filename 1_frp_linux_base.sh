#!/bin/bash
# 环境:  1、设备自带(永久)存储空间   2、(frps frps.ini)或(frpc frpc.ini)文件已配置好

log=/tmp/frpc.log
# ------for arm、x86_64 -------------------------
frp=/opt/frpc/frpc
frpini=/opt/frpc/frpc.ini

# ------for padavan -------------------------
#udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
#[ -z "$udisk" ] && echo "$(date +"%F %T") frp is no exist !" && exit 1
#frp=${udisk:=/tmp}/frpc
#frpini=/etc/storage/bin/frpc.ini

[ -f "$frp" -a -f "$frpini" ] || exit
ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof ${frp##*/})" ] ; then
  chmod 555 $frp
  $frp -c $frpini &
  echo "$(date +"%F %T") frp was not runing ; start frp ..." >> $log
else
  echo "$(date +"%F %T") frp is runing, Don't do anything !" >> $log
fi
