#!/bin/bash
# 用于万兆通PAE兼容测试岗位 : 自动创建兼容测试模板、邮件编码的核对工作
# 需要文件：需求的邮件编码信息、编码完后的编码压缩zip文件
# 需要软件：apt install zip unzip dos2unix
# Author : XJ  Date: 20180519

clear
# 获取脚本当前路径,并进入脚本目录
cd $(dirname $0)
echo "------------------ 工作模式 ------------------"
echo "1-自动检查编码"
echo "2-手动输入订单号检查编码"
echo "3-创建兼容交换机测试模板文件"
echo "4-整理排板邮件中的产品类型、SN"
echo "5-自动放码：只需放入Port1或Port2，将自动复制到其他Port; 若有Page02放一个并重命名为起始SN即可"
echo "6-创建ZQP-P02全FF的bin文件(适用于SN后4位为非数字编码工具无法生成的场景)---待测试"
echo "7-针对生产写码QSFP/4SFP、ZQP/4ZSP二端SN不一致无法写码，仅修改QSFP端SN命名，和SFP端SN保持一致"
echo ""
result=./result
# 获取需求的邮件编码信息文件
input_txt() {
	input_txt=$(ls -t *.txt | head -n1)
	[ -z "$input_txt" ] && echo -e "\nxx.txt 文件不存在，请重新检查！！！\n" && exit
	dos2unix -q $input_txt
}
# 获取编码完后的编码压缩zip文件
input_zip() {
	input_zip=$(ls -t *.zip | head -n1)
	# 判断是否存在未删除的解压出来的文件夹，删除了再解压刚传入的zip文件,-iname表示忽略大小写
	find ./ -type d -iname "WO*" -exec rm -r {} \; 2> /dev/null
	[ -z "$input_zip" ] && echo -e "\nxx.zip 文件不存在，请重新检查！！！\n" && exit
	unzip -q "$input_zip" || exit
}

older_info() {
# 提取邮件中某个生产订单一整行内容
older_all=$(cat $input_txt | grep -a $older_id)
# 提取内容中的日期,示例：20180515
older_time=$(echo $older_all | awk '{print $1}')
# 提取邮件中的产品SN，示例：S180701230001
older_sn_info=$(echo $older_all | awk '{print $6}')
older_sn=
for sn_start in $older_sn_info
do 
	older_sn=$(echo $older_sn ${sn_start%-*})
done

# 提取邮件中的产品名称，示例：CAB-10GSFP-P3M
older_type=$(echo $older_all | awk '{print $4}') 
# 提取内容中的备注,示例：通用/OEM中性码，VN：Optech，PN：OPQSFP-T-05-PCB
older_remark=$(echo $older_all | awk '{print $8$9$10$11$12}')
[ -z "$older_remark" ] && older_remark="无备注"

# 提取邮件中的需求长度，单位CM/M;判断特殊情况：CAB-10GSFP-P65CM的编码长度位为00
if [ -z "$(echo "$older_type" | grep -i cm)" ]; then
	older_length=$(echo ${older_type%M*} | sed 's/.*\(...\)$/\1/' | sed 's/[a-zA-Z]//g' | sed 's/-//g')
	older_length=$(echo $older_length | awk '{print int($0)}')
else
	if [ -n "$(echo $older_type | grep -i 10sfp)" -a -n "$(echo $older_remark | grep -Ei "h3c|hp")" ]; then 
		older_length=0
	else 
		older_length=1
	fi
fi


# 提取订单编码数量,示例：30
older_num_old=$(echo $older_all | awk '{print $5}')
# 20191119新增10gsfp线缆的MCU方案
older_kind=
[ -n "$(echo $older_all | grep -Ei "10gsfp|0sfp" | grep -i mcu)" ] && older_kind=CiscoMCU
[ -n "$(echo $older_all | grep -Ei "10gsfp|0sfp" | grep -Ei "h3c|hp")" ] && older_kind=H3C
[ -z "$older_kind" ] && older_kind=null
case $older_kind in
"H3C"|"CiscoMCU")
	older_num=$(($older_num_old * 2 + 5)) 
	;;
