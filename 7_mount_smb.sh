#!/bin/sh
# example : mount -t cifs -o username=admin,password=administrator //192.168.20.200/Public /media/hwnas

fun_mount() {
# $1:mount_src $2:mount_dest $3:username $4:password
  [ -d "$2" ] || mkdir -p $2
  [ -z "$(mount | grep "$1 on $2")" ] && \
  mount -t cifs -o username=$3,password=$4 $1 $2
}

# === mount 1 ==========================
src0=//192.168.20.200/Public
dest0=/media/hwnas
user0=admin
password0=administrator
fun_mount $src0 $dest0 $user0 $password0

# === mount 2 ==========================
#src1=
#dest1=
#user1=
#password1=
#fun_mount $src1 $dest1 $user1 $password1
