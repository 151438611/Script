#!/bin/bash
# 适用Zabbix-agent(support x86_64 and arm64)自定义脚本，用于检测ping目标主机的延时; 时间单位:ms
# $1表示目录主机的 IP 或 域名
# 注意: 
#  1 需要修改 zabbix_server.conf 和 zabbix_agentd.conf 中的 Timeout=10 或更长
#  2 chmod +x ping_delay.sh
# zabbix_agentd.conf: UserParameter=ping.delay[*],/bin/bash /etc/zabbix/ping_delay.sh $1
# zabbix_agentd.conf: UserParameter=get_public_ip,/bin/curl https://ip.cn 2> /dev/null | awk -F \" '{print $4}'   # 监控本地网络的公网IP变化

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

[ -z "$1" ] && echo "Usage: bash $0 Host" && exit 1

delay=$(ping -w 5 $1 | awk -F "/" '/min/{print $5}')

echo ${delay:-0}