*)
	if [ -n "$(echo $older_type | grep -Ei "10gsfp|xfp/xfp|0sfp")" ]; then older_num=$(($older_num_old * 3 + 1))
	elif [ -n "$(echo $older_type | grep -Ei "zsp/zsp|xfp/sfp")" ]; then older_num=$(($older_num_old * 2 + 1))
	elif [ -n "$(echo $older_type | grep -Ei "q10/q10|qsfp/qsfp|8644/qsfp|8644/8644|8644/8088|qsfp/8088|q14/q14")" ]; then
		if [ -n "$(echo $older_remark | grep -i mcu)" ]; then 
			older_num=$(($older_num_old * 4 + 5))
		else 
			older_num=$(($older_num_old * 3 + 1))
		fi
	elif [ -n "$(echo $older_type | grep -Ei "q10/4s|qsfp/4sfp|qsfp/4xfp")" ] ; then 
		if [ -n "$(echo $older_remark | grep -i mcu | grep -Ei "h3c|hp")" ]; then 
			older_num=$(($older_num_old * 6 + 11))
		elif [ -n "$(echo $older_remark | grep -i mcu)" ]; then 
			older_num=$(($older_num_old * 6 + 3))
		else 
			older_num=$(($older_num_old * 5 + 1))
		fi
	elif [ -n "$(echo $older_type | grep -Ei "q10/1s|qsfp/1s")" ] ; then
		if [ -n "$(echo $older_remark | grep -i mcu)" ]; then
			older_num=$(($older_num_old * 3 + 3))
		else
			older_num=$(($older_num_old * 2 + 1))
		fi
	elif [ -n "$(echo $older_type | grep -Ei "q10/2s|qsfp/2s")" ] ; then
		if [ -n "$(echo $older_remark | grep -i mcu)" ]; then
			older_num=$(($older_num_old * 4 + 3))
		else
			older_num=$(($older_num_old * 3 + 1))
		fi
	elif [ -n "$(echo $older_type | grep -i "zqp/zqp")" ]; then older_num=$(($older_num_old * 4 + 5))
	elif [ -n "$(echo $older_type | grep -i "zqp/4zsp")" ]; then older_num=$(($older_num_old * 6 + 3))
	elif [ -n "$(echo $older_type | grep -i "zqp/2zqp")" ]; then older_num=$(($older_num_old * 6 + 7))
	elif [ -n "$(echo $older_type | grep -i "zqp/2zsp")" ]; then older_num=$(($older_num_old * 4 + 3))
	else older_num=$older_num_old
	fi 
	;;
esac
# 判断邮件中要求的编码类型，H3C表示H3C码, OEM表示OEM码,默认表示思科兼容
if [ -n "$(echo $older_all | grep -Ei "10gsfp|0sfp" |grep -Ei "h3c|hp")" ]; then older_kind=H3C
# 临时使用---超过200pcs东莞直接收货所以兼容一定要正确, 设置超过100pcs严格按兼容编码
# 20191119新增10gsfp线缆的MCU方案
elif [ -n "$(echo $older_all | grep -Ei "10gsfp|0sfp" |grep -i mcu)" ]; then older_kind=CiscoMCU
elif [ -n "$(echo $older_remark | grep -i oem | grep -i optech)" ]; then older_kind=OEM
elif [ -n "$(echo $older_remark | grep -i juniper)" -a $older_num_old -ge 100 ]; then older_kind=Juniper
elif [ -n "$(echo $older_remark | grep -i arista)" -a $older_num_old -ge 100 ]; then 
	[ -n "$(echo $older_type | grep -Ei "qsfp|q10|zsp")" ] && older_kind=Arista || older_kind=OEM
elif [ -n "$(echo $older_remark | grep -i alcatel)" -a $older_num_old -ge 100 ]; then older_kind="Alcatel-lucent"
elif [ -n "$(echo $older_remark | grep -i brocade)" -a $older_num_old -ge 100 ]; then older_kind=Brocade
elif [ -n "$(echo $older_remark | grep -Ei "dell|force")" -a $older_num_old -ge 100 ]; then 
	[ -n "$(echo $older_type | grep -i 10gsfp)" ] && older_kind=Dell || older_kind=OEM
elif [ -n "$(echo $older_remark | grep -i "mellanox")" -a $older_num_old -ge 100 ]; then 
	[ -n "$(echo $older_type | grep -i zqp)" ] && older_kind=Mellanox || older_kind=OEM
