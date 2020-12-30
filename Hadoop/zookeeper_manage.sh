#!/bin/bash
# for apache-zookeeper-3.6.2
# 用于在 master 主机上管理(启动/停止/查看) zookeeper 集群服务
# 提前: master和其他主机配置好SSH免密登陆, zookeeper 集群配置正确

# 主机名或IP地址; 自行填写
host1=slave1
host2=slave2
host3=slave3
host4=
host5=
hosts="$host1 $host2 $host3 $host4 $host5"

green_echo() {
echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
echo -e "\033[33m$1\033[0m"
}
red_echo() {
echo -e "\033[31m$1\033[0m"
}

exec_dir="/usr/local/zookeeper/bin"
case $1 in
	"start")
		exec_command="$exec_dir/zkServer.sh start"
	;;
	"stop")
		exec_command="$exec_dir/zkServer.sh stop"
	;;
	"status")
		exec_command="$exec_dir/zkServer.sh status"
	;;
	*)
		yellow_echo "Usage : $0 [ start | stop | status ]"
		exit
	;;
esac

for host in $hosts
do
	yellow_echo "---------- Host: $host $1 Zookeeper ----------"
	green_echo "$(ssh $host $exec_command 2> /dev/null)\n"
done

