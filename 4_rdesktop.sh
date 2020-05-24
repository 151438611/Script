#!/bin/bash
# Install : apt install rdesktop
# Usage Eamples : bash rdesktop.sh $1_Host $2_User $3_Password $4_OPTION(user "Option1 Option2 ...")
# 

echo "Usage: bash rdesktop.sh \$1_Host \$2_User \$3_Password "

HOST=192.168.20.22
USERNAME=Jun
PASSWORD=
#OPTION="-g 1280x960 -P -x l -z -r disk:share=/tmp -r sound:local -r clipboard:PRIMARYCLIPBOARD"
OPTION="-P -r disk:share=/tmp -r sound:local -r clipboard:CLIPBOARD"

[ $1 ] && HOST=$1
[ $2 ] && USERNAME=$2
[ "$3" ] && {
	if [ -z "$(echo "$3" | grep \-)" ]; then 
		PASSWORD=$3
		OPTION_O=$4
	else 
		OPTION_O=$3
	fi 	
	}

[ -z "$HOST" -a -z "$USERNAME" ] && echo "RPC Login User or Host not is Empty" && exit 2

RPC=$(which rdesktop)
[ $RPC ] || { echo "rdesktop : command not found; Please install the command first !" && exit 2; } 

if [ -n "$(pgrep -a rdesktop | grep $HOST)" ]; then
	echo "The $HOST computer is under remote control !" 
else
	exec $RPC $HOST -u $USERNAME -p "$PASSWORD" $OPTION $OPTION_O &
fi
