#!/bin/bash
# 用于万兆通PAE兼容测试岗位 : 自动创建兼容测试模板、邮件编码的核对工作
# 需要文件：需求的邮件编码信息、编码完后的编码压缩zip文件
# 需要软件：apt install zip unzip dos2unix
# Author : XJ  Date: 20180519
# 20200113 应叶工(东莞自动写码软件测试版)要求：需要所有编码都要放码到根目录(只读取SN,不读取码内容); 修改生产订单码文件数量判断
# 20200323 因东莞生产更换新系统,致导出的产品名称格式由Q10/Q10、ZQP/ZQP...变成Q10-Q10、ZQP-ZQP...; 修改生产订单中的产品名称判断
# 20200402 因10G-SFP-MCU线缆底层128和145 byte已固定为10 01，所以新增检查10G-SFP-MCU码文件中的128和145 byte是否为10 01
#	新增 QSFP_MCU、QSFP_MCU/2SFP_EEPROM、ZQP_MCU/ZQP_MCU、ZQP_MCU/2ZSP_EEPROM 线缆需加密底层的写码模板,需LMM/Page00/Page02中都放password.txt文件,
#	修改文件数量判断,需在此备注后面添加"Encryption_bottom"来让脚本识别订单为特殊加密底层
# 20200408 新增检查码中的起始SN和末尾SN是否和码文件SN命名一致
# 20200512 修改兼容性检查,不再区分50pcs数量来使用不同的兼容码;统一更改所有都按兼容要求编码
#	新增CAB-1GSFP-PxM检查模板,和SFP-MCU放码模块类似,只是无Password.txt
# 20201125 新增检查VN、PN列(若vn、pn中有空格则会判断失误；若无vn、pn要求则为0)；现在code.txt结构：1-日期 2-销售单号 3-生产单号 4-产品名称 5-生产数量 6-起始SN 7-结束SN 8-VN 9-PN 10-备注
# 20210701 新增交换机测试模板中的冷热启动模板

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
echo "7-针对生产写码10GSFP QSFP/4SFP、ZQP/4ZSP二端SN不同，无法自动写码，仅修改QSFP端SN命名，和SFP端SN保持一致"
echo ""
result=./result
# 获取需求的邮件编码信息文件
input_txt() {
	input_txt=$(ls -t *.txt | head -n1)
	[ -z "$input_txt" ] && echo -e "\n编码邮件内容.txt 文件不存在，请重新检查！！！\n" && exit
	dos2unix -q $input_txt
}
# 获取编码完后的编码压缩zip文件
input_zip() {
	input_zip=$(ls -t *.zip | head -n1)
	# 判断是否存在未删除的解压出来的文件夹，删除了再解压刚传入的zip文件,-iname表示忽略大小写
	find ./ -type d -iname "[MW]O*" -exec rm -r {} \; 2> /dev/null
	[ -z "$input_zip" ] && echo -e "\n编码文件.zip 文件不存在，请重新检查！！！\n" && exit
	unzip -q "$input_zip" || exit
}

