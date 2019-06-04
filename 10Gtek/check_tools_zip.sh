#!/bin/bash
# 用于万兆通PAE兼容测试岗位 : 自动创建兼容测试模板、邮件编码的核对工作
# 需要文件：需求的邮件编码信息、编码完后的编码压缩zip文件
# 需要软件：zip dos2unix
# Author : XJ  Date: 20180519

#获取脚本当前路径,并进入脚本目录
cd `dirname $0`  ;  clear
echo "------------------工作模式------------------"
echo "1-自动检查编码"
echo "2-手动检查编码"
echo "3-创建兼容测试模板文件"
echo "4-整理排板邮件中的产品类型、SN"
echo "5-汇总产品验证结果，输出到result.txt文件中"
echo "6-创建ZQP-P02全FF的bin文件(适用于SN后4位为非数字编码工具无法生成的场景)"
echo ""
result=./result
#获取需求的邮件编码信息文件
input_txt() {
input_txt=$(ls -t *.txt | head -n1)
[ -z "$input_txt" ] && echo -e "\ntxt文件不存在，请重新检查！！！\n" && exit
dos2unix -o $input_txt 2> /dev/null
}
#获取编码完后的编码压缩zip文件
input_zip() {
input_zip=$(ls -t *.zip | head -n1)
#判断是否存在未删除的解压出来的文件夹，删除了再解压刚传入的zip文件,-iname表示忽略大小写
ls | grep -qi "wo" && find . -type d -iname "WO*" -exec rm -rf {} \; 2> /dev/null
[ -z "$input_zip" ] && echo -e "\nzip文件不存在，请重新检查！！！\n" && exit
unzip -o "$input_zip" 1> /dev/null || exit
}

older_info() {
#提取邮件中某个生产订单一整行内容
older_all=$(cat $input_txt | grep -a $older_id)
#提取邮件中的产品名称，示例：CAB-10GSFP-P3M
older_type=$(echo $older_all | awk '{print $4}') 
#提取邮件中的产品SN，示例：S180701230001
older_sn=$(echo $older_all | awk '{print $6}' | awk -F"-" '{print $1}') 
#提取邮件中的需求长度，单位CM/M;判断特殊情况：CAB-10GSFP-P65CM的编码长度位为00
if [ -z "$(echo "$older_type" | grep -i "cm")" ] ; then
	older_length=$(echo ${older_type%M*} | sed 's/.*\(...\)$/\1/' | sed 's/[a-zA-Z]//g' | sed 's/-//g')
else
	if [ -z "$(echo $older_all | awk '{print $8}' | grep -i "h3c")" ] ; then older_length=1 ; else older_length=0 ; fi
fi
#提取内容中的日期,示例：20180515
older_time=$(echo $older_all | awk '{print $1}')
#判断邮件中要求的编码类型，H3C表示H3C码, OEM表示OEM码,默认表示思科兼容
if [ -n "$(echo $older_all | awk '{print $8}' | grep -Ei "h3c|hp")" ] ; then older_kind="H3C"
elif [ -n "$(echo $older_all | awk '{print $8}' | grep -i "oem")" ] ; then older_kind="OEM"
elif [ -n "$(echo $older_all | awk '{print $8}' | grep -i "juniper")" ] ; then older_kind="Juniper"
else older_kind="Cisco"
fi
#提取订单编码数量,示例：30
older_num_old=$(echo $older_all | awk '{print $5}')
case $older_kind in
"H3C")
	older_num=$((older_num_old * 2 + 5)) ;;
