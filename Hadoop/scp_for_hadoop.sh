#!/bin/bash
# 用于hadoop master自动分发文件或配置到其他主机
# 提前: master和其他主机配置好SSH免密登陆

# 需要分发的主机名或IP地址; 自行填写
host1=master2
host2=slave1
host3=slave2
host4=192.168.200.252
host5=

hosts="$host1 $host2 $host3 $host4 $host5"

scp_files="$@"
if [ -n "$scp_files" ]; then
	for f in $scp_files
	do
		# 判断传入的是绝对路径还是相对路径 
		if [ -n "$(echo $f | grep ^/)" ]; then
			# 表示传入的是绝对路径
			[ -e "$f" ] && {
				for h in $hosts
				do 
					scp -r $f $h:$(dirname $f) && echo "$f transfer to $h complete ."
				done
			} || echo "$f Input File or DIR is no exist!!! "
		else
			# 表示传入的是相对路径,转换成绝对路径
			f_pwd=$(pwd)/$f
			[ -e "$f_pwd" ] && {
				for h in $hosts
				do 
					scp -r $f_pwd $h:$(dirname $f_pwd) && echo "$f_pwd transfer to $h complete ."
				done
			} || echo "$f_pwd Input File or DIR is no exist!!! "
		fi

	done
else
	echo "Please Input SCP_Source File or DIR !!! "
fi