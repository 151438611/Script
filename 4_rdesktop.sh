#!/bin/bash
# Install : apt install rdesktop
# Usage Eamples : bash rdesktop.sh $1_Host $2_User $3_Screen_resolution

echo -e "Usage: bash rdesktop.sh \$1_Host \$2_User \$3_Screen_resolution \nIf Input User/Host is Empty, then User/Host is Default ;\n"

HOST=192.168.20.22
USERNAME=Jun
PASSWORD=
GEOMETRY=1280x960

[ $1 ] && HOST=$1
[ $2 ] && USERNAME=$2
[ $3 ] && GEOMETRY=$3

[ -z "$HOST" -a -z "$USERNAME" ] && echo "RPC Login User or Host not is Empty" && exit 2

option="-g $GEOMETRY -r disk:opt_share=/opt -r sound:local -r clipboard:PRIMARYCLIPBOARD -P -x l -z"
#option="-f -r disk:opt_share=/opt -r sound:local -r clipboard:PRIMARYCLIPBOARD -P -x l -z"

RPC=$(which rdesktop)
[ $RPC ] || { echo "rdesktop : command not found; Please install the command first !" && exit 2; } 

if [ -n "$(pidof rdesktop)" ]; then
	[ "$(ps a | grep $HOST)" ] && echo "The $HOST computer is under remote control !"
else
	exec $RPC -u $USERNAME -p "$PASSWORD" $option $HOST & 
fi