*)
	if [ -n "$(echo $older_type | grep -Ei "10gsfp|xfp/xfp|sfp-sfp")" ] ; then older_num=$(($older_num_old * 3 + 1))
	elif [ -n "$(echo $older_type | grep -Ei "zsp/zsp|xfp/sfp")" ] ; then older_num=$(($older_num_old * 2 + 1))
	elif [ -n "$(echo $older_type | grep -i "zqp/2zqp")" ] ; then older_num=$((($older_num_old * 2 + 2) * 3 + 1))
	elif [ -n "$(echo $older_type | grep -i "zqp/4zsp")" ] ; then older_num=$(($older_num_old * 6 + 3))
	elif [ -n "$(echo $older_type | grep -i "zqp/2zsp")" ] ; then older_num=$(($older_num_old * 4 + 3))
	elif [ -n "$(echo $older_type | grep -Ei "q10/4s|qsfp/4sfp|qsfp/4xfp")" ] ; then older_num=$(($older_num_old * 7 + 1))
	elif [ -n "$(echo $older_all | awk '/[qQ]10\/[qQ]10/&&/[mM][cC][uU]/{print $0}')" -o -n "$(echo $older_type | grep -i "zqp/zqp")" ]; then
	  older_num=$(($older_num_old * 4 + 5))
	elif [ -n "$(echo $older_all | awk '/[qQ]10\/4[sS]/&&/[mM][cC][uU]/{print $0}')" ]; then older_num=$(($older_num_old * 6 + 3))
	elif [ -n "$(echo $older_type | grep -Ei "q10/q10|qsfp/8088|8644/8644|8644/qsfp|8644/8088")" ] ; then older_num=$(($older_num_old * 2 + 1))
	else older_num=$older_num_old
	fi ;;
	esac
}

code_info() {
#统计编码文件夹下的编码数量，在后面判断是否和邮件中的数量是否一致？
code_num=$(find ./ -type d -name $older_id -exec ls -lR {} \; | grep -c "^-")
#在编码文件夹中搜索SN号为001.bin或0001.bin的编码文件
code_file=$(find ./ -type f -name "$older_sn".bin | sort | head -n1)
if [ -n "$code_file" ] ; then
	code_file_hex_all=$(hexdump -vC $code_file)
	[ -z "$(echo $older_type | grep -Ei "qsfp|q10")" -o -n "$(echo $older_all | grep -i "mcu")" ] && \
	code_file_hex=$(hexdump -vC $code_file -n 128) || code_file_hex=$(hexdump -vC $code_file -s 128 -n 256)
	#提取编码中的第1位，03表示SFP类型，06表示XFP类型, 0D表示40G-QSFP, 11表示100G-ZQP，0F表示8644
	code_type=$(echo "$code_file_hex" | awk 'NR==1{print $2}')
	case $code_type in
	"03") code_type="SFP" ;;
	"06") code_type="XFP" ;;
	"0d") code_type="Q10" ;;
	"11") code_type="ZQP" ;;
	"18") code_type="QSFP-DD" ;;
	"0f") code_type="8644" ;;
	*) code_type="请检查第0位产品类型代码：$code_type" ;;
	esac
	#提取编码中的第1行第14位，0C表示千兆，63/67表示10G, FF表示25G, 3C表示6G
	code_speed=$(echo "$code_file_hex" | awk 'NR==1{print $14}')
	case $code_speed in
	"0c") code_speed="1000BASE" ;;
	"3c") code_speed="6G" ;;
	"63"|"64"|"67") code_speed="10G" ;;
	"ff") code_speed="25G" ;;
	*) code_speed="请检查第13位产品速率代码：$code_speed" ;;
	esac
	[ "$code_type" = "SFP" -a "$code_speed" = "25G" ] && code_type="ZSP"
	#提取编码中的第7行第96位-98位，"48 33 43"表示H3C码, “00 00 00”表示OEM码,因思科码96位不同，所以只判断第97 98位，"00 11"表示思科码
	code_kind=$(echo "$code_file_hex" | awk 'NR==7{print $3,$4}')
	case $code_kind in
	"00 00") code_kind="OEM" ;;
	"33 43") code_kind="H3C" ;;
	"00 11"|"43 11") code_kind="Cisco" ;;
	"34 30"|"34 11") code_kind="Juniper" ;;
	"58 54") code_kind="Extreme" ;;
	*) code_kind="请检查LMM加密位的编码兼容类型:$code_kind" ;;
	esac
	#提取编码中的第2行第4位，表示线缆的长度
	code_length=$(echo "$code_file_hex" | awk 'NR==2{print $4}')
	code_length=$(echo $((0x$code_length)))
	#提取编码中的第6行日期
	code_time_line=$(echo "$code_file_hex" | awk -F "|" 'NR==6{print $2}')
	code_time=${code_time_line:4:6}
	[ "$code_type" = "SFP" -a "$code_speed" = "25G" ] && code_type="ZSP"
	[ "$code_type" = "Q10" -a "$code_speed" = "10G" ] && code_speed="40G"
	[ "$code_type" = "ZQP" -a "$code_speed" = "25G" ] && code_speed="100G"
