#!/bin/bash
# 用于在 master 主机上操作其他主机运行相关命令
# 提前: master和其他主机配置好SSH免密登陆
# 示例: bash run_command_for_hadoop.sh "uname -a"

# 自行填写: 被操作运行命令的主机名或IP地址; 多个用空格分隔; 
hosts="slave1 slave2 192.168.200.251"

blue_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}

if [ -n "$1" ]; then
	for host in $hosts
	do
		yellow_echo "---------- Host: $host Running: \"$1\"----------"
		blue_echo "$(ssh $host $1)\n"
	done
else
	yellow_echo "Usage : $0 'command'"
fi

