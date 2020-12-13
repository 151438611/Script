#!/bin/bash
# disable someone user to login system
# ¥50
while :
do

	user_all=$(w | awk '/pts/{print $1,$2}' | grep -v root)
	first_user=$(echo "$user_all" | awk 'NR==1 {print $1}')
	other_user_tty=$(echo "$user_all" | grep -v $first_user | awk '{print $2}')
	[ "$other_user_tty" ] && {
		for tty in $other_user_tty
		do
			pkill -kill -t $tty
		done
		}
		sleep 3
	
done