fi
}

check_info() {
#判断之前先初始化错误信息
error_time=  ;  error_type=  ;  error_num=  ;  error_kind=  
#核对邮件内容中的日期和编码中的日期是否一致
if [ "${older_time:2}" = "$code_time" ] ; then result_time="(ok)"
else
	result_time="(-error!-)"
	error_time="邮件中的日期<"$older_time">和编码日期<"$code_time">不一致，请仔细核对编码日期！！！"
fi
#核对邮件内容中的产品类型和编码中的是否一致
if [ -n "$(echo $older_type | grep -i "qsfp")" ] ; then
	if [ "$code_type" = "Q10" -o "$code_type" = "8644" ] ; then result_type="(ok)"
	else
		result_type="(-error-)"
		error_type="邮件中的产品名称<"$older_type">和编码类型<"$code_type">不一致，请仔细核对编码类型！！！"
	fi
else
	if [ -n "$(echo $older_type | grep -i $code_type)" ] ; then result_type="(ok)"
	else
		result_type="(-error-)"
		error_type="邮件中的产品名称<"$older_type">和编码类型<"$code_type">不一致，请仔细核对编码类型！！！"
	fi
fi
#核对邮件内容中的数量和编码中的数量是否一致
if [ $older_num -eq $code_num ] ; then result_num="(ok)"
else
	result_num="(-error!-)"
	error_num="邮件中的数量<"$older_num_old">和编码数量<"$code_num">不一致，请仔细核对编码数量！！！"
fi
#核对邮件内容中的兼容性和编码中的兼容性是否一致
if [ "$older_kind" = "$code_kind" ] ; then result_kind="(ok)"
else
	result_kind="(-error!-)"
	error_kind="邮件的兼容<"$older_kind">和编码兼容<"$code_kind">不一致，请仔细核对编码兼容情况！！！"
fi
#核对邮件内容中的长度和编码中的长度是否一致
result_length="(-?-)"
if [ $(expr $older_length \< 2) -eq 1 ] ; then
	expr ${code_length:=null} \<= 1 1>/dev/null && result_length="(ok)"
elif [ $(expr $older_length \>= 2) -eq 1 ] ; then
	expr $older_length \>= ${code_length:=null} 1>/dev/null && expr $older_length \< $(($code_length+2)) 1>/dev/null && result_length="(ok)"
fi
}

check_end() {
#清除解压出来的编码文件夹，并重命名
mv -f $input_zip old.zip &> /dev/null 
mv -f $input_txt old.txt &> /dev/null
deldir=$(find . -type d -cmin -2 | grep -v ^\.$) && rm -rf $deldir
}
printmark() {
echo "------------------------------------------------------------------------------"
}
read -p "请选择工作模式,***直接回车***退出程序： " mode ; echo ""
case $mode in
1)
echo "正在检查,可能需要5~30秒,请稍等......"
input_txt  ;  input_zip
#提取生产订单列表
echo -e "$(awk '{print $1}' $input_txt | sed -n '1p')编码核对信息汇总：\n" > $result
older_list=$(awk '{print $3}' $input_txt)
for older_id in $older_list
do
	#判断是否存在生产单号对应的编码文件夹
	if [ -d $older_id ] ; then
		echo "生产订单号"$older_id"核对结果：" >> $result
		older_info  ;  code_info
		if [ -n "$code_file" ] ; then
			check_info
			#输出检查结果信息
			echo "邮件日期:"$older_time" 产品名称:"$older_type" 数量:"$older_num_old" 备注:"$older_kind"" >> $result
			echo "编码日期:"$code_time""$result_time" 产品类型:"$code_type""$result_type" 长度:"$code_length"米"$result_length" 数量:"$code_num""$result_num" 速率:"$code_speed" 兼容:"$code_kind""$result_kind"" >> $result
			#判断是否出现编码错误，出错就输出错误信息和编码中的十六进制文件。
			if [ -n "$error_time""$error_type""$error_num""$error_kind" ] ; then
				#echo "$error_time""$error_type""$error_num""$error_kind" >> $result
				printmark >> $result
				echo "$code_file_hex_all" | head -n16 >> $result
			fi
		else
			echo "没有找到SN为 "$older_sn" 编码！！！" >> $result
			printmark >> $result
			echo "" >> $result
			continue
		fi
	else
		echo "没有找到"$older_id"对应的编码文件夹,请重新检查！！！" >> $result 
		echo $(unzip -l $input_zip | awk -F / '/WO/{print $1}' | awk '{print $4}' | sort -u) >> $result
	fi
	printmark >> $result
	echo "" >> $result
