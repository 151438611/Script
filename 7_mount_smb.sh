#!/bin/sh
# support all Linux
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

fun_mount() {
# $1:username $2:password $3:mount_src $4:mount_dest 
 [ -d "$4" ] || mkdir -p $4
 if [ -z "$(mount | grep "$3 on $4")" ] ; then
   mount -t cifs $3 $4 -o username=$1,password=$2,rw,file_mode=0777,dir_mode=0777,vers=2.0 &> /dev/null || \
   mount -t cifs $3 $4 -o username=$1,password=$2,rw,file_mode=0777,dir_mode=0777,vers=1.0
 fi
}

# === mount 1 ==========================
user=admin
password=administrator
src=//192.168.20.200/Public
dest=/media/hwnas
#fun_mount $user $password $src $dest

# === mount 2 ==========================
user=GCB01 
password="*WGQGf"
src=//192.168.1.250/gc-fae/2018/20181001 
dest=/media/10gtek
#fun_mount $user $password $src $dest 