order_info() {
	# 提取邮件中某个生产订单一整行内容
	order_all=$(cat $input_txt | grep -a $order_id)
	# 提取内容中的日期,示例：20180515
	order_time=$(echo $order_all | awk '{print $1}')
	# 提取订单编码数量,示例：30
	order_num_old=$(echo $order_all | awk '{print $5}')
	# 提取邮件中的产品SN，示例：S180701230001
	order_sn_info=$(echo $order_all | awk '{print $6}')
	order_sn=$(echo ${order_sn_info%-*})
	[ $order_num_old -eq 1 ] && order_sn_end=$order_sn || {
		# 最后SN为起始SN加上数量，减1即可; 思路：将SN后4位分开，再将后4位加数量减1后，再和SN前面合并
		order_sn_end_num=${#order_num_old}
		order_sn_1=${order_sn: -4}
		order_sn_2=$(expr $order_sn_1 + $order_num_old - 1)
		order_sn_end=${order_sn: 0: -4}$(echo $order_sn_2 | awk '{printf("%04d",$0)}')
	}

	# 提取邮件中的产品名称，示例：CAB-10GSFP-P3M
	order_type=$(echo $order_all | awk '{print $4}')
	# 20201125 新增提取PN
	# 提取邮件中的产品定制VN，示例：Optech
	order_vn=$(echo $order_all | awk '{print $8}')
	[ "$order_vn" = "0" ] && order_vn=
	
	# 提取邮件中的产品定制PN，示例：EXQSFP4SFPDJ3.5M
	order_pn=$(echo $order_all | awk '{print $9}')
	[ "$order_pn" = "0" ] && order_pn=
	# 提取内容中的备注,示例：通用/OEM中性码，VN：Optech，PN：OPQSFP-T-05-PCB
	order_remark=$(echo $order_all | awk '{print $10$11$12$13$14$15$16$17$18$19$20}')
	[ -z "$order_remark" ] && order_remark="无备注"

	# 提取邮件中的需求长度，单位CM/M; 判断特殊情况：CAB-10GSFP-P65CM和HP-Aruba的编码长度位为00
	if [ -z "$(echo "$order_type" | grep -i cm)" ]; then
		if [ -n "$(echo $order_type | grep -i 10gsfp)" -a -n "$(echo $order_remark | grep -Ei "hpp|aruba")" ]; then
			order_length=0
		else
			order_length=$(echo ${order_type%M*} | sed 's/.*\(...\)$/\1/' | sed 's/[a-zA-Z]//g' | sed 's/-//g')
			order_length=$(echo $order_length | awk '{print int($0)}')
		fi
	else
		if [ -n "$(echo $order_type | grep -i 10gsfp)" -a -n "$(echo $order_remark | grep -Ei "h3c|hp")" ]; then
			order_length=0
		else
			order_length=1
		fi
	fi

	# 20191119新增10gsfp线缆的MCU方案
	order_kind=
	[ -n "$(echo $order_all | grep -i 10gsfp | grep -i mcu)" ] && order_kind=CiscoMCU
	[ -n "$(echo $order_all | grep -i 10gsfp | grep -Ei "h3c|hp|aruba")" ] && order_kind=HP-H3C-Aruba
	[ $order_kind ] || order_kind=null
	case $order_kind in
	"HP-H3C-Aruba"|"CiscoMCU")
		order_num=$(($order_num_old * 3 + 5))
		;;
	*)
		if [ -n "$(echo $order_type | grep -Ei "10gsfp|xfp-xfp")" ]; then order_num=$(($order_num_old * 3 + 1))
		elif [ -n "$(echo $order_type | grep -Ei "zsp-zsp|xfp-sfp")" ]; then order_num=$(($order_num_old * 3 + 1))
		elif [ -n "$(echo $order_type | grep -Ei "q10-q10|qsfp-qsfp|8644-qsfp|8644-8644|8644-8088|qsfp-8088|q14-q14")" ]; then
			if [ -n "$(echo $order_remark | grep -i mcu)" ]; then
				[ "$(echo $order_remark | grep -i Encryption_bottom)" ] && order_num=$(($order_num_old * 5 + 9)) || order_num=$(($order_num_old * 5 + 5))
			else
				order_num=$(($order_num_old * 3 + 1))
			fi
		elif [ -n "$(echo $order_type | grep -Ei "q10-4s|qsfp-4sfp|qsfp-4xfp")" ] ; then
			# 判断QSFP/4SFP、QSFP/1SFP、QSFP/4SFP，QSFP端可分EEPROM或MCU，SFP只能是EEPROM
			[ "$(echo $order_remark | grep -i mcu)" ] && order_num=$(($order_num_old * 7 + 3)) || order_num=$(($order_num_old * 6 + 1))
		elif [ -n "$(echo $order_type | grep -Ei "q10-1s|qsfp-1s")" ] ; then
			[ "$(echo $order_remark | grep -i mcu)" ] && order_num=$(($order_num_old * 4 + 3)) || order_num=$(($order_num_old * 3 + 1))
		elif [ -n "$(echo $order_type | grep -Ei "q10-2s|qsfp-2s")" ] ; then
			if [ -n "$(echo $order_remark | grep -i mcu)" ]; then
				[ -n "$(echo $order_remark | grep -i Encryption_bottom)" ] && order_num=$(($order_num_old * 5 + 5)) || order_num=$(($order_num_old * 5 + 3))
			else
				order_num=$(($order_num_old * 4 + 1))
			fi
		elif [ -n "$(echo $order_type | grep -i zqp-zqp)" ]; then 
			[ -n "$(echo $order_remark | grep -i Encryption_bottom)" ] && order_num=$(($order_num_old * 5 + 9)) || order_num=$(($order_num_old * 5 + 5))
		elif [ -n "$(echo $order_type | grep -i zqp-4zsp)" ]; then order_num=$(($order_num_old * 7 + 3))
		elif [ -n "$(echo $order_type | grep -i zqp-2zqp)" ]; then order_num=$(($order_num_old * 7 + 7))
		elif [ -n "$(echo $order_type | grep -i zqp-2zsp)" ]; then 
			[ -n "$(echo $order_remark | grep -i Encryption_bottom)" ] && order_num=$(($order_num_old * 5 + 5)) || order_num=$(($order_num_old * 5 + 3))
		else order_num=$order_num_old
		fi
		;;
	esac
	# --- 临时增加: CAB-1GSFP-PxM长度检查,默认使用的千兆光模块码,码中铜缆长度标识为 0 ---
	[ -n "$(echo "$order_type" | grep -i 1gsfp)" ] && { order_length=0 ; order_num=$(($order_num_old * 3 + 3)) ; }
	
	# 判断邮件中要求的编码类型，H3C表示H3C码, OEM表示OEM码,默认表示思科兼容
	if [ -n "$(echo $order_all | grep -i 10gsfp |grep -Ei "h3c|hp|aruba")" ]; then order_kind=HP-H3C-Aruba
	# 临时使用 --- 超过50pcs深圳不改码出货所以兼容一定要正确 --- 20200512不再区分数量，全部检测
	# 20191119新增10gsfp线缆的MCU方案
	elif [ -n "$(echo $order_all | grep -i 10gsfp |grep -i mcu)" ]; then order_kind=CiscoMCU
	elif [ -n "$(echo $order_remark | grep -i oem | grep -i optech)" ]; then order_kind=OEM
	elif [ -n "$(echo $order_remark | grep -i Arista)" ]; then
		[ -n "$(echo $order_type | grep -Ei "qsfp|q10|zsp")" ] && order_kind=Arista || order_kind=OEM
	elif [ -n "$(echo $order_remark | grep -i alcatel)" ]; then order_kind=Alcatel-lucent
	elif [ -n "$(echo $order_remark | grep -i Brocade)" ]; then order_kind=Brocade
	elif [ -n "$(echo $order_remark | grep -i Cisco)" ]; then order_kind=Cisco
	elif [ -n "$(echo $order_remark | grep -i Dell)" ]; then order_kind=Dell
	elif [ -n "$(echo $order_remark | grep -i Extreme)" ]; then order_kind=Extreme
	elif [ -n "$(echo $order_remark | grep -i Huawei)" ]; then order_kind=Huawei
	elif [ -n "$(echo $order_remark | grep -i Juniper)" ]; then order_kind=Juniper
	elif [ -n "$(echo $order_remark | grep -i Mellanox)" ]; then order_kind=Mellanox
	# Mikrotik 码已停用,品牌不认码,使用Cisco码代替
	elif [ -n "$(echo $order_remark | grep -i Mikrotik)" ]; then order_kind=Cisco
	# Ubiquiti 品牌不认码,使用Cisco码代替
	elif [ -n "$(echo $order_remark | grep -i Ubiquiti)" ]; then order_kind=Cisco
	elif [ -n "$(echo $order_remark | grep -i Intel)" ]; then order_kind=Intel
	elif [ -n "$(echo $order_remark | grep -i Lenovo)" ]; then order_kind=Lenovo
	# 非以上备注默认思科码代替
	else order_kind=Cisco
	fi
}