done
check_end
dos2unix -o $result 2> /dev/null
echo -e "\n---检查完成！检查结果保存在result文件中, 请及时查看(方法:cat result), 下次运行会自动覆盖!---\n"
;;

2)
echo "正在准备手动检查编码......"
input_txt ; input_zip
while [ true ] ; do
	echo ""  ;  read -p "请输入需要核对的生产订单号,***直接回车***退出手动检查：" scdh
	#判断手输的生产单号是否存在邮件内容中，思路：生产单号是唯一的，判断唯一
	echo ""  ;  [ -z $scdh ] && echo -e "正在退出手动检查编码......\n" && check_end && break 
	if [ $(cat $input_txt | awk '{print $3}' | grep -c $scdh 2>/dev/null) -eq 1 ] ; then
		#提取手输的生产订单号全称，示例：WO180500115
		older_id=$(cat $input_txt | awk '{print $3}' | grep $scdh) 
		#判断是否存在生产单号对应的编码文件夹
		if [ -d $older_id ] ; then older_info  ;  code_info
			if [ -n "$code_file" ] ; then 
			check_info
			#输出检查结果信息
			echo "生产订单号："$older_id""
			echo "邮件日期:"$older_time" 产品名称:"$older_type" 数量:"$older_num_old" 备注:"$older_kind""
			echo "编码日期:"$code_time""$result_time" 产品类型:"$code_type""$result_type" 长度:"$code_length"米"$result_length" 数量:"$code_num""$result_num" 速率:"$code_speed" 兼容:"$code_kind""$result_kind""
			#判断是否出现编码错误，出错就输出错误信息和编码中的十六进制文件。
			[ -n "$error_time""$error_type""$error_num""$error_kind" ] && echo "$error_time""$error_type""$error_num""$error_kind"
			printmark
			#输出编码中的十六进制文件，仅输出20行。
			echo "$code_file_hex_all" | head -n20 
			else echo -e "\n没有找到SN为"$older_sn"编码！！！"
			fi
		else
			echo "没有找到对应的编码文件夹,请重新检查！！！" 
			#显示编码压缩文件中的目录内容
			echo $(unzip -l $input_zip | awk -F / '/WO/{print $1}' | awk '{print $4","}' | sort -u)
		fi
	else echo -e "\n请重新输入完整、正确的生产单号！！！"  ;  continue
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
Edgecore-7712
H3C-S5120
HP-2910
HP-5900
Huawei-S5700
Huawei-CE6855
IBM-G8264
Juniper-QFX5100"
;;
"40g"|"56g"|"100g")
swtich="Arista-7050
Cisco-3064
Cisco-5548
Cisco-3232C
Cisco-92160
Dell-ForceS4810
Edgecore-5712
Edgecore-7712
HP-5900
Huawei-CE6855
IBM-G8264
Mellanox-SB7800
Juniper-QFX5200
Juniper-QFX5100"
;;
"200g")
swtich="Cisco-3232C
Cisco-92160
Edgecore-7712
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
Mellanox-SB7800
Juniper-QFX5200
Juniper-QFX5100"
;;
esac

