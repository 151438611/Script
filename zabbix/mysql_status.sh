#!/bin/bash
# 适用Zabbix-agent，用于检测系统状态
# 

# 检查参数是否正确 
if [ $# -eq 0 ]; then  
    echo "input arg error!" 
fi 

# 数据库状态检查
MysqlAdmin=/usr/bin/mysqladmin
MysqlUser=xxx
MysqlPassword=xxx
MysqlHost=localhost
MysqlPort=3306
MysqlConnect="$MysqlAdmin -u$MysqlUser -p$MysqlPassword -h$MysqlHost -P$MysqlPort"

# 获取数据 
case $1 in  
    SystemOnline) 
        # 用Ping来检测主机是否在线，在线则记录1，不在线则记录0
        [ ! "$2" ]  && echo "Usage: bash $0 SystemOnline IP_Addr" && exit 1
        ping -c2 -w3 $2 && result=1 || result=0
		echo $result
	;;
    SystemUptimeSec) 
		result=$(awk '{print int($1)}' /proc/uptime)
		echo $result
	;;
    SystemUptimeLoadAverageFloat) 
		result=$(awk '{print $2}' /proc/loadavg)
		echo $result
	;;
	SystemMemUsedBytes) 
		result=$(free -m | awk '/Mem/ {print $3}')
		echo $result
	;;
    SystemMemFreeBytes) 
		result=$(free -m | awk '/Mem/ {print $4}')
		echo $result
	;;
    SystemDiskUsedPercentage) 
		result=$(df | awk '$6=="/" {print int($5)}')
		echo $result
	;;
    MysqlPing) 
        # Mysql 在线则记录1，不在线则记录0
		result=$($MysqlConnect ping | grep -c alive)
		echo $result
	;;
    MysqlUptimeSec) 
		result=$($MysqlConnect status | awk '{print $2}')
		echo $result
	;;
    MysqlThreadsPcs) 
		result=$($MysqlConnect status | awk '{print $4}')
		echo $result
	;;
    MysqlQuestions) 
		result=$($MysqlConnect | awk '{print $6}')
		echo $result
	;;
    MysqlSentBytes) 
		result=$($MysqlConnect extended-status | grep -w "Bytes_sent" | cut -d"|" -f3)
		echo $result
	;;
    MysqlReceivedBytes) 
		result=$($MysqlConnect extended-status | grep -w "Bytes_received" | cut -d"|" -f3)
		echo $result
	;;	
    *)  
		echo "Usage: bash $0 (SystemOnline IP | SystemUptimeSec | SystemUptimeLoadAverageFloat | SystemMemUsedBytes | SystemMemFreeBytes | SystemDiskUsedPercentage | MysqlPing | MysqlUptimeSec | MysqlThreadsPcs | MysqlQuestions | MysqlSentBytes | MysqlReceivedBytes)"  
    ;; 
esac
