#!/bin/sh
# Sendmail in Busybox Guide------------此脚本还未完美，暂无法使用
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
cron=/etc/crontabs/root
grep -qi $(basename $0) $cron || echo -e "\n23 23 * * * sh /etc/storage/bin/$(basename $0)" >> $cron

from_add=xiongjun0928@163.com
username=${from_add%@*}
userpasswd=xiongjuncheng
smtp_add=smtp.${from_add#*@}
to_add=xiongjun0928@foxmail.com
cc_add=jun_xiong@10gsfp.com
subject="$(date +%F)---Hostname---$(nvram get computer_name)"
message="uptime---$(uptime)

$(ifconfig | awk 'BEGIN{print "Iface_IP infomation : "}/inet addr/ || /HWaddr/ {print $0}')

$(awk 'BEGIN{print "Client infomation : "} {print $2"\t"$3}' /tmp/dhcp.leases)
"
mailtxt=/tmp/mail.txt

cat << END > $mailtxt
From:$from_add
To:$to_add
CC:$cc_add
Subject:$subject

$message
END

sendmail -f $from_add -au$username -ap$userpasswd -S $smtp_add -t < $mailtxt
