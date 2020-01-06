#!/bin/bash
# 获取网络的外网IP地址

log=/tmp/ip.txt

ipinfo=$(curl https://ip.cn 2> /dev/null | awk -F \" '{print $4}')

echo "$(date +"%F %T") IP: $ipinfo" >> $log