elif [ -n "$(echo $older_remark | grep -Ei "huawei|intel|extreme")" -a $older_num_old -ge 100 ]; then older_kind=OEM
# 非以上备注默认思科码代替
else older_kind=Cisco
fi

}

code_info() {
# 统计编码文件夹下的编码数量，在后面判断是否和邮件中的数量是否一致？
code_num=$(find ./ -type d -name $older_id -exec ls -lR {} \; | grep -c "^-")
# 在编码文件夹中搜索SN号为001.bin或0001.bin的编码文件
code_file=$(find ./ -type f -name ${older_sn}.bin | sort | head -n1)
if [ -n "$code_file" ] ; then
	# hexdump参数： -s偏移量 -n指定字节
	code_file_hex_all=$(hexdump -vC $code_file)
	[ -n "$(echo $older_type | grep -Ei "qsfp|q10|8644|q14")" -a -z "$(echo $older_remark | grep -i mcu)" ] && \
		code_file_hex=$(hexdump -vC $code_file -s 128 -n 256) || code_file_hex=$(hexdump -vC $code_file -n 128) 
	
	# 提取编码中的第0位，03表示SFP类型，06表示XFP类型, 0D表示40G-QSFP, 11表示100G-ZQP，0F表示8644
	code_type=$(echo "$code_file_hex" | awk 'NR==1{print $2}')
	case $code_type in
		"03") code_type="SFP" ;;
		"06") code_type="XFP" ;;
		"0d") code_type="Q10" ;;
		"11") code_type="ZQP" ;;
		"18") code_type="QSFPDD" ;;
		"0f") code_type="8644" ;;
		*) 	code_type="请检查第0位未识别的产品类型代码：$code_type" ;;
	esac
	# 提取编码中的第1行第13位，0C表示千兆，63/67表示10G, FF表示25G, 3C表示6G
	code_speed=$(echo "$code_file_hex" | awk 'NR==1{print $14}')
	case $code_speed in
		"67"|"63"|"64") code_speed="10G" ;;
		"ff") 			code_speed="25G" ;;
		"0c") 			code_speed="1000BASE" ;;
		"3c") 			code_speed="6G" ;;
		"78") 			code_speed="12G" ;;
		"8d") 			code_speed="14G" ;;
		*) 	code_speed="请检查第13位未识别的产品速率代码：$code_speed" ;;
	esac
	[ "$code_type" = "SFP" -a "$code_speed" = "25G" ] && code_type="ZSP"
	[ "$code_type" = "Q10" -a "$code_speed" = "10G" ] && code_type="Q10" && code_speed="40G"
	[ "$code_type" = "Q10" -a "$code_speed" = "14G" ] && code_type="Q14" && code_speed="56G"
	[ "$code_type" = "ZQP" -a "$code_speed" = "25G" ] && code_type="ZQP" && code_speed="100G"
	# 提取编码中的第7行第96位-98位，"48 33 43"表示H3C码, "00 00 00"表示OEM码,因思科码96位不同，所以只判断第97 98位，"00 11"表示思科码
	code_kind=$(echo "$code_file_hex" | awk 'NR==7{print $3,$4}')
	case $code_kind in
		"00 00") 		 code_kind=OEM ;;
		"33 43") 		 code_kind=H3C ;;
		"00 11"|"43 11") code_kind=Cisco ;;
		"34 30"|"34 11") code_kind=Juniper ;;
		"61 20") 		 code_kind=Arista ;;
		"32 30") 		 code_kind="Alcatel-lucent" ;;
		"58 54") 		 code_kind=Extreme ;;
		"47 53") 		 code_kind=Brocade ;;
		"10 00") 		 code_kind=Dell ;;
		"50 A0"|"50 A2") code_kind=HPP ;;
		"41 31") 		 code_kind=Avaya ;;
		"39 32") 		 code_kind=Mellanox ;;
		*) code_kind="请检查LMM加密位的编码兼容类型: $code_kind" ;;
	esac
	# 提取编码中的第2行第4位，表示线缆的长度
	code_length=$(echo "$code_file_hex" | awk 'NR==2{print $4}')
	code_length=$(echo $((0x$code_length)))
	# 提取编码中的第6行日期
	code_time_line=$(echo "$code_file_hex" | awk -F "|" 'NR==6{print $2}')
	code_time=${code_time_line:4:6}
