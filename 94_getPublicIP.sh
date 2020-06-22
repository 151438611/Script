#!/bin/bash
# 获取本地网络的外网IP地址

log=/tmp/ip.txt

publicIP=$(curl ip.3322.net 2> /dev/null)
[ "$publicIP" ] || publicIP=$(curl ip.cip.cc 2> /dev/null)

echo "$(date +"%F %T") IP: $publicIP" | tee -a $log
