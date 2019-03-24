#!/bin/sh
# 用于在Centos测试电脑上进行网卡测试

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
log="/tmp/nic_test.txt" ; date +"%F %T" > $log
clear
echo -e "\n测试环境要求："
echo -e "\n1、测试电脑1(上)需配置IP信息：eth1:192.168.6.101 eth2:192.168.7.101 eth3:192.168.8.101 eth4:192.168.9.101;"
echo -e "\n2、测试电脑2(下)需配置IP信息：eth1:192.168.6.201 eth2:192.168.7.201 eth3:192.168.8.201 eth4:192.168.9.201;"
echo -e "\n3、二台电脑的同号端口相连，不可混连; 例如: eth1连接eth1、eth2连接eth2 依此连接 ... "
echo -e "\n   注意：测试网卡需要二张同端口的网卡，端口数不同的网卡测试只能按照端口少的来连接。"
echo -e "\n4、将另一台电脑作为服务端，运行 "iperf3 -s" 命令\n"
read -p "测试环境配置是否已完成,默认yes,请输入 <yes/no> : " confirm
[ "${confirm:=yes}" != yes ] && echo -e "\n请配置好测试环境，再重新测试 !!! \n" && exit
echo ""

ip addr | awk '/</ {print $0}'
echo -e "\n说明:PCIE网卡端口号从eth1开始 , state UP表示已链接,state DOWN表示未链接\n"
read -p "请输入插入的网卡端口号,默认eth1, 请输入 <eth1/eth2/eth3/eth4> : " port 
read -p "请输入Ping包次数,默认2000, 请输入 <2000-10000> : " count 
[ -n $(echo ${count:=2000} | tr -d [0-9]) ] && count=2000

echo -e "\n开始读取PCI-E插入网卡信息..."
ethernet=$(lspci | grep -i "Ethernet controller")
[ $(echo $ethernet | wc -l) -lt 1 ] && result="识别网卡成功:" || result="未识别插入的PCI-E网卡:"
echo -e "\n$result" | tee -a $log 
echo -e "$ethernet\n" >> $log 

eth_i=$(ethtool -i ${port:=eth1})
[ $? -eq 0 ] && result="读取网卡驱动版本信息成功:" || result="读取网卡驱动版本信息失败:"
echo -e "\n$result" | tee -a $log 
echo -e "$eth_i\n" >> $log 

echo -e "\n开始读取EEPROM信息...\n"
eth_m=$(ethtool -m $port)
[ $? -eq 0 ] && result="读取EEPROM信息成功:" || result="读取EEPROM信息失败:"
echo -e "\n$result\n$eth_m" | tee -a $log 
echo -e "$eth_m\n" >> $log 

echo -e "\n开始读取链路连通状态...\n"
link_cmd=$(ethtool $port)
link_stat=$(echo "$link_cmd" | awk '/Link detected:/{print $3}')
link_speed=$(echo "$link_cmd" |awk '/Speed:/{print int($2)}')
[ "$link_stat" = "yes" -a -n "link_speed" ] && result="链路连通正常:" || result="链路连通失败:"
echo -e "\n$result\n$link_cmd" | tee -a $log 

echo -e "\n开始进行 Ping 包测试...\n"
net_ip=$(ifconfig eth1 | awk '/inet/ && /netmask/ {print $2}')
if [ -n "$(echo $net_ip |  grep 10)" ] ; then
case $port in
 eth1) dest_ip=192.168.6.201 ;;
 eth2) dest_ip=192.168.7.201 ;;
 eth3) dest_ip=192.168.8.201 ;;
 eth4) dest_ip=192.168.9.201 ;;
esac
elif [ -n "$(echo $net_ip |  grep 20)" ] ; then
case  $port in
 eth1) dest_ip=192.168.6.101 ;;
 eth2) dest_ip=192.168.7.101 ;;
 eth3) dest_ip=192.168.8.101 ;;
 eth4) dest_ip=192.168.9.101 ;;
esac
fi
ping -w 2 $dest_ip &> /dev/null && \
ping -c $count -i 0.05 $dest_ip | tee /tmp/ping.log 
ping_head=$(head -n6 /tmp/ping.log)
ping_tail=$(tail /tmp/ping.log)
[ -n "$(echo "$ping_tail" | awk '/0% packet loss/ {print $0}')" ] && result="Ping包成功，无丢包:" || result="Ping包失败或有丢包:"
echo -e "\n$result\n$ping_head\n......\nping_tail" | tee -a $log 

iperf3 -c $dest_ip -t 60 | tee /tmp/iperf.log
iperf_head=$(head -n6 /tmp/iperf.log)
iperf_tail=$(tail /tmp/iperf.log)
[ -n "$(echo "$iperf_tail" | grep "iperf Done")" ] && result="性能测试完成: " || result="性能测试失败: " 
echo -e "\n$result\n$iperf_head\n......\niperf_tail" | tee -a $log 

unix2dos -o $log ; rm -f /tmp/ping.log /tmp/iperf.log
echo -e "\n测试已完成! 测试数据保存在 /tmp/nic_test.txt 中，下次测试会覆盖掉，请及时拷出！！！\n"