fi
}

check_info() {
# 判断之前先初始化错误信息
error_time=  ; error_type=  ; error_num=  ; error_kind=  ; error_length=
# 核对邮件内容中的日期和编码中的日期是否一致
if [ "${older_time:2}" = "$code_time" ]; then result_time="(ok)"
else
	result_time="(-error!-)"
	error_time="邮件中的日期<${older_time}>和编码日期<${code_time}>不一致，请仔细核对编码日期！！！"
fi
# 核对邮件内容中的产品类型和编码中的是否一致
if [ -n "$(echo $older_type | grep -Ei "qsfp/4sfp|qsfp/4xfp|qsfp/8644|qsfp/8088|8644/8088")" ]; then
	if [ "$code_type" = Q10 -o "$code_type" = 8644 ]; then result_type="(ok)"
	else
		result_type="(-error-)"
		error_type="邮件中的产品名称<${older_type}>和编码类型<${code_type}>不一致，请仔细核对编码类型！！！"
	fi
else
	if [ -n "$(echo $older_type | grep -i $code_type)" ] ; then result_type="(ok)"
	else
		result_type="(-error-)"
		error_type="邮件中的产品名称<${older_type}>和编码类型<${code_type}>不一致，请仔细核对编码类型！！！"
	fi
fi
# 核对邮件内容中的数量和编码中的数量是否一致
if [ $older_num -eq $code_num ] ; then result_num="(ok)"
else
	result_num="(-error!-)"
	error_num="邮件中的数量<${older_num_old}>和编码数量<${code_num}>不一致，请仔细核对编码数量！！！"
fi
# 核对邮件内容中的兼容性和编码中的兼容性是否一致
if [ "$older_kind" = "$code_kind" ] ; then result_kind="(ok)"
# 20191119新增10gsfp线缆的MCU方案
elif [ "$older_kind" = CiscoMCU -a "$code_kind" = Cisco ]; then result_kind="(ok)"
else
	result_kind="(-error!-)"
	error_kind="邮件的兼容<${older_kind}>和编码兼容<${code_kind}>不一致，请仔细核对编码兼容情况！！！"
fi
# 核对邮件内容中的长度和编码中的长度是否一致
if [ $older_length = $code_length ] ; then
	result_length="(ok)"
elif [ $(($older_length - $code_length)) -le 1 ] ; then
	result_length="(ok)"
else 
	result_length="(-error?-)"
	error_length="邮件的长度<${older_length}>和编码长度<${code_length}>不一致，请仔细核对编码兼容情况！！！"
fi
}

check_end() {
# 清除解压出来的编码文件夹
mv -f $input_zip old.zip 2> /dev/null
mv -f $input_txt old.txt 2> /dev/null
deldir=$(find ./ -type d -cmin -2 | grep -v ^./$) && rm -rf $deldir
}
printmark() {
echo "------------------------------------------------------------------------------"
}
read -p "请选择工作模式,***直接回车***退出程序： " mode
echo ""
case $mode in
1)
echo "正在检查,可能需要5~30秒,请稍等......"
input_txt
input_zip
# 提取生产订单列表
echo -e "$(awk '{print $1}' $input_txt | sed -n '1p')编码核对信息汇总：\n" > $result
older_list=$(awk '{print $3}' $input_txt)
for older_id in $older_list
do
	# 判断是否存在生产单号对应的编码文件夹
	if [ -d $older_id ] ; then
		echo "生产订单号${older_id}核对结果：" >> $result
		older_info
		code_info
		if [ -n "$code_file" ] ; then
			check_info
			# 输出检查结果信息
			echo "邮件日期:${older_time} 产品名称:${older_type} 数量:${older_num_old} 备注:${older_remark}" >> $result
			echo "编码日期:${code_time}${result_time} 产品类型:${code_type}${result_type} 长度:${code_length}米${result_length} 数量:${code_num}${result_num} 速率:${code_speed} 兼容<200pcs以下默认思科兼容>:${code_kind}${result_kind}" >> $result
			# 判断是否出现编码错误，出错就输出错误信息和编码中的十六进制文件。
			if [ -n "${error_time}${error_type}${error_num}${error_kind}${error_length}" ] ; then
				#echo ${error_time}${error_type}${error_num}${error_kind}${error_length} >> $result
				printmark >> $result
				echo "$code_file_hex_all" | head -n16 >> $result
			fi
		else
			echo "没有找到SN为 "$older_sn" 编码！！！" >> $result
			continue
		fi
	else
		echo "没有找到${older_id}对应的编码文件夹,请重新检查！！！" >> $result 
		echo $(unzip -l $input_zip | awk -F / '/WO/{print $1}' | awk '{print $4}' | sort -u) >> $result
	fi
	printmark >> $result
	echo >> $result