code_info() {
	# 统计编码文件夹下的编码数量，在后面判断是否和邮件中的数量是否一致？
	code_num=$(find ./ -type d -name $order_id -exec ls -lR {} \; | grep -c "^-")
	# 在编码文件夹中搜索SN号为001.bin或0001.bin的编码文件
	code_file=$(find ./ -type f -name ${order_sn}.bin | grep -i port | sort | head -n1)
	
	if [ -n "$code_file" ] ; then
		# hexdump参数： -s偏移量 -n指定字节
		code_file_hex_all=$(hexdump -vC $code_file)
		[ -n "$(echo $order_type | grep -Ei "qsfp|q10|8644|q14")" -a -z "$(echo $order_remark | grep -i mcu)" ] && \
			code_file_hex=$(hexdump -vC $code_file -s 128 -n 256) || code_file_hex=$(hexdump -vC $code_file -n 256)

		# 提取编码中的第0位，03表示SFP类型，06表示XFP类型, 0D表示40G-QSFP, 11表示100G-ZQP，0F表示8644
		code_type=$(echo "$code_file_hex" | awk 'NR==1{print $2}')
		case $code_type in
			"03") code_type=SFP ;;
			"06") code_type=XFP ;;
			"0d") code_type=Q10 ;;
			"11") code_type=ZQP ;;
			"18") code_type=QSFP-DD ;;
			"0f") code_type=8644 ;;
			*)	code_type="请检查第0位未识别的产品类型代码：$code_type" ;;
		esac
		# 提取编码中的第1行第13位，0C表示千兆，63/67表示10G, FF表示25G, 3C表示6G
		code_speed=$(echo "$code_file_hex" | awk 'NR==1{print $14}')
		case $code_speed in
			"63"|"64"|"67") code_speed=10G ;;
			"ff")	code_speed=25G ;;
			"01"|"02")	code_speed=100M ;;
			"0c"|"0d"|"15")	code_speed=1G ;;
			"19")	code_speed=2.5G ;;
			"3c")	code_speed=6G ;;
			"55")	code_speed=8G ;;
			"78")	code_speed=12G ;;
			"8c"|"8d")	code_speed=14G ;;
			*)	code_speed="请检查第13位未识别的产品速率代码：$code_speed" ;;
		esac
		if [ "$code_type" = SFP -a "$code_speed" = 1G ]; then code_type=1GSFP
		elif [ "$code_type" = SFP -a "$code_speed" = 10G ]; then code_type=10GSFP
		elif [ "$code_type" = SFP -a "$code_speed" = 25G ]; then code_type=ZSP
		elif [ "$code_type" = Q10 -a "$code_speed" = 10G ]; then code_type=Q10 ; code_speed=40G
		elif [ "$code_type" = Q10 -a "$code_speed" = 14G ]; then code_type=Q14 ; code_speed=56G
		elif [ "$code_type" = ZQP -a "$code_speed" = 25G ]; then code_type=ZQP ; code_speed=100G
		fi
		# 提取编码中的第7行第96位-98位，"48 33 43"表示H3C码, "00 00 00"表示OEM码,因思科码96位不同，所以只判断第97 98位，"00 11"表示思科码
		code_kind=$(echo "$code_file_hex" | awk 'NR==7{print $3,$4}')
		case $code_kind in
			"00 00") 		 
				if [ -n "$(echo "$code_file_hex" | grep -i Arista)" ]; then code_kind=Arista
				elif [ -n "$(echo "$code_file_hex" | grep -i Brocade)" ]; then code_kind=Brocade
				elif [ -n "$(echo "$code_file_hex" | grep -i Cisco)" ]; then code_kind=Cisco
				elif [ -n "$(echo "$code_file_hex" | grep -i Dell)" ]; then code_kind=Dell
				elif [ -n "$(echo "$code_file_hex" | grep -i Huawei)" ]; then code_kind=Huawei
				elif [ -n "$(echo "$code_file_hex" | grep -Ei "HP|H3C|Aruba")" ]; then code_kind=HP-H3C-Aruba
				elif [ -n "$(echo "$code_file_hex" | grep -i Extr)" ]; then code_kind=Extreme
				# Lenovo 10G-DAC码厂商名为 Blade ; 40G-DAC码厂商名为 IBM
				elif [ -n "$(echo "$code_file_hex" | grep -Ei "IBM|Blade")" ]; then code_kind=Lenovo
				# Juniper码没有明显Juniper标识特征, 只有加密位中包含 REV 版本字符
				elif [ -n "$(echo "$code_file_hex" | grep -i REV)" ]; then code_kind=Juniper
				elif [ -n "$(echo "$code_file_hex" | grep -i Intel)" ]; then code_kind=Intel
				elif [ -n "$(echo "$code_file_hex" | grep -i Mellanox)" ]; then code_kind=Mellanox
				# Mikrotik码已全部停用,使用Cisco码代替
				elif [ -n "$(echo "$code_file_hex" | grep -i Mikrotik)" ]; then code_kind=Mikrotik
				elif [ -n "$(echo "$code_file_hex" | grep -i Ruijie)" ]; then code_kind=Ruijie
				else code_kind=OEM 
				fi
			;;
			"33 43"|"50 a0"|"50 a2")	code_kind=HP-H3C-Aruba ;;
			"00 11"|"43 11")	code_kind=Cisco ;;
			"34 30"|"34 11")	code_kind=Juniper ;;
			"61 20")	code_kind=Arista ;;
			"32 30")	code_kind=Alcatel-lucent ;;
			"58 54")	code_kind=Extreme ;;
			"47 53")	code_kind=Brocade ;;
			"10 00"|"10 01")	code_kind=Dell ;;
			"41 31")	code_kind=Avaya ;;
			"39 32")	code_kind=Mellanox ;;
			*)	code_kind="请检查LMM加密位的编码兼容类型: $code_kind" ;;
		esac
		# 提取编码中的第2行第4位，表示线缆的长度
		code_length=$(echo "$code_file_hex" | awk 'NR==2{print $4}')
		code_length=$(echo $((0x$code_length)))
		# 提取编码中的第6行日期
		code_time_line=$(echo "$code_file_hex" | awk -F "|" 'NR==6{print $2}')
		code_time=${code_time_line:4:6}
		[ "$(echo $order_all | grep -i 10gsfp | grep -i mcu)" ] && {
			code_128btye=$(echo "$code_file_hex" | awk 'NR==9{print $2}')
			code_145btye=$(echo "$code_file_hex" | awk 'NR==10{print $3}')
			}
		# 提取编码中的VN信息
		code_vn_line_start=$(echo "$code_file_hex" | awk -F "|" 'NR==2{print $2}')
		code_vn_line_end=$(echo "$code_file_hex" | awk -F "|" 'NR==3{print $2}')
		code_vn_start=${code_vn_line_start:4:12}
		code_vn_end=${code_vn_line_end::4}
		code_vn=$(echo $code_vn_start$code_vn_end)
		
		# 提取编码中的PN信息
		code_pn_line_start=$(echo "$code_file_hex" | awk -F "|" 'NR==3{print $2}')
		code_pn_line_end=$(echo "$code_file_hex" | awk -F "|" 'NR==4{print $2}')
		code_pn_start=${code_pn_line_start:8:8}
		code_pn_end=${code_pn_line_end::8}
		code_pn=$(echo $code_pn_start$code_pn_end)
	fi
}