for pr in $product
do
	pr=$(echo $pr | sed '{s/\//-/g ; s/ //g}')
	[ -n "$(echo $pr | grep "^-")" ] && echo -e "\n文件名不能以 - 开头，请检查输入的产品名称！！！" && continue 
	[ -d $pr ] && rm -rf $pr/* || mkdir -p $pr
	for sw in $swtich
	do
		sw=$(echo $sw | sed '{s/\//-/g ; s/ //g}')
		touch $pr/$pr-$sw.txt 
		#添加测试模板格式到文本文件中：指示灯、基本信息、DDM信息
		if [ -n "$(echo $sw | grep -i "edgecore")" ] ; then echo $sw | grep -qi "5712" && name="Cisco" || name="H3C"
		elif [ -n "$(echo $sw | grep -i "hp")" ] ; then echo $sw | grep -qi "2910" && name="HP" || name="H3C"
		else name=$(echo $sw | awk -F"-" '{print $1}')
		fi
		if [ -n "$(echo $pr | grep -iE "cab|aoc|-t")" ] ; then
			echo "$name code, Indictor light is UP/DOWN , Basic infomation is OK/ERROR , DDM is NONE ." >> $pr/$pr-$sw.txt 
		else
			echo "$name code, Indictor light is UP/DOWN , Basic infomation is OK/ERROR , DDM is OK/ERROR ." >> $pr/$pr-$sw.txt 
		fi
	done
done
#将创建好的文件夹打包，并删除原文件,方便拷出
dir=$(find . -type d -cmin -1 | grep -v "^\.$")  ;  dir_name="$(date +%Y%m%d-%H%M%S).tar"
tar --remove-files -cf $dir_name $dir && echo -e "\n----------测试模板文件"$dir_name"创建完成!----------\n"
;;

4)
#用来提取邮件中的SN号，并整理排板好
input_txt
echo "--------------产品类型---------------------------"
awk '{print $4}' $input_txt | awk -F"M" '{print $1"M"}'
echo "--------------起始SN-----------------------------"
awk '{print $6}' $input_txt | awk -F"-" '{print $1}'
echo "--------------截止SN-----------------------------"
snall=$(awk '{print $6}' $input_txt)
for sn in $snall
do 
	sn_start=$(echo $sn | awk -F"-" '{print $1}')
	if [ -n "$(echo $sn | grep "-")" ] ; then
		sn_end=$(echo $sn | awk -F"-" '{print $2}')
		num1=$((${#sn_start} - ${#sn_end}))
		echo "${sn_start:0:$num1}$sn_end"
	else echo "$sn"
	fi
done
echo -e "--------------整理完成-------------------------\n"
mv -f $input_txt old.txt 2> /dev/null
;;

5)
#将测试结果文件整理并汇总到一个文本中
input_zip
alldir=$(find . -type d -cmin -1 -print | grep -v "\.$")
echo -e "测试结果汇总：\n" > $result
for dir in $alldir
do
	alltxt=$(ls $dir | grep ".txt")
	[ -z "$alltxt" ] && echo -e "$dir\n" >> $result && continue
	echo -e "\n${dir##*/}: " >> $result
	for txt in $alltxt
	do
	txt_h=$(cat $dir/$txt | head -n3)
	if [[ -z $(echo $txt | grep error) && -z $(echo $txt_h | grep -aiE "down|error|false") && -n $(echo $txt_h | grep -aiE "on|ok") ]] ; then
		action $txt /bin/true >> $result
	else
		if [ -z "$(echo $txt_h)" -o -n "$(echo $txt_h | grep -ai "on\/down")" ] ; then
			echo $txt---------------------------------[ 未测试 ] >> $result
		else
			action $txt /bin/false >> $result
			echo "$txt_h" | head -n1 >> $result
		fi
	fi
	done
done
rm -rf $(find . -type d -cmin -2 | grep -v "\.$") 1> /dev/null
echo -e "\n整理完成！整理结果保存在result文件中, 请及时查看(方法:cat result), 下次运行会自动覆盖！\n"
;;

6)
if [ -f zqp_p02.bin ] ; then
  read -p "请输入SN的前面固定位：" sn_start
  read -p "请输入SN的后面变化位(必须为数字，不足前面可补0)：" sn_end
  if [ -n "$sn_start" -a -n "$sn_end" ] ; then
	for sn in `seq -w $sn_end` ; do cp zqp_p02.bin ${sn_start}$sn.bin ; done
	tar --remove-file -cf $sn_start.tar $sn_start*
  else echo -e "请输入正确的SN信息！！！"
  fi
else echo "zqp_p02.bin文件不存在，请放入全FF的bin文件，并命名为：zqp_p02.bin ！！！"
fi
;;

*)
echo -e "请输入正确的工作模式！！！\n"	
;;
esac
