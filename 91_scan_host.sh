#!/bin/sh
# support all Linux 
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

subnet=192.168.1.
hosts=/tmp/scan_host.log ; echo -e "$(date +"%F %T") start scan ...... \n" > $hosts

a=$1 ; b=$2
[ -n "$(echo $a | tr -d [0-9])" -o -n "$(echo $b | tr -d [0-9])" -o -z "$a" ] && echo "please input subnet_number" && exit
if [ "$a" = 0 ] ; then unset a
  [ -z "$b" -o "$b" = 0 ] && echo "please input not zero subnet_number" && exit
elif [ "$b" = 0 ] ; then unset b
elif [ -n "$b" ] ; then 
  [ "$a" -gt "$b" ] && c=$a && a=$b && b=$c
  [ "$b" -ge 255 ] && echo "It's Max subnet_number cann't grate than 255" && exit
fi
[ "$a" -ge 255 ] && echo "It's Min subnet_number cann't grate than 255" && exit

for x in `seq $a $b`
do
  ping -w 1 $subnet$x && \
  echo "$(arp -an | awk -F [\(\)] '$2=="'$subnet$x'" {print $0}')" >> $hosts
done
