#!/bin/sh
# Sendmail in Busybox Guide

from_add=xiongjun0928@163.com
username=${from_add%@*}
userpasswd=xxx
smtp_add=smtp.${from_add#*@}
to_add=jun_xiong@10gsfp.com
cc_add=
subject="$(date +"%F %T") $(nvram get computer_name) WAN_IP:$(nvram get wan_ipaddr) log "

message="
$(cat /tmp/static_ip.inf)
$(tail -n 20 /tmp/rsync.log)
$(tail -n 20 /tmp/autoChangeAp.log)
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
