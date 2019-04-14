#!/bin/bash
# 环境:（frpc frpc.ini)/(frps frps.ini)文件已存在并已配置好
# 此脚本仅自动执行在Linux中后台运行操作

log=/tmp/frpc.log

# ------for arm、x86_64 -------------------------
#frp=/opt/frpc/frpc
#frpini=/opt/frpc/frpc.ini

# ------for padavan -------------------------
udisk=$(mount | awk '$1~"/dev/" && $3~"/media/"{print $3}' | head -n1)
frp=${udisk:=/tmp}/frpc
frpini=/etc/storage/bin/frpc.ini

[ -f "$frp" -a -f "$frpini" ] || exit
ping -c2 -w5 114.114.114.114 && \
if [ -z "$(pidof ${frp##*/})" ] ; then
  chmod 555 $frp
  $frp -c $frpini &
  echo "$(date +"%F %T") frp was not runing ; start frp ..." >> $log
else
  echo "$(date +"%F %T") frp is runing, Don't do anything !" >> $log
fi

