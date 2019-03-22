#!/bin/sh

grep -qEi "debian|ubuntu" /etc/os-release && os_type=debian
grep -qEi "redhat|centos" /etc/os-release && os_type=redhat
[ -n "$os_type" ] || exit
case $os_type in
  debian)
  etherwake=$(which etherwake)
  [ -n "$etherwake" ] || apt -y install etherwake || exit
  etherwake=$(which etherwake) 
  ;;
  redhat)
  etherwake=$(which ether-wake)
  [ -n "$etherwake" ] || yum -y install net-tools || exit
  etherwake=$(which ether-wake)
  ;;
esac

echo -e "\n1 : 10gtek_windows10_office_computer"
echo "2 : 10gtek_windows2016_test_computer"
echo "3 : 10gtek_centos7_up_computer"
echo "4 : 10gtek_centos7_down_computer"
echo -e "5 : 10gtek_cisco_coding_computer \n"

read -p "Please input a number : " device
[ -n "$device" ] || exit
case $device in
  1) mac=70:85:c2:30:b9:cd ;;
  2) mac=00:d8:61:10:df:a8 ;;
  3) mac=e0:d5:5e:47:ca:ec ;;
  4) mac=00:d8:61:10:df:a2 ;;
  5) mac=48:5b:39:a7:78:5b ;;
  *) echo "Please input 1~5 number" && exit ;;
esac

$etherwake -b $mac &> /dev/null
$etherwake -i eth0 -b $mac &> /dev/null
