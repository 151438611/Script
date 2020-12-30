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
	for sf in $scp_files
	do
		# 判断传入的是绝对路径还是相对路径 
		if [ -n "$(echo "$sf" | grep -E "^/|^~")" ]; then
			# 表示传入的是绝对路径
			[ -e "$sf" ] && {
				for host in $hosts
				do 
					scp -r $sf $host:$(dirname $sf) && echo "$sf transfer to $host complete ."
				done
			} || echo "$sf Input File or DIR is no exist !!! "
		else
			# 表示传入的是相对路径,转换成绝对路径
			f_pwd=$(pwd)/$sf
			[ -e "$f_pwd" ] && {
				for host in $hosts
				do 
					scp -r $f_pwd $host:$(dirname $f_pwd) && echo "$f_pwd transfer to $host complete ."
				done
			} || echo "$f_pwd Input File or DIR is no exist !!! "
		fi

	done
else
	echo "Please Input SCP_Source File or DIR !!!"
fi