done
check_end
echo -e "\n---检查完成！结果保存在result文件中,下次运行会自动覆盖,请及时查看(方法:cat result)!---\n"
;;

2)
echo "正在准备手动检查编码......"
input_txt
input_zip
while [ true ]
do
	echo ""
	read -p "请输入需要核对的生产订单号,***直接回车***退出手动检查：" scdh
	# 判断手输的生产单号是否存在邮件内容中，思路：生产单号是唯一的，判断唯一
	echo ""
	[ -z $scdh ] && echo -e "正在退出手动检查编码......\n" && check_end && break 
	if [ $(cat $input_txt | awk '{print $3}' | grep -c $scdh 2>/dev/null) -eq 1 ]; then
		# 提取手输的生产订单号全称，示例：WO180500115
		older_id=$(cat $input_txt | awk '{print $3}' | grep $scdh) 
		# 判断是否存在生产单号对应的编码文件夹
		if [ -d $older_id ]; then 
			older_info
			code_info
			if [ -n "$code_file" ]; then 
			check_info
			# 输出检查结果信息
			echo "生产订单号：${older_id}"
			echo "邮件日期:${older_time} 产品名称:${older_type} 数量:${older_num_old} 备注:${older_remark}"
			echo -e "编码日期:${code_time}\033[43;30m${result_time}\033[0m 产品类型:${code_type}\033[43;30m${result_type}\033[0m 长度:${code_length}米\033[43;30m${result_length}\033[0m 数量:${code_num}\033[43;30m${result_num}\033[0m 速率:${code_speed} 兼容<200pcs以下默认思科兼容>:${code_kind}\033[43;30m${result_kind}\033[0m"
			# 判断是否出现编码错误，出错就输出错误信息和编码中的十六进制文件。
			[ -n "${error_time}${error_type}${error_num}${error_kind}${error_length}" ] && echo "${error_time}${error_type}${error_num}${error_kind}${error_length}"
			printmark
			# 输出编码中的十六进制文件，仅输出20行。
			echo "$code_file_hex_all" | head -n16 
			else echo -e "\n没有找到SN为${older_sn}编码！！！"
			fi
		else
			echo "没有找到对应的编码文件夹,请重新检查！！！" 
			# 显示编码压缩文件中的目录内容
			echo $(unzip -l $input_zip | awk -F / '/WO/{print $1}' | awk '{print $4","}' | sort -u)
		fi
	else echo -e "\n请重新输入完整、正确的生产单号！！！" ;  continue
	fi
done
check_end
;;

