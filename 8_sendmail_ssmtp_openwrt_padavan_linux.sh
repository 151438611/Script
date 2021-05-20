#!/bin/sh
# support padavan(sendmail) and openwrt(ssmtp)
# Notes: 
# ssmtp need to config /etc/sstmp/sstmp.conf ---> mailhub FromLineOverride=YES AuthUser AuthPass

from_add=xiongjun0928@163.com
smtp_add=smtp.${from_add#*@}
username=${from_add%@*}
userpasswd=xxxxxxxx

to_add=xiongjun0928@foxmail.com
cc_add=jun_xiong@10gsfp.com

mailtxt=/tmp/mail.txt

if [ -n "$(grep -i padavan /proc/version)" ] ; then
	os_type=padavan
	
	export PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH
	sh_path=sh /etc/storage/bin/sendmail.sh
	cron=/etc/storage/cron/crontabs/$(nvram get http_username) 
	grep -q "$sh_path" $cron || echo -e "\n22 2 * * * sh $sh_path" >> $cron
	
	subject="$(date +%F)---Hostname---$(nvram get computer_name)"
	frpc=$(ps | grep frpc | grep -v grep | awk '{print $5,$6,$7}')
	message="
Router_information:
$(nvram get http_username) / $(nvram get http_passwd) / uptime---$(uptime)

FreeRAM:
$(free | head -n2)

Frp_status:
$($frpc status)

DHCP_Client:
$(awk -F, 'BEGIN{print "Client infomation : "} {print $1"\t"$2"\t"$3}' /tmp/static_ip.inf)
=======================================================
autoChangeAp.log : 
$(tail -n 48 /tmp/autoChangeAp.log | grep -E ":00:|WIFI")

$(ip address | grep inet)
"

cat << END > $mailtxt
From:$from_add
To:$to_add
CC:$cc_add
Subject:$subject

$message
END
	sendmail -f $from_add -au$username -ap$userpasswd -S $smtp_add -t < $mailtxt

elif [ -n "$(grep -Ei "openwrt|lede" /proc/version)" ] ; then
	os_type=openwrt
	
	subject="(date +%F)---Hostname---$(uci get system.@system[0].hostname)"
	message="
Uptime:	$(uptime)

FreeRAM:	
$(free | head -n2)
	
DHCP:
$(cat /tmp/dhcp.leases)
"
	
	cat << END > $mailtxt
From:$from_add
To:$to_add
CC:$cc_add
Subject:$subject

$message
END

ssmtp $to_add < $mailtxt

else 
	os_type=linux
fi
