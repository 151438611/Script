#!/bin/bash
# 用于在 master 主机上查看所有集群主机的 jps 启动服务
# 提前: master和其他主机配置好SSH免密登陆

# 自行填写：主机名或IP地址; 多个用空格分隔
hosts="master slave1 slave2 slave3"

java_home=/usr/local/java
jps=$(which jps)
[ "$jps" ] || jps=$java_home/bin/jps

blue_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}
red_echo() {
	echo -e "\033[31m$1\033[0m"
}

for host in $hosts
do
	yellow_echo "---------- Host: $host ----------"
	blue_echo "$(ssh $host $jps)\n"
done