check_info() {
	# 判断之前先初始化错误信息
	error_time= ; error_type= ; error_num= ; error_kind= 
	error_length= ; error_sn= ; error_vn= ; error_pn=
	result_time= ; result_type= ; result_num= ; result_kind= 
	result_length= ; result_sn=  ; result_vn=  ; result_pn=
	# 核对邮件内容中的日期和编码中的日期是否一致
	[ "${order_time:2}" = "$code_time" ] && result_time="(ok)" || {
		result_time="(-error!-)"
		error_time="邮件中的日期<${order_time}>和编码日期<${code_time}>不一致，请仔细核对编码日期！！！"
	}
	# 核对邮件内容中的产品类型和编码中的是否一致
	if [ -n "$(echo $order_type | grep -Ei "qsfp-4sfp|qsfp-4xfp|qsfp-8644|qsfp-8088|8644-8088")" ]; then
		if [ "$code_type" = Q10 -o "$code_type" = 8644 ]; then 
			result_type="(ok)"
		else
			result_type="(-error-)"
			error_type="邮件中的产品名称<${order_type}>和编码类型<${code_type}>不一致，请仔细核对编码类型！！！"
		fi
	else
		[ -n "$(echo $order_type | grep -i $code_type)" ] && result_type="(ok)" || {
			result_type="(-error-)"
			error_type="邮件中的产品名称<${order_type}>和编码类型<${code_type}>不一致，请仔细核对编码类型！！！"
			}
	fi
	# 核对邮件内容中的数量和编码中的数量是否一致
	[ $order_num -eq $code_num ] && result_num="(ok)" || {
		result_num="(-error!-)"
		error_num="邮件中的数量<${order_num_old}>和编码数量<${code_num}>不一致，请仔细核对编码数量！！！"
		}
	# 核对邮件内容中的兼容性和编码中的兼容性是否一致
	if [ "$order_kind" = "$code_kind" ] ; then 
		if [ -n "$(echo $order_all | grep -i 10gsfp | grep -i mcu)" ] ; then
			[ "${code_128btye}${code_145btye}" = "1001" ] && result_kind="(ok)" || {
				result_kind="(-error!-)"
				error_kind="10G-SFP-MCU方案中的第128<${code_128btye}>和145<${code_145btye}>字节不是10 01，请重新核对编码！！！"
				}
		else result_kind="(ok)"
		fi
	# 20191119新增10gsfp线缆的MCU方案
	elif [ "$order_kind" = CiscoMCU -a "$code_kind" = Cisco ]; then 
		[ "${code_128btye}${code_145btye}" = "1001" ] && result_kind="(ok)" || {
				result_kind="(-error!-)"
				error_kind="10G-SFP-MCU方案中的第128<${code_128btye}>和145<${code_145btye}>字节不是10 01，请重新核对编码！！！"
				}
	else
		result_kind="(-error!-)"
		error_kind="邮件的兼容<${order_kind}>和编码兼容<${code_kind}>不一致，请仔细核对编码兼容情况！！！"
	fi
	# 核对邮件内容中的长度和编码中的长度是否一致
	if [ $order_length = $code_length ] ; then
		result_length="(ok)"
	elif [ $(($order_length - $code_length)) -le 1 ] ; then
		result_length="(ok)"
	else
		result_length="(-error?-)"
		error_length="邮件的长度<${order_length}>和编码长度<${code_length}>不一致，请仔细核对编码兼容情况！！！"
	fi
	# 20200408 检查编码文件中的SN是否与邮件中的SN一致
	code_file_start=$(find ./ -type f -name ${order_sn}.bin | grep -i port | sort | head -n1)
	code_file_end=$(find ./ -type f -name ${order_sn_end}.bin | grep -i port | sort | head -n1)
	if [ -n "$(echo $order_type | grep -Ei "qsfp|q10|8644|q14")" -a -z "$(echo $order_remark | grep -i mcu)" ] ; then
		code_file_start_hex=$(hexdump -vC $code_file_start -s 128 -n 256)
		code_file_end_hex=$(hexdump -vC $code_file_end -s 128 -n 256)
	else
		code_file_start_hex=$(hexdump -vC $code_file_start -n 256)
		code_file_end_hex=$(hexdump -vC $code_file_end -n 256)
	fi
	code_start_sn_line1=$(echo "$code_file_start_hex" | awk -F "|" 'NR==5{print $2}')
	code_start_sn_line2=$(echo "$code_file_start_hex" | awk -F "|" 'NR==6{print $2}')
	code_end_sn_line1=$(echo "$code_file_end_hex" | awk -F "|" 'NR==5{print $2}')
	code_end_sn_line2=$(echo "$code_file_end_hex" | awk -F "|" 'NR==6{print $2}')
	code_start_sn=${code_start_sn_line1:4}${code_start_sn_line2::4}
	code_start_sn=$(echo $code_start_sn)
	code_end_sn=${code_end_sn_line1:4}${code_end_sn_line2::4}
	code_end_sn=$(echo $code_end_sn)
	if [ "$order_sn" = "$code_start_sn" -a "$order_sn_end" = "$code_end_sn" ]; then
		result_sn="(ok)"
	else
		result_sn="(-error!-)"
		error_sn="文件SN<$order_sn $order_sn_end>和编码SN<$code_start_sn $code_end_sn>不一致，请仔细编码中的SN是否正确！！！"
	fi
	# 20201125 检查编码文件中的VN是否与邮件中的定制VN一致
	if [ -n "$order_vn" ]; then
		[ "$order_vn" = "$code_vn" ] && result_vn="(ok)" || {
			result_vn="(-error!-)"
			error_vn="文件PN<$order_vn>和编码PN<$code_vn>不一致，请仔细编码中的VN是否正确！！！"
		}
	else
		result_vn="(ok)"
	fi
	# 20201125 检查编码文件中的PN是否与邮件中的定制PN一致
	if [ -n "$order_pn" ]; then
		[ "$order_pn" = "$code_pn" ] && result_pn="(ok)" || {
			result_pn="(-error!-)"
			error_pn="文件PN<$order_pn>和编码PN<$code_pn>不一致，请仔细编码中的PN是否正确！！！"
		}
	else
		result_pn="(ok)"
	fi
}

