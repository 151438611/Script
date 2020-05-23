#!/bin/bash
# Install : apt install rdesktop
# Usage Eamples : bash rdesktop.sh User Host

echo "Usage: bash rdesktop.sh User Host"
echo "If Input User/Host is Empty, then User/Host is Default ;"

HOST=192.168.20.22
USERNAME=Jun
PASSWORD=

[ $1 ] && USERNAME=$1
[ $2 ] && HOST=$2

[ -z "$HOST" -a -z "$USERNAME" ] && echo "RPC Login User or Host not is Empty" && exit 2

option="-g 1280x960 -r disk:opt_share=/opt -r sound:local -r clipboard:PRIMARYCLIPBOARD -P -x l"

#option="-f -r disk:opt_share=/opt -r sound:local -r clipboard:PRIMARYCLIPBOARD -P -x l"

RPC=$(which rdesktop)
[ $RPC ] || { echo "rdesktop : command not found; Please install the command first !" && exit 2; } 

[ "$(pidof rdesktop)" ] || \
	exec $RPC -u $USERNAME -p "$PASSWORD" $option $HOST