#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

subnet=192.168.3.
hosts=/tmp/online_host.txt ; echo "$(arp -n | head -n1)" > $hosts

a=$1 ; b=$2
[ -z "$a" ] && echo "please input Number" && exit
expr $a + 1 &> /dev/null && expr $b + 1 &> /dev/null
[ $? -ne 0 ] && echo "please input Number " && exit 
if [ "$a" = 0 ] ; then
  [ -z "$b" -o "$b" = 0 ] && echo "please input not zero Number" && exit
  unset a
elif [ "$b" = 0 ] ; then unset b
elif [ -n "$b" ] ; then 
	[ "$a" -gt "$b" ] && c=$a && a=$b && b=$c
  [ "$b" -ge 255 ] && echo "It's cann't grate than 255" && exit
fi
[ -n "$a" ] && [ "$a" -ge 255 ] && echo "It's cann't grate than 255" && exit

for x in `seq $a $b`
do
  ping -w 1 $subnet$x 
  [ $? -eq 0 ] && echo "$(arp -n | awk '$1=="'$subnet$x'"{print $0}')" >> $hosts
done