check_end() {
	# 清除解压出来的编码文件夹
	[ -f $input_zip ] && mv -f $input_zip old.zip 2> /dev/null
	[ -f $input_txt ] && mv -f $input_txt old.txt 2> /dev/null
	deldir=$(find ./ -type d -cmin -3 | grep -v ^./$) && rm -rf $deldir
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
order_list=$(awk '{print $3}' $input_txt)
for order_id in $order_list
do
	# 判断是否存在生产单号对应的编码文件夹
	if [ -d $order_id ] ; then
		echo "生产订单号${order_id}核对结果：" >> $result
		order_info
		code_info
		if [ -n "$code_file" ] ; then
			check_info
			# 输出检查结果信息
			echo "邮件日期:${order_time} 产品名称:${order_type} 数量:${order_num_old} 备注:${order_remark}" >> $result
			echo -e "编码日期:${code_time}${result_time} 产品类型:${code_type}${result_type} 长度:${code_length}米${result_length} 数量:${code_num}${result_num} \n    速率:${code_speed} SN:${result_sn}${error_sn} VN:${result_vn}${error_vn} PN:${result_pn}${error_pn} \n    兼容:${code_kind}${result_kind}${error_kind}" >> $result
			# 判断是否出现编码错误，出错就输出错误信息和编码中的十六进制文件。
			[ -n "${error_time}${error_type}${error_num}${error_kind}${error_length}${error_sn}${error_vn}${error_pn}" ] && {
				printmark >> $result
				echo "$code_file_hex_all" | head -n16 >> $result
				}
		else
			echo "没有找到SN为 $order_sn 编码！！！" >> $result
			continue
		fi
	else
		echo "没有找到${order_id}对应的编码文件夹,请重新检查！！！" >> $result
		echo $(unzip -l $input_zip | awk -F / '/[MW]O/{print $1}' | awk '{print $4}' | sort -u) >> $result
	fi
	printmark >> $result
	echo >> $result
done
check_end
echo -e "\n--- 检查完成！结果保存在 result 文件中,下次运行会自动覆盖,请及时查看(方法 : cat result )! ---\n"
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
	[ -z $scdh ] && { echo -e "正在退出手动检查编码......\n" ; check_end ; break ; }
	if [ $(cat $input_txt | awk '{print $3}' | grep -c $scdh 2>/dev/null) -eq 1 ]; then
		# 提取手输的生产订单号全称，示例：WO180500115
		order_id=$(cat $input_txt | awk '{print $3}' | grep $scdh)
		# 判断是否存在生产单号对应的编码文件夹
		if [ -d $order_id ]; then
			order_info
			code_info
			if [ -n "$code_file" ]; then
			check_info
			# 输出检查结果信息
			echo "生产订单号：${order_id}"
			echo "邮件日期:${order_time} 产品名称:${order_type} 数量:${order_num_old} 备注:${order_remark}"
			echo -e "编码日期:${code_time}\033[43;30m${result_time}\033[0m 产品类型:${code_type}\033[43;30m${result_type}\033[0m 长度:${code_length}米\033[43;30m${result_length}\033[0m 数量:${code_num}\033[43;30m${result_num}\033[0m \n    速率:${code_speed} SN:\033[43;30m${result_sn}\033[0m${error_sn} VN:\033[43;30m${result_vn}\033[0m${error_vn} PN:\033[43;30m${result_pn}\033[0m${error_pn} \n    兼容:${code_kind}\033[43;30m${result_kind}${error_kind}\033[0m"
			# 判断是否出现编码错误，出错就输出错误信息和编码中的十六进制文件。
			[ -n "${error_time}${error_type}${error_num}${error_kind}${error_length}${error_sn}${error_vn}${error_pn}" ] && echo "${error_time}${error_type}${error_num}${error_kind}${error_length}${error_sn}${error_vn}${error_pn}"
			printmark
			# 输出编码中的十六进制文件，仅输出20行。
			echo "$code_file_hex_all" | head -n16
			else echo -e "\n没有找到SN为${order_sn}编码！！！"
			fi
		else
			echo "没有找到对应的编码文件夹,请重新检查！！！"
			# 显示编码压缩文件中的目录内容
			echo $(unzip -l $input_zip | awk -F / '/[MW]O/{print $1}' | awk '{print $4","}' | sort -u)
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
	switch="Cisco-C2960
	Cisco-C2960G
	H3C-S3100V2
	Huawei-S5700"
	cold_startup_switch="Cisco-C2960G
	H3C-S3100V2
	Huawei-S5700"
	hot_startup_switch=$cold_startup_switch
	;;
	"1g")
	switch="Arista-7050S
	Brocade-VDX6740
	Cisco-C2960
	Cisco-C2960G
	Cisco-C3560
	Cisco-C3064PQ
	Cisco-C5548UP
	Cisco-C3232C
	Cisco-C92160YC
	Dell-ForceS4810
	Edgecore-5712
	H3C-S3100V2
	H3C-S5120
	HP-2910AL
	HP-5900AF
	Huawei-S5700
	Huawei-CE6855
	IBM-G8264
	Mellanox-SN2410
	Mikrotik-CRS309_1G_8S+PC
	Juniper-QFX5100"
	cold_startup_switch="Arista-7050S
	Cisco-C2960G
	Dell-ForceS4810
	Edgecore-5712
	H3C-S5120
	HP-2910AL
	Huawei-S5700
	IBM-G8264
	Mellanox-SN2410
	Juniper-QFX5100"
	hot_startup_switch=$cold_startup_switch
	;;
	"10g")
	switch="Arista-7050S
	Brocade-VDX6740
	Cisco-C3064PQ
	Cisco-C5548UP
	Cisco-C3232C
	Cisco-C92160YC
	Dell-ForceS4810
	Edgecore-5712
	H3C-S5120
	HP-2910AL
	HP-5900AF
	Huawei-S5700
	Huawei-CE6855
	IBM-G8264
	Mellanox-SN2410
	Mikrotik-CRS309_1G_8S+PC
	Juniper-QFX5100"
	cold_startup_switch="Arista-7050S
	Cisco-C3064PQ
	Dell-ForceS4810
	Edgecore-5712
	H3C-S5120
	HP-2910AL
	Huawei-CE6855
	IBM-G8264
	Mellanox-SN2410
	Juniper-QFX5100"
	hot_startup_switch=$cold_startup_switch
	;;
	"25g")
	switch="Cisco-C92160YC
	Mellanox-SN2410"
	cold_startup_switch=$switch
	hot_startup_switch=$switch
	;;
	"40g"|"56g")
	switch="Arista-7050S
	Brocade-VDX6740
	Cisco-C3064PQ
	Cisco-C5548UP
	Cisco-C3232C
	Cisco-C92160YC
	Dell-ForceS4810
	Edgecore-5712
	HP-5900AF
	Huawei-CE6855
	IBM-G8264
	Mellanox-SN2410
	Mellanox-SB7800
	Juniper-QFX5200
	Juniper-QFX5100"
	cold_startup_switch="Arista-7050S
	Cisco-C3064PQ
	Dell-ForceS4810
	Edgecore-5712
	HP-5900AF
	Huawei-CE6855
	IBM-G8264
	Mellanox-SN2410
	Juniper-QFX5100"
	hot_startup_switch=$cold_startup_switch
	;;
	"100g")
	switch="Cisco-C3232C
	Cisco-C92160YC
	Mellanox-SN2410
	Mellanox-SB7800
	Juniper-QFX5200"
	cold_startup_switch="Cisco-C92160YC
	Mellanox-SN2410"
	hot_startup_switch=$cold_startup_switch
	;;
	*)
	echo -e "\n请输入正确的速率类型！！！\n" && exit
	# 所有交换机汇总列表
	switch="Arista-7050S
	Brocade-VDX6740
	Cisco-C2960
	Cisco-C2960G
	Cisco-C3560
	Cisco-C3064PQ
	Cisco-C5548UP
	Cisco-C3232C
	Dell-ForceS4810
	Edgecore-5712
	Edgecore-7712
	H3C-S3100V2
	H3C-S5120
	HP-2910AL
	HP-5900AF
	Huawei-S3700
	Huawei-S5700
	IBM-G8264
	Mellanox-SN2410
	Mellanox-SB7800
	Mikrotik-CRS309_1G_8S+PC
	Juniper-QFX5200
	Juniper-QFX5100"
	;;
