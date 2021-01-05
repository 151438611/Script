#!/bin/bash
# 用于在 master 主机上查看所有集群主机的 jps 启动服务
# 提前: master和其他主机配置好SSH免密登陆

# 需要分发的主机名或IP地址; 自行填写
host1=master1
host2=
host3=slave1
host4=slave2
host5=slave3
hosts="$host1 $host2 $host3 $host4 $host5"

blue_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}

jps=$(which jps)
if [ -n "$jps" ]; then
	for host in $hosts
	do
		yellow_echo "---------- Host: $host ----------"
		blue_echo "$(ssh $host $jps)\n"
	done
else
	yellow_echo "jps: command not found"
fi
