#!/bin/sh
# Sendmail in Busybox Guide
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
cron=/etc/storage/cron/crontabs/$(nvram get http_username) 
grep -qi $(basename $0) $cron || echo -e "\n12 12 * * * sh /etc/storage/bin/$(basename $0)" >> $cron

from_add=xiongjun0928@163.com
username=${from_add%@*}
userpasswd=xiongjuncheng
smtp_add=smtp.${from_add#*@}
to_add=xiongjun0928@foxmail.com
cc_add=jun_xiong@10gsfp.com
subject="$(date +%F)---Hostname---$(nvram get computer_name)"
message="$(nvram get http_username) / $(nvram get http_passwd)

$(ifconfig | awk 'BEGIN{print "Iface_IP infomation : "}/inet addr/ || /HWaddr/ {print $0}')

$(awk -F, 'BEGIN{print "Client infomation : "} {print $1"\t"$2"\t"$3}' /tmp/static_ip.inf)

=======================================================
uptime

$(tail -n 24 /tmp/autoChangeAp.log)
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