esac

for pr in $product
do
	pr=$(echo $pr | sed '{s/\//-/g ; s/ //g}')
	[ -n "$(echo $pr | grep "^-")" ] && echo -e "\n文件名不能以 - 开头，请检查输入的产品名称！！！" && continue
	cold_dir=${pr}_cold_startup
	hot_dir=${pr}_hot_startup
	[ -d $pr ] && rm -rf ${pr}/* $cold_dir $hot_dir || mkdir -p $pr $cold_dir $hot_dir
	for sw in $switch
	do
		sw=$(echo $sw | sed '{s/\//-/g ; s/ //g}')
		sw_file="${pr}/${pr}_${sw}.txt"
		# 添加测试模板格式到文本文件中：指示灯、基本信息、DDM信息
		if [ -n "$(echo $sw | grep -i "edgecore")" ]; then name="Cisco"
		elif [ -n "$(echo $sw | grep -i "hp")" ]; then
			echo $sw | grep -qi "2910" && name="HPP" || name="H3C"
		else name=$(echo $sw | awk -F"-" '{print $1}')
		fi
		[ -n "$(echo $pr | grep -Ei "cab|aoc|-t")" ] && \
			echo -e "$name code , Indictor_light is UP/DOWN , Basic_infomation is OK/ERROR , DDM is NONE .\n\n" > $sw_file || \
			echo -e "$name code , Indictor_light is UP/DOWN , Basic_infomation is OK/ERROR , DDM is OK/ERROR .\n\n" > $sw_file
		unix2dos -q $sw_file
		[ "$(echo $cold_startup_switch | grep $sw)" ] && cp -f $sw_file $cold_dir
		[ "$(echo $hot_startup_switch | grep $sw)" ] && cp -f $sw_file $hot_dir
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
	if [ -d "${order_id}/Port1/Page02" ]; then
		page02_sn=$(find ${order_id}/Port1/Page02/ -type f -iname "${order_sn}*")
		cp_num=$order_num
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
			[ "$cp_num" -eq 1 ] && echo "${order_id}/Port1/Page02/ 下SN数量为1个！！！" || \
			echo "${order_id}/Port1/Page02/ 下SN文件不存在！！！"
		fi
	fi
}
# cp选项: -r递归 -n不覆盖同名文件 -f覆盖同名文件
sfp_zsp_eeprom_mcu() {
	if [ -d $1/Port2 ]; then
		[ -d $1/Port5 ] && cp -rn $1/Port2/* $1/Port5/
		#[ ! -d $1/Port2/A2 ] && cp -n $1/Port2/A0/* $1/
		cp -n $1/Port2/A0/* $1/
	else
		echo "$1/Port2 文件夹不存在，调用 sfp_eeprom_mcu 模板错误！！！" && continue
	fi
}
qsfp_zqp_2zqp_eeprom_mcu() {
	if [ -d $1/Port1 ]; then
		[ -d $1/Port2 ] && cp -rn $1/Port1/* $1/Port2/
		[ -d $1/Port6 ] && cp -rn $1/Port1/* $1/Port6/
		[ -d $1/Port1/A0 ] && cp -n $1/Port1/A0/* $1/
		[ -d $1/Port1/Page00 ] && cp -n $1/Port1/Page00/* $1/
	else
		echo "$1/Port1 文件夹不存在，调用 qsfp_zqp_2zqp_eeprom_mcu 模板错误！！！" && continue
	fi
}
qsfp_4sfp_zqp_4zsp() {
	if [ -d $1/Port2 ]; then
		[ -d $1/Port3 ] && cp -rn $1/Port2/* $1/Port3/
		[ -d $1/Port4 ] && cp -rn $1/Port2/* $1/Port4/
		[ -d $1/Port5 ] && cp -rn $1/Port2/* $1/Port5/
		cp -n $1/Port2/A0/* $1/
	else
		echo "$1/Port2 文件夹不存在，调用 qsfp_4sfp_zqp_4zsp 模板错误！！！" && continue
	fi
}

order_list=$(awk '{print $3}' $input_txt)
for order_id in $order_list
do
	# 提取邮件中某个生产订单一整行内容
	order_all=$(cat $input_txt | grep -a $order_id)
	# 提取邮件中的产品名称，示例：CAB-10GSFP-P3M
	order_type=$(echo $order_all | awk '{print $4}')
	# 提取邮件中的产品SN，示例：S180701230001
	order_sn=$(echo $order_all | awk '{print $6}' | awk -F"-" '{print $1}')
	# 提取订单编码数量,示例：30
	order_num=$(echo $order_all | awk '{print $5}')
	if [ -n "$(echo $order_type | grep -i 10gsfp)" ]; then
		sfp_zsp_eeprom_mcu $order_id
	elif [ -n "$(echo $order_type | grep -i "zsp-zsp")" ]; then
		sfp_zsp_eeprom_mcu $order_id
	elif [ -n "$(echo $order_type | grep -Ei "q10-4s|qsfp-4sfp|zqp-4zsp|qsfp-4xfp|q10-2s|q10-1s|zqp-2zsp")" ]; then
		copy_page02
		qsfp_4sfp_zqp_4zsp $order_id
	elif [ -n "$(echo $order_type | grep -Ei "q10-q10|qsfp-qsfp|zqp-zqp|zqp-2zqp|q14-q14|8644-8644|8644-8088|qsfp-8088")" ]; then
		copy_page02
		qsfp_zqp_2zqp_eeprom_mcu $order_id
	else
		echo "没有匹配到 $order_id 订单的产品类型！！！"
	fi
done
dir_name="$(date +%Y%m%d-%H%M%S).zip"
zip -qrm $dir_name $order_list && echo -e "\n----------放码完成! $dir_name ----------\n"
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
echo "针对生产线缆10GSFP-DAC写码二端SN不一样，解决方法：正常编码完，仅将Port5中的SN重命名和Port2中的SN命名一样"
echo "针对生产线缆QSFP/4SFP、ZQP/4ZSP写码，仅Q和S端SN不一样，所有S端都是同一SN的情况"
echo "解决方法：按照正常编码，编码完将Q端的码文件重命名为S端名字，Q端和S端SN从小到大一一对应"
input_txt
input_zip
while [ true ]
do
	echo ""
	read -p "请输入需要重命名的生产订单号,***直接回车***退出重命名：" scdh
	echo ""
	[ -z "$scdh" ] && echo -e "正在退出重命名编码......\n" && break
	if [ $(cat $input_txt | awk '{print $3}' | grep -c $scdh 2>/dev/null) -eq 1 ]; then
		# 提取手输的生产订单号全称，示例：WO180500115
		order_id=$(cat $input_txt | awk '{print $3}' | grep $scdh)
		# 判断是否存在生产单号对应的编码文件夹
		if [ -d $order_id ]; then
			order_info
			if [ -n "$(echo $order_type | grep -Ei "10gsfp|xfp-xfp|zsp-zsp")" ]; then 
				# 10G-SFP ZSP的放码模板结构为：Port2/A0 Port5/A0
				port2=${order_id}/Port2/A0/
				port5=${order_id}/Port5/A0/
				port2_allsn=$(ls $port2 | sort)
				port5_allsn=$(ls $port5 | sort)
				port2_num=$(echo "$port2_allsn" | wc -l)
				port5_num=$(echo "$port5_allsn" | wc -l)
				[ $port2_num -ne $port5_num ] && echo "Port2与Port5中的SN数量不一样，请重新检查！！！" && continue
				for num in $(seq $port2_num)
				do
					port2_sn=$(echo "$port2_allsn" | awk 'NR=="'$num'"{print $0}')
					port5_sn=$(echo "$port5_allsn" | awk 'NR=="'$num'"{print $0}')
					mv -f ${port5}${port5_sn} ${port5}${port2_sn} 
				done
			elif [ -n "$(echo $order_type | grep -Ei "q10-4s|qsfp-4sfp|qsfp-4xfp|zqp-4zsp")" ] ; then
				# 分支线缆的放码模板结构为：Port1/[A0|Page00|Page02] Port2/A0 ... Port5/A0
				port1=${order_id}/Port1/A0/
				[ ! -d $port1 ] && port1=${order_id}/Port1/Page00/
				port1_p02=${order_id}/Port1/Page02/
				port2=${order_id}/Port2/A0/
				port1_allsn=$(ls $port1 | sort)
				port2_allsn=$(ls $port2 | sort)
				port1_num=$(echo "$port1_allsn" | wc -l)
				port2_num=$(echo "$port2_allsn" | wc -l)
				[ $port1_num -ne $port2_num ] && echo "QSFP-Port1与SFP-Port2中的SN数量不一样，请重新检查！！！" && continue
				for num in $(seq $port1_num)
				do
					port1_sn=$(echo "$port1_allsn" | awk 'NR=="'$num'"{print $0}')
					port2_sn=$(echo "$port2_allsn" | awk 'NR=="'$num'"{print $0}')
					mv -f ${port1}${port1_sn} ${port1}${port2_sn} 
					[ -d $port1_p02 ] && mv -f ${port1_p02}${port1_sn} ${port1_p02}${port2_sn} 
				done
			fi
			echo "$order_id 已经重命名完成 ！"
			continue
		else
			echo "没有找到对应的编码文件夹,请重新检查！！！"
			# 显示编码压缩文件中的目录内容
			echo $(unzip -l $input_zip | awk -F / '/[MW]O/{print $1}' | awk '{print $4","}' | sort -u)
			continue
		fi
	else 
		echo -e "\n请重新输入完整、正确的生产单号！！！"
		continue
	fi
done
order_all=$(find ./ -type d -name "[MW]O*")
dir_name="$(date +%Y%m%d-%H%M%S).zip"
zip -qrm $dir_name $order_all && echo -e "\n----------重命名文件 ${dir_name} 创建完成!----------\n"
rm -f old.zip $input_zip
check_end
;;

*)
	echo -e "请输入正确的工作模式！！！\n"
;;
esac
