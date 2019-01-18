#!/bin/sh
# Sendmail in Busybox Guide

mailtxt=/tmp/mail.txt

from_add="xiongjun0928@163.com"
username=${from_add%@*}
userpasswd=xxx
smtp_add="smtp.${from_add#*@}"
to_add="jun_xiong@10gsfp.com xiongjun0928@foxmail.com"
cc_add=""
subject="$(nvram get computer_name) rsync log "

message=$(cat /tmp/rsync.log)

cat << END > $mailtxt
From:$from_add
To:$to_add
CC:$cc_add
Subject:$subject

$message
END

/usr/sbin/sendmail -f $from_add -au$username -ap$userpasswd -S $smtp_add -t < $mailtxt

[ $? -eq 0 ] || echo -e "\n $(date +"%F %T") sendmail fail!"
