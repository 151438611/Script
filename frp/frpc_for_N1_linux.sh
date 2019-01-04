#!/bin/sh

frpc="/usr/local/apps/frp/frpc" ; frpcini="/usr/local/apps/frp/frpc.ini"
[ -x "$frpc" -a -f "$frpcini"  ] || exit 1

ip_addr=$(ifconfig eth0 | awk '$0~"inet addr"{print $2}' | cut -d: -f2)
old_addr=$(awk '$0~"local_ip = 192.168" {print $3}' $frpcini | head -n1)

[ "$ip_addr" = "$old_addr" ] || sed -i 's/'"$old_addr"'/'"$ip_addr"'/g' $frpcini

if [ -z "$(pidof frpc)" ] ; then
  $frpc -c $frpcini &
  echo "$(date +"%F %T") frpc was not runing ; start frpc ..." >> /tmp/frpc.log
else
  echo "$(date +"%F %T") frpc is runing, Don't do anything !" >> /tmp/frpc.log
fi