3)
# 功能：自动创建以产品名＋交换机命名的模板文件；
read -p "请输入产品名称(多个请用空格隔开)：" product
[ -z "$product" ] && echo -e "\n请输入正确的产品名称！！！\n" && exit
read -p "请输入产品速率(100m、1g、10g、25g、40g、56g、100g)：" speed
case $speed in
"100m")
swtich="Cisco-2960
Cisco-2960G
H3C-S3100V2
Huawei-S3700
Huawei-S5700"
;;
"1g")
swtich="Arista-7050
Cisco-2960
Cisco-2960G
Cisco-3560
Cisco-3064
Cisco-5548
Cisco-3232C
Cisco-92160
Dell-ForceS4810
Edgecore-5712
H3C-S3100V2
H3C-S5120
HP-2910
HP-5900
Huawei-S3700
Huawei-S5700
Huawei-CE6855
IBM-G8264
Mikrotik-CRS309_1G_8S+PC
Juniper-QFX5100"
;;
"10g"|"25g")
swtich="Arista-7050
Cisco-3064
Cisco-5548
Cisco-3232C
Cisco-92160
Dell-ForceS4810
Edgecore-5712
H3C-S5120
HP-2910
HP-5900
Huawei-S5700
Huawei-CE6855
IBM-G8264
Mikrotik-CRS309_1G_8S+PC
Juniper-QFX5100"
;;
"40g"|"56g")
swtich="Arista-7050
Cisco-3064
Cisco-5548
Cisco-3232C
Cisco-92160
Dell-ForceS4810
Edgecore-5712
HP-5900
Huawei-CE6855
IBM-G8264
Mellanox-SB7800
Juniper-QFX5200
Juniper-QFX5100"
;;
"100g"|"200g")
swtich="Cisco-3232C
Cisco-92160
Mellanox-SB7800
Juniper-QFX5200"
;;
*)
echo -e "\n请输入正确的速率类型！！！\n" && exit
# 现在交换机汇总列表
swtich="Arista-7050
Cisco-2960
Cisco-2960G
Cisco-3560
Cisco-3064
Cisco-5548
Cisco-3232C
Dell-ForceS4810
Edgecore-5712
Edgecore-7712
H3C-S3100V2
H3C-S5120
HP-2910
HP-5900
Huawei-S3700
Huawei-S5700
IBM-G8264
Mikrotik-CRS309_1G_8S+PC
Mellanox-SB7800
Juniper-QFX5200
Juniper-QFX5100"
;;
esac

