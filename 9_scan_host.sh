#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

subnet="192.168.3."
hosts=/tmp/online_host.txt ; echo echo $(date +"%F %T") > $hosts

a=$1 ; b=$2

[ -n "$(echo $a | tr -d [0-9])" -o -n "$(echo $b | tr -d [0-9])" -o -z "$a" ] && echo "please input Number" && exit

if [ "$a" = 0 ] ; then unset a
  [ -z "$b" -o "$b" = 0 ] && echo "please input not zero Number" && exit
elif [ "$b" = 0 ] ; then unset b
elif [ -n "$b" ] ; then 
  [ "$a" -gt "$b" ] && c=$a && a=$b && b=$c
  [ "$b" -ge 255 ] && echo "It's MaxNum cann't grate than 255" && exit
fi
[ "$a" -ge 255 ] && echo "It's MinNum cann't grate than 255" && exit

for x in `seq $a $b`
do
  ping -w 1 $subnet$x 
  [ $? -eq 0 ] && echo "$(arp -an | awk -F [\(\)] '$2=="'$subnet$x'" {print $0}')" >> $hosts
done
