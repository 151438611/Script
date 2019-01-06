#!/bin/sh
# example : mount -t cifs -o username=admin,password=administrator //192.168.20.200/Public /media/hwnas

fun_mount() {
# $1:username $2:password $3:mount_src $4:mount_dest 
 [ -d "$4" ] || mkdir -p $4
 [ -z "$(mount | grep "$3 on $4")" ] && \
 mount -t cifs -o username=$1,password=$2 $3 $4
}

# === mount 1 ==========================
user0=admin
password0=administrator
src0=//192.168.20.200/Public
dest0=/media/hwnas
fun_mount $user0 $password0 $src0 $dest0

# === mount 2 ==========================
#user1= 
#password1=
#src1= 
#dest1=
#fun_mount $user1 $password1 $src1 $dest1 
