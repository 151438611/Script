#!/bin/bash
# for apache-zookeeper-3.6.2
# 用于在 master 主机上管理(启动/停止/查看) zookeeper 集群服务
# 提前: master和其他主机配置好SSH免密登陆, zookeeper 集群配置正确

# 自行填写：zookeeper集群中的主机名或IP地址; 多个主机用空格分隔
hosts="slave1 slave2 slave3"
# 注意：exec_dir路径后面一定要带/号
exec_dir="/usr/local/zookeeper/bin/"
[ -d $exec_dir ] || exec_dir=

blue_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}

case $1 in
	"start")
		exec_command="${exec_dir}zkServer.sh start"
	;;
	"stop")
		exec_command="${exec_dir}zkServer.sh stop"
	;;
	"status")
		exec_command="${exec_dir}zkServer.sh status"
	;;
	*)
		yellow_echo "Usage : $0 [ start | stop | status ]"
		exit
	;;
esac

for host in $hosts
do
	yellow_echo "---------- Host: $host $1 Zookeeper ----------"
	blue_echo "$(ssh $host $exec_command 2> /dev/null)\n"
done

