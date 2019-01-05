#!/bin/sh

cron=/etc/cron/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n15 * * * * [ \$(date +%k) -eq 5 ] && killall frpc ; sleep 8 && sh /usr/local/apps/frp/$(basename $0)" >> $cron
grep -qi reboot $cron || echo -e "\n5 5 * * * [ -n "\$(date +%e | grep -E "1|10|20")" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot" >> $cron

frpc="/usr/local/apps/frp/frpc" ; frpcini="/usr/local/apps/frp/frpc.ini"
[ -x "$frpc" -a -f "$frpcini"  ] || exit 1

ip_addr=$(ifconfig eth0 | awk '$0~"inet addr"{print $2}' | cut -d: -f2)
old_addr=$(awk '$0~"local_ip = 192.168" {print $3}' $frpcini | head -n1)

[ -n "$ip_addr" -a "$ip_addr" != "$old_addr" ] && sed -i 's/'"$old_addr"'/'"$ip_addr"'/g' $frpcini

if [ -z "$(pidof frpc)" ] ; then
  $frpc -c $frpcini &
    echo "$(date +"%F %T") frpc was not runing ; start frpc ..." >> /tmp/frpc.log
else
    echo "$(date +"%F %T") frpc is runing, Don't do anything !" >> /tmp/frpc.log
fi
