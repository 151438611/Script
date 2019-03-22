#!/bin/sh

grep -qEi "debian|ubutu" /etc/os-release && os_type=debian
grep -qEi "redhat|centos" /etc/os-release && os_type=redhat

case $os_type in
  debian)
  etherwake=$(which etherwake) 
  [ -z "$etherwake" ] && apt -y install etherwake || exit
  ;;
  redhat)
  etherwake=$(which ether-wake)
  [ -z "$etherwake" ] && yum -y install ether-wake || exit
  ;;
esac

echo "1 : 10gtek_windows10_office_computer"
echo "2 : 10gtek_windows2016_test_computer"
echo "3 : 10gtek_centos7_up_computer"
echo "4 : 10gtek_centos7_down_computer"
read -p "Please input a number : " device
[ -n "$device" ] || exit
case $device in
  1) mac=70:85:c2:30:b9:cd ;;
  2) mac=00:d8:61:10:df:a8 ;;
  3) mac=e0:d5:5e:47:ca:ec ;;
  4) mac=00:d8:61:10:df:a2 ;;
  *) echo "Please input 1~4 number" && exit ;;
esac

$etherwake -b $mac || $etherwake -i eth0 -b $mac
