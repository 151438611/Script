#!/bin/bash
# 需要事先创建好目录

minio_exec=/opt/minio
[ -f $minio_exec ] || wget -t 2 -T 8 -O $minio_exec https://dl.min.io/server/minio/release/linux-amd64/minio
[ -x $minio_exec ] || chmod +x $minio_exec

host1="192.168.20.11"
host2="192.168.20.12"
host3="192.168.20.13"
host4="192.168.20.14"
stroage_dir1="/opt/dir1"
stroage_dir2="/opt/dir2"

export MINIO_ACCESS_KEY=10gtek123
export MINIO_SECRET_KEY=10gtek456

$minio server http://$host1$stroage_dir1 http://$host1$stroage_dir2 \
http://$host2$stroage_dir1 http://$host2$stroage_dir2 \
http://$host3$stroage_dir1 http://$host3$stroage_dir2 \
http://$host4$stroage_dir1 http://$host4$stroage_dir2 &
