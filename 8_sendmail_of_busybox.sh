#!/bin/sh
# Sendmail in Busybox Guide
cron=/etc/storage/cron/crontabs/$(nvram get http_username) 
grep -qi $(basename $0) $cron || echo -e "\n12 12 * * * sh /etc/storage/bin/$(basename $0)" >> $cron

from_add=xiongjun0928@163.com
username=${from_add%@*}
userpasswd=xxx
smtp_add=smtp.${from_add#*@}
to_add=jun_xiong@10gsfp.com
cc_add=
subject="$(date +%F)  Hostname : $(nvram get computer_name)  WAN_IP : $(nvram get wan_ipaddr)"

message="
$(nvram get http_username) / $(nvram get http_passwd)

$(awk -F, '{print $1"\t"$2"\t"$3}' /tmp/static_ip.inf)

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

/usr/sbin/sendmail -t -f $from_add -au$username -ap$userpasswd -S $smtp_add < $mailtxt
