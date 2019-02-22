#!/bin/sh
# 使用scp配合ssh公钥私钥，用来将armbian中的文件同步到jhk2p路由器中保存

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
scplog=/tmp/scp.log ; echo "" >> $rsynclog

src0=/media/sda1/data/script
src1=/media/sda1/data/document
src2=/media/sda1/data/config_bak
src3=
src4=
src5=
src6=
src7=
src8=
src9=
src10=
source="$src0 $src1 $src2 $src3 $src4 $src5 $src6 $src7 $src8 $src9 $src10"

dest_ip=admin@frp.xiongxinyi.cn
dest_dir=/media/AiDisk_a2/data
dest=$dest_ip:$dest_dir
dest_port=17500

scp_fun() {
# $1表示备份的源文件/目录src , $2表示备份的目的目录dest
  scp -r -o "StrictHostKeyChecking no" -P $dest_port $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") scp success $1" >> $scplog || echo "$(date +"%F %T") scp fail--- $1" >> $scplog
}

# === start scp ==============
for src in $source
do
   scp_fun $src $dest
done
 