for pr in $product
do
	pr=$(echo $pr | sed '{s/\//-/g ; s/ //g}')
	[ -n "$(echo $pr | grep "^-")" ] && echo -e "\n文件名不能以 - 开头，请检查输入的产品名称！！！" && continue 
	[ -d $pr ] && rm -rf ${pr}/* || mkdir -p $pr
	for sw in $swtich
	do
		sw=$(echo $sw | sed '{s/\//-/g ; s/ //g}')
		sw_file="${pr}/${pr}-${sw}.txt"
		# 添加测试模板格式到文本文件中：指示灯、基本信息、DDM信息
		if [ -n "$(echo $sw | grep -i "edgecore")" ]; then name="Cisco"
		elif [ -n "$(echo $sw | grep -i "hp")" ]; then 
			echo $sw | grep -qi "2910" && name="HPP" || name="H3C"
		else name=$(echo $sw | awk -F"-" '{print $1}')
		fi
		if [ -n "$(echo $pr | grep -Ei "cab|aoc|-t")" ]; then
			echo -e "$name code , Indictor_light is UP/DOWN , Basic_infomation is OK/ERROR , DDM is NONE .\n\n" > $sw_file
		else
			echo -e "$name code , Indictor_light is UP/DOWN , Basic_infomation is OK/ERROR , DDM is OK/ERROR .\n\n" > $sw_file
		fi
		unix2dos -q $sw_file
	done
done
# 将创建好的文件夹打包，并删除原文件,方便拷出
dir=$(find ./ -type d -cmin -1 | grep -v "^./$")
dir_name="$(date +%Y%m%d-%H%M%S).tar"
tar --remove-files -cf $dir_name $dir && echo -e "\n----------测试模板文件"$dir_name"创建完成!----------\n"
;;

4)
# 用来提取邮件中的SN号，并整理排板好
input_txt
echo "-------------- 产品类型 ------------"
awk '{print $4}' $input_txt | awk -F"M" '{print $1"M"}'
echo "-------------- 起始SN --------------"
#awk '{print $6}' $input_txt | awk -F"-" '{print $1}'
snall=$(awk '{print $6}' $input_txt)
for sn_start in $snall
do 
	echo ${sn_start%-*}
done
echo "-------------- 截止SN --------------"
for sn_end in $snall
do 
	sn_st=${sn_end%-*}
	if [ -n "$(echo $sn_end | grep "-")" ] ; then
		sn_en=$(echo ${sn_end##*-})
		num1=${#sn_en}
		echo "${sn_st: 0: -$num1}$sn_en"
	else 
		echo "$sn_end"
	fi
done
echo -e "-------------- 整理完成 ------------\n"
mv -f $input_txt old.txt 2> /dev/null
;;

5)
echo -e "需求：\n1、首先复制相应放码模板，并以生产订单号命名"
echo "2、使用相应编码软件编码，并放入模板第一个Port文件夹中即可"
echo "3、若QSFP、ZQP是MCU方案放Page02.bin并重命名为起始SN,一个即可"
input_txt
input_zip
copy_page02() {
	# 查找订单下面是否有Page02文件夹，并找出起始SN的编码,然后开始复制 ......
	if [ -d "${older_id}/Port1/Page02" ]; then
		page02_sn=$(find ${older_id}/Port1/Page02/ -type f -iname "${older_sn}*")
		cp_num=$older_num
		if [ -n "$page02_sn" -a "$cp_num" -gt 1 ]; then
			dir_file=$(dirname $page02_sn)
			p02_name=$(basename $page02_sn)
			p02_name_start=${p02_name%.*}
			p02_name_start_4s=${p02_name_start: 0: -4}
			p02_name_start_4e=${p02_name_start: -4}
			p02_name_start_4e=$(echo $p02_name_start_4e | awk '{print int($0)}')
			p02_name_end=${p02_name#*.}
			# 因起始SN存在，则总数需要减1
			cp_num=$(($cp_num - 1))
			for n in $(seq $cp_num)
			do
				sum_end=$(($p02_name_start_4e + $n))
				cp -n $page02_sn ${dir_file}/${p02_name_start_4s}$(printf %04d $sum_end).${p02_name_end}
			done
		else
			[ "$cp_num" -eq 1 ] && echo "${older_id}/Port1/Page02/ 下SN数量为1个！！！" || \
			echo "${older_id}/Port1/Page02/ 下SN文件不存在！！！" 
		fi
	fi
}
# cp选项: -r递归 -n不覆盖同名文件 -f覆盖同名文件
sfp_eeprom_mcu() {
	if [ -d $1/Port2 ]; then
		[ -d $1/Port5 ] && cp -rn $1/Port2/* $1/Port5/
		[ ! -d $1/Port2/A2 ] && cp -n $1/Port2/A0/* $1/
	else
		echo "$1/Port2 文件夹不存在，调用 sfp_eeprom_mcu 模板错误！！！" && continue
	fi
}
zsp_eeprom() {
	if [ -d $1/Port2 ]; then
		[ -d $1/Port5 ] && cp -rn $1/Port2/* $1/Port5/
	else
		echo "$1/Port2 文件夹不存在，调用 zsp_eeprom 模板错误！！！" && continue
	fi
}
qsfp_zqp_2zqp_eeprom_mcu() {
	if [ -d $1/Port1 ]; then
		[ -d $1/Port2 ] && cp -rn $1/Port1/* $1/Port2/
		[ -d $1/Port6 ] && cp -rn $1/Port1/* $1/Port6/
		[ -d $1/Port1/A0 ] && cp -n $1/Port1/A0/* $1/
	else 
		echo "$1/Port1 文件夹不存在，调用 qsfp_zqp_2zqp_eeprom_mcu 模板错误！！！" && continue
	fi
}
qsfp_4sfp_zqp_4zsp() {
	if [ -d $1/Port2 ]; then
		[ -d $1/Port3 ] && cp -rn $1/Port2/* $1/Port3/
		[ -d $1/Port4 ] && cp -rn $1/Port2/* $1/Port4/
		[ -d $1/Port5 ] && cp -rn $1/Port2/* $1/Port5/
	else 
		echo "$1/Port2 文件夹不存在，调用 qsfp_4sfp_zqp_4zsp 模板错误！！！" && continue
	fi
}

older_list=$(awk '{print $3}' $input_txt)
for older_id in $older_list
do
	# 提取邮件中某个生产订单一整行内容
	older_all=$(cat $input_txt | grep -a $older_id)
	# 提取邮件中的产品名称，示例：CAB-10GSFP-P3M
	older_type=$(echo $older_all | awk '{print $4}')
	# 提取邮件中的产品SN，示例：S180701230001
	older_sn=$(echo $older_all | awk '{print $6}' | awk -F"-" '{print $1}') 
	# 提取订单编码数量,示例：30
	older_num=$(echo $older_all | awk '{print $5}')
	if [ -n "$(echo $older_type | grep -Ei "10gsfp|0sfp")" ]; then
		sfp_eeprom_mcu $older_id
	elif [ -n "$(echo $older_type | grep -i "zsp/zsp")" ]; then
		zsp_eeprom $older_id
	elif [ -n "$(echo $older_type | grep -Ei "q10/4s|qsfp/4sfp|zqp/4zsp|qsfp/4xfp|q10/2s|q10/1s|zqp/2zsp")" ]; then
		copy_page02
		qsfp_4sfp_zqp_4zsp $older_id
	elif [ -n "$(echo $older_type | grep -Ei "q10/q10|qsfp/qsfp|zqp/zqp|zqp/2zqp|q14/q14|8644/8644|8644/8088|qsfp/8088")" ]; then
		copy_page02
		qsfp_zqp_2zqp_eeprom_mcu $older_id
	else 
		echo "没有匹配到 $older_id 订单的产品类型！！！"
	fi
done
dir_name="$(date +%Y%m%d-%H%M%S).zip"
zip -qrm $dir_name $older_list && echo -e "\n----------放码完成! $dir_name ----------\n"
rm -f old.zip $input_zip
;;

6)
echo "1、将zqp_p02.bin放入脚本根目录"
echo "2、SN最后4位为数字 "
if [ -f zqp_p02.bin ]; then
  read -p "请输入起始SN：" sn_start
  read -p "请输入需要生成SN的数量：" sn_end
  if [ -z "$sn_start" -o -z "$sn_end" ]; then
	echo "SN或数量不能为空，请重新输入" && exit
  elif [ -n "$(echo "$sn_end" | sed 's/[0-9]//g')" ]; then
	echo "数量输入错误，不能包含字母" && exit
  fi
	# 去掉数字前面的0
	sn_end=$(echo $sn_end | awk '{print int($0)}')
	sn_start_st=${sn_start: 0: -4}
	sn_start_en=${sn_start: -4}
	sn_start_en=$(echo $sn_start_en | awk '{print int($0)}')
	for sn in $(seq $sn_end)
	do 
		cp -f zqp_p02.bin ${sn_start_st}$(printf %04d $sn_start_en).bin
		sn_start_en=$((sn_start_en + 1))
	done
	tar --remove-file -cf ${sn_start}.tar ${sn_start_st}*

else 
  echo "zqp_p02.bin文件不存在，请放入全FF的bin文件，并命名为：zqp_p02.bin ！"
fi
;;
7)
echo "针对生产线缆QSFP/4SFP、ZQP/4ZSP写码，仅Q和S端SN不一样，所有S端都是同一SN的情况"
echo "解决方法：按照正常编码，编码完将Q端的码文件重命名为S端名字，Q端和S端SN从小到大一一对应"
input_zip
older_all=$(find ./ -type d -name "WO*")
for older in $older_all
do
	# QSFP-EEPROM 模板目录为 Port1/A0
	port1=$older/Port1/A0/
	# QSFP/ZQP-MCU 模板目录为 Port1/LMM Page00 Page02
	[ ! -d "$port1" ] && port1=$older/Port1/Page00/ && port1_p02=$older/Port1/Page02/
	# SFP/ZSP 模板目录为:  Port2/A0
	port2=$older/Port2/A0/
	
	qsfpAllSN=$(ls $port1) 
	sfpAllSN=$(ls $port2)
	
	allNum=$(echo "$qsfpAllSN" | wc -l)
	
	[ -d "$port1_p02" ] && [ $(ls $port1_p02 | wc -l) -ne $(echo "$sfpAllSN" | wc -l) ] && echo "QSFP端Page02 和 SFP端 SN数量不一致,请检查 ！！！" && exit
	[ $allNum -ne $(echo "$sfpAllSN" | wc -l) ] && echo "QSFP端 和 SFP端 SN数量不一致,请检查 ！！！" && exit
	for num in $(seq $allNum)
	do
		qsfpSN=$(echo "$qsfpAllSN" | awk 'NR=="'$num'"{print $0}')
		sfpSN=$(echo "$sfpAllSN" | awk 'NR=="'$num'"{print $0}')
		mv -f ${port1}$qsfpSN ${port1}$sfpSN
		[ -d "$port1_p02" ] && mv -f ${port1_p02}$qsfpSN ${port1_p02}$sfpSN
	done
done
dir_name="$(date +%Y%m%d-%H%M%S).tar"
tar --remove-files -cf $dir_name $older_all && echo -e "\n----------重命名文件 ${dir_name} 创建完成!----------\n"
check_end
;;

*)
	echo -e "请输入正确的工作模式！！！\n"	
;;
esac
