#!/bin/bash
# "Usage: bash rdesktop.sh User Host ;"

echo "Usage: bash rdesktop.sh User Host ;"

host=192.168.20.22
rpd_user=Jun
rpd_passwd=

[ $1 ] && rpd_user=$1
[ $2 ] && host=$2

[ -z "$host" -a -z "$rpd_user" ] && echo "RPC User or Host_IP not is Empty" && exit 2

option="-g 1280x960 -r disk:opt_share=/opt -r sound:local -r clipboard:PRIMARYCLIPBOARD -P -x l"

#option="-f -r disk:opt_share=/opt -r sound:local -r clipboard:PRIMARYCLIPBOARD -P -x l"

[ "$(pidof rdesktop)" ] || \
	exec rdesktop -u $rpd_user -p "$rpd_passwd" $option $host
