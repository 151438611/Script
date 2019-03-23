#!/bin/sh
# 用于在Centos测试电脑上进行网卡测试

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
log="~/nic_test.txt" ; date +"%F %T" > $log
clear
echo -e "\n请先确认测试电脑已配置好如下IP信息："
echo "上面的测试电脑需配置IP信息：eth1:192.168.6.101 eth2:192.168.7.101 eth3:192.168.8.101 eth4:192.168.9.101;"
echo "下面的测试电脑需配置IP信息：eth1:192.168.6.201 eth2:192.168.7.201 eth3:192.168.8.201 eth4:192.168.9.201;"
echo "且二台电脑的同号端口相连，不可混连; 例如: eth1连接eth1、eth2连接eth2 依此连接 ... "

sleep 3 ; echo "开始读取PCI-E插入网卡信息..."
ethernet=$(lspci | grep -i "Ethernet controller")
[ $(echo $ethernet | wc -l) -lt 1 ] && result="识别网卡成功:" || result="未识别插入的PCI-E网卡:"
echo -e "\n$result\n$ethernet" | tee -a $log 

ip addr | awk '/</ {print $0}'
read -p "请输入测试的网卡端口号,state UP表示已链接,state DOWN表示未链接 (见上面 eth[1-4] ) : " port  
eth_i=$(ethtool -i $port)
[ $? -eq 0 ] && result="读取网卡驱动版本信息成功:" || result="读取网卡驱动版本信息失败:"
echo -e "\n$result\n$eth_i" | tee -a $log 

echo -e "\n开始读取EEPROM信息...\n"
eth_m=$(ethtool -m $port)
[ $? -eq 0 ] && result="读取EEPROM信息成功:" || result="读取EEPROM信息失败:"
echo -e "\n$result\n$eth_m" | tee -a $log 

echo -e "\n开始读取链路连通状态...\n"
link_cmd=$(ethtool $port)
link_stat=$(echo "$link_cmd" | awk '/Link detected:/{print $3}')
link_speed=$(echo "$link_cmd" |awk '/Speed:/{print int($2)}')
[ "$link_stat" = "yes" -a -n "link_speed" ] && result="链路连通正常:" || result="链路连通失败:"
echo -e "\n$result\n$link_cmd" | tee -a $log 

echo -e "\n开始进行 Ping 包测试...\n"
read -p "请输入Ping包次数,默认2000: (2000-10000以内)" count
[ -n $(echo ${count:=2000} | tr -d [0-9]) ] && count=2000
net_ip=$(ifconfig eth1 | awk '/inet/ && /netmask/ {print $2}')
if [ -n "$(echo $net_ip |  grep 10)" ] ; then
case
 eth1) dest_ip=192.168.6.201 ;;
 eth2) dest_ip=192.168.7.201 ;;
 eth3) dest_ip=192.168.8.201 ;;
 eth4) dest_ip=192.168.9.201 ;;
esca
elif [ -n "$(echo $net_ip |  grep 20)" ] ; then
 eth1) dest_ip=192.168.6.101 ;;
 eth2) dest_ip=192.168.7.101 ;;
 eth3) dest_ip=192.168.8.101 ;;
 eth4) dest_ip=192.168.9.101 ;;
fi
ping -w 2 $dest_ip &> /dev/null && \
ping -c $count -i 0.05 $dest_ip | tee /tmp/ping.log 
ping_head=$(head -n6 /tmp/ping.log)
ping_tail=$(tail /tmp/ping.log)
[ -n $(echo "$ping_tail" | awk '/0% packet loss/ {print $0}') ] && result="Ping包成功，无丢包:" || result="Ping包失败或有丢包:"
echo -e "\n$result\n$ping_head\n......\nping_tail" | tee -a $log 

echo -e "\n请先将另一台电脑作为服务端，运行 "iperf3 -s" 命令"
echo "然后本机将开始iperf性能测试...\n"
read -p "请确认另一台电脑已运行 "iperf3 -s" , 按 回车键 开始性能测试: " confirm
iperf3 -c $dest_ip -t 60 | tee /tmp/iperf.log
iperf_head=$(head -n6 /tmp/iperf.log)
iperf_tail=$(tail /tmp/iperf.log)
[ -n $(echo "$iperf_tail" | grep "iperf Done") ] && result="性能测试完成: " || result="性能测试失败: " 
echo -e "\n$result\n$iperf_head\n......\niperf_tail" | tee -a $log 

unix2dos -o $log ; rm -f /tmp/ping.log /tmp/iperf.log
echo -e "\n测试已完成 ! 测试数据保存在 nic_test.txt 中，请及时拷出！！！\n"
