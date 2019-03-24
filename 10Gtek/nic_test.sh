#!/bin/sh
# 用于在Centos测试电脑上进行网卡测试

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
log="/tmp/nictest.txt" ; date +"%F %T" > $log
clear
echo -e "\n测试环境要求："
echo -e "\n1、测试电脑1(上)需配置IP信息：eth1:192.168.6.101 eth2:192.168.7.101 eth3:192.168.8.101 eth4:192.168.9.101"
echo -e "\n2、测试电脑2(下)需配置IP信息：eth1:192.168.6.201 eth2:192.168.7.201 eth3:192.168.8.201 eth4:192.168.9.201"
echo -e "\n3、二台电脑的同号端口相连，不可混连; 例如: eth1连接eth1、eth2连接eth2 依此连接 ... "
echo -e "\n   注意：尽量使用端口数量相同的网卡，端口数不同的网卡测试只能按照端口少的相应端口连接。"
echo -e "\n4、在另一台电脑上运行 "iperf3 -s" 命令，作为服务端，本机作为客户端测试\n"
read -p "确认测试环境配置是否已完成,默认yes,请输入 <yes/no> : " confirm
[ "${confirm:=yes}" != yes ] && echo -e "\n请配置好测试环境，再重新测试 !!! \n" && exit

echo -e "\n所有网卡端口号列表:  (说明:state UP表示端口已链接,state DOWN表示端口未链接)"
ip addr | awk '/</ {print $0}'
echo ""
read -p "请输入连接的网卡端口号,默认eth1, 请输入 <eth1/eth2/eth3/eth4> : " port 
echo ""
read -p "请输入Ping包次数,默认2000次, 请输入 <2000-10000> : " count 
[ -n $(echo ${count:=2000} | tr -d [0-9]) ] && count=2000
echo ""
read -p "请输入iperf3性能测试时长,默认60秒, 请输入自定义时间，单位为秒 : " iperf_time
[ -n $(echo ${iperf_time:=60} | tr -d [0-9]) ] && iperf_time=60

echo -e "\n开始自动进行测试: "
echo -e "\n正在读取PCI-E插入网卡信息..."
ethernet=$(lspci | grep -i "Ethernet controller")
if [ $(echo $ethernet | wc -l) -lt 1 ] ; then 
  result="识别网卡成功:"
  echo -e "\n$result" | tee -a $log 
  echo -e "$ethernet\n" >> $log 
else 
  result="未识别插入的PCI-E网卡"
  echo -e "\n$result,请重新检查是否已插好,再来测试 !!!\n" && exit
fi


eth_i=$(ethtool -i ${port:=eth1} 2> /dev/null)
[ $? -eq 0 ] && result="读取网卡驱动版本信息成功:" || result="读取网卡驱动版本信息失败:"
echo -e "\n$result" | tee -a $log 
echo -e "$eth_i" >> $log 

echo -e "\n正在读取EEPROM信息..."
eth_m=$(ethtool -m $port 2> /dev/null)
[ $? -eq 0 ] && result="读取EEPROM信息成功:" || result="读取EEPROM信息失败:"
echo -e "\n$result\n$eth_m" | tee -a $log 
echo -e "$eth_m" >> $log 

echo -e "\n正在读取链路连通状态...\n"
link_cmd=$(ethtool $port 2> /dev/null)
link_stat=$(echo "$link_cmd" | awk '/Link detected:/{print $3}')
link_speed=$(echo "$link_cmd" |awk '/Speed:/{print int($2)}')
[ "$link_stat" = "yes" -a -n "link_speed" ] && result="链路已连通,速率为 ${link_speed}Mb/s :" || result="链路连通失败:"
echo -e "\n$result" | tee -a $log
echo "$link_cmd" >> $log 

echo -e "\n正在进行 $count 次的 Ping 包测试..."
net_ip=$(ifconfig eth1 2> /dev/null | awk '/inet/ && /netmask/ {print $2}')
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
ping -c $count -i 0.05 $dest_ip 2> /dev/null | tee /tmp/ping.log 
ping_head=$(head -n6 /tmp/ping.log 2> /dev/null)
ping_tail=$(tail /tmp/ping.log 2> /dev/null)
[ -n "$(echo "$ping_tail" | awk '/0% packet loss/ {print $0}')" ] && result="Ping包成功,无丢包:" || result="Ping包失败,或有丢包:"
echo -e "\n$result" | tee -a $log
echo -e "$ping_head\n......\nping_tail" >> $log

echo -e "\n正在进行 $iperf_time 秒的 iperf3 性能测试..."
iperf3 -c $dest_ip -t 60 | tee /tmp/iperf.log
iperf_head=$(head -n6 /tmp/iperf.log 2> /dev/null)
iperf_tail=$(tail /tmp/iperf.log 2> /dev/null)
[ -n "$(echo "$iperf_tail" | grep "iperf Done")" ] && result="性能测试完成: " || result="性能测试失败: " 
echo -e "\n$result" | tee -a $log
echo -e "$iperf_head\n......\niperf_tail" >> $log 

unix2dos -o $log ; rm -f /tmp/ping.log /tmp/iperf.log
echo -e "\n测试已完成! 测试数据保存在 /tmp/nictest.txt 中，下次测试会覆盖掉，请及时拷出！！！\n"

