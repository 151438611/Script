#!/bin/bash
# 获取网络的外网IP地址

log=/tmp/ip.txt

ipinfo=$(curl http://ip.sb 2> /dev/null)

echo "$(date +"%F %T") IP: $ipinfo" | tee -a $log
