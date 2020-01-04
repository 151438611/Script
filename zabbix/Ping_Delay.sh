#!/bin/bash
# 适用Zabbix-agent(x86_64 and arm64)自定义脚本，用于检测ping目标主机的延时;单位:ms
# $1表示传入的目录主机 IP 或 域名
# 注意: 需要修改 zabbix_server.conf 和 zabbix_agentd.conf 中的 Timeout=10 或更长

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

[ -z "$1" ] && echo "Usage: bash $0 Host" && exit 1

delay=$(ping -w 5 $1 | awk -F "/" '/min/{print $5}')

echo ${delay:-0}
