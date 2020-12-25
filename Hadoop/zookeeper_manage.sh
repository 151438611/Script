#!/bin/bash
# 用于在 master 主机上管理(启动/停止/查看) zookeeper 集群服务
# 提前: master和其他主机配置好SSH免密登陆, zookeeper集群配置正确

# 主机名或IP地址; 自行填写
zookeeper1=slave1
zookeeper2=slave2
zookeeper3=slave3
zookeeper4=
zookeeper5=
zookeepers="$zookeeper1 $zookeeper2 $zookeeper3 $zookeeper4 $zookeeper5"

zkPATH=/usr/local/zookeeper/bin
case $1 in
	"start")
		exec_command="$zkPATH/zkServer.sh start"
	;;
	"stop")
		exec_command="$zkPATH/zkServer.sh stop"
	;;
	"status")
		exec_command="$zkPATH/zkServer.sh status"
	;;
	*)
		echo -e "Usage : \033[31m$0 [start | stop | status]\033[0m"
		exit
	;;
esac

for zk_host in $zookeepers
do
	echo -e "\033[33m---------- Host: $zk_host ----------\033[0m"
	echo -e "\033[36m$(ssh $zk_host $exec_command 2> /dev/null)\033[0m\n"
done

