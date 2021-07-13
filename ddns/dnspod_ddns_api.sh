#!/bin/bash
# # create date: 20210707 by xj; for DNSPod ddns api
# 1、依赖 curl(必需) jq(可选)；[yum | apt] install curl jq 
# 2、在 dnspod.cn 帐号中心创建申请：API密钥 --- DNSPod Token
# 若子域名不存在，则会自动创建

# ======域名信息=====
domain="xxy1.ltd"
sub_domain="n2n"
login_token="xx,79a4628589385f5daaee91be6903axxx"
ddns_log=/tmp/dnspod_ddns.log

blue_echo() {
	echo -e "\033[36m$1\033[0m" | tee -a $ddns_log
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m" | tee -a $ddns_log
}
red_echo() {
	echo -e "\033[31m$1\033[0m" | tee -a $ddns_log
}
# check curl command
[ -n "$(curl --version)" ] || { red_echo "$(date +"%F %T") curl : command not found! Please install it. Exit"; exit 2; }

# get public ip address
PublicIP=$(curl -4 -q ip.sb)
[ "$PublicIP" ] || PublicIP=$(curl -4 -q ip.3322.net)
[ "$PublicIP" ] || { red_echo "$(date +"%F %T") get PublicIP is Null, Exit"; exit 3; }

# check jq command
if [ -n "$(jq --version)" ]; then
# ================== 已安装 jq 软件 ==================
	# 获取子域名RecordID、RecordValue
	RecordList=$(curl -X POST https://dnsapi.cn/Record.List -d "login_token=${login_token}&domain=${domain}&sub_domain=${sub_domain}&format=json&lang=en")
	RecordListStatus=$(echo "$RecordList" | jq ".status.code" | sed 's/"//g')
	if [ "$RecordListStatus" = 1 ];then
		blue_echo "$(date +"%F %T") get RecordList Success "
	elif [ "$RecordListStatus" = 10 ];then
		yellow_echo "$(date +"%F %T") get RecordList Fail! Create $sub_domain Domain Record"
		RecordCreate=$(curl -X POST https://dnsapi.cn/Record.Create -d "login_token=${login_token}&domain=${domain}&sub_domain=${sub_domain}&record_type=A&record_line_id=0&value=${PublicIP}&format=json&lang=en")
		RecordCreateStatus=$(echo "$RecordCreate" | jq ".status.code" | sed 's/"//g')
		if [ "$RecordCreateStatus" = 1 ]; then
			blue_echo "$(date +"%F %T") Create $sub_domain Domain Record $PublicIP Success! Exit. \n$RecordCreate "
		else
			red_echo "$(date +"%F %T") Create $sub_domain Domain Record $PublicIP Fail! Exit. \n$RecordCreate "
		fi
		exit 1
		
	else
		red_echo "$(date +"%F %T") get RecordList Fail! Exit. \n$RecordList "
		exit 3
	fi
	RecordID=$(echo "$RecordList" | jq ".records[].id" | sed 's/"//g')
	RecordValue=$(echo "$RecordList" | jq ".records[].value" | sed 's/"//g')
	[ -z "$RecordID" -o -z "$RecordValue" ] && red_echo "$(date +"%F %T") get RecordID or RecordValue is Null, Exit" && exit 3
	
	if [ "$PublicIP" != "$RecordValue" ]; then
		# 变更解析IP
		RecordModify=$(curl -X POST https://dnsapi.cn/Record.Modify -d "login_token=${login_token}&domain=${domain}&record_id=${RecordID}&sub_domain=${sub_domain}&value=${PublicIP}&record_type=A&record_line_id=0&format=json&lang=en")
		RecordModifyStatus=$(echo "$RecordModify" | jq ".status.code" | sed 's/"//g')
		if [ "$RecordModifyStatus" = 1 ]; then
			blue_echo "$(date +"%F %T") The Record_Value: $RecordValue is different as Public_IP: $PublicIP , RecordModify SUCCESS "
		else 
			red_echo "$(date +"%F %T") The Record_Value: $RecordValue is different as Public_IP: $PublicIP , RecordModify FAIL \n$RecordModify "
		fi
	else
		blue_echo "$(date +"%F %T") The Record_Value and Public_IP are the same is  $RecordValue " 
	fi

else
# ================== 若未安装 jq 软件，则使用Linux自带命令操作，适用于：软硬路由系统、嵌入式... ==================
	# 获取子域名RecordID、RecordValue
	RecordList=$(curl -X POST https://dnsapi.cn/Record.List -d "login_token=${login_token}&domain=${domain}&sub_domain=${sub_domain}&format=xml&lang=en")
	RecordListStatus=$(echo "$RecordList" | awk -F '[<>]' '/<code>/ {print $3}')
	if [ "$RecordListStatus" = 1 ];then
		blue_echo "$(date +"%F %T") get RecordList Success "
	elif [ "$RecordListStatus" = 10 ];then
		yellow_echo "$(date +"%F %T") get RecordList Fail! Create $sub_domain Domain Record"
		RecordCreate=$(curl -X POST https://dnsapi.cn/Record.Create -d "login_token=${login_token}&domain=${domain}&sub_domain=${sub_domain}&record_type=A&record_line_id=0&value=${PublicIP}&format=xml&lang=en")
		RecordCreateStatus=$(echo "$RecordCreate" | awk -F '[<>]' '/<code>/ {print $3}')
		if [ "$RecordCreateStatus" = 1 ]; then
			blue_echo "$(date +"%F %T") Create $sub_domain Domain Record $PublicIP Success! Exit. \n$RecordCreate "
		else
			red_echo "$(date +"%F %T") Create $sub_domain Domain Record $PublicIP Fail! Exit. \n$RecordCreate "
		fi
		exit 1
	else
		red_echo "$(date +"%F %T") get RecordList Fail! Exit. \n$RecordList "
		exit 3
	fi
	RecordID=$(echo "$RecordList" | grep \<id\> | awk -F '[<>]' 'NR==2 {print $3}')
	RecordValue=$(echo "$RecordList" | awk -F '[<>]' '/<value>/ {print $3}')
	[ -z "$RecordID" -o -z "$RecordValue" ] && red_echo "$(date +"%F %T") get RecordID or RecordValue is Null, Exit" && exit 3
	
	if [ "$PublicIP" != "$RecordValue" ]; then
		# 变更解析IP
		RecordModify=$(curl -X POST https://dnsapi.cn/Record.Modify -d "login_token=${login_token}&domain=${domain}&record_id=${RecordID}&sub_domain=${sub_domain}&value=${PublicIP}&record_type=A&record_line_id=0&format=xml&lang=en")
		RecordModifyStatus=$(echo "$RecordModify" | awk -F '[<>]' '/<code>/ {print $3}')
		if [ "$RecordModifyStatus" = 1 ]; then
			blue_echo "$(date +"%F %T") The Record_Value: $RecordValue is different as Public_IP: $PublicIP , RecordModify Success "
		else 
			red_echo "$(date +"%F %T") The Record_Value: $RecordValue is different as Public_IP: $PublicIP , RecordModify FAIL \n$RecordModify "
		fi
	else
		blue_echo "$(date +"%F %T") The Record_Value and Public_IP are the same is  $RecordValue " 
	fi

fi

