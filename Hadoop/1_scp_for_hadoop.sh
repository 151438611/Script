#!/bin/bash
# 用于hadoop master自动分发文件或配置到其他主机
# 提前: master和其他主机配置好SSH免密登陆

# 自行填写: 需要分发的主机名或IP地址; 多个用空格隔开
hosts="slave1 slave2 master"

bule_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}
red_echo() {
	echo -e "\033[31m$1\033[0m"
}

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
					scp -r $sf $host:$(dirname $sf) && bule_echo "$sf transfer to $host complete ."
				done
			} || red_echo "$sf is not exists !!!"
		else
			# 表示传入的是相对路径,转换成绝对路径
			f_pwd=$(pwd)/$sf
			[ -e "$f_pwd" ] && {
				for host in $hosts
				do 
					scp -r $f_pwd $host:$(dirname $f_pwd) && bule_echo "$f_pwd transfer to $host complete ."
				done
			} || red_echo "$f_pwd is not exists !!!"
		fi

	done
else
	yellow_echo "Usage : $0 File_Path or Dir_Path "
fi
