#!/bin/bash
# tencent domain ddns , Only support x86_64/arm64 Linux

Domain=xxy1.ltd
SubDomain=wzt
# ===== Change SecretId / SecretKey ===========
SecretId="xx"
SecretKey="xx"
# =============================================
Timestamp=$(date +%s)
Nonce=$(head -n 8 /dev/urandom | tr -cd 0-9 | head -c 5)
SignatureMethod=HmacSHA1
URL="https://cns.api.qcloud.com/v2/index.php"
Log=/tmp/ddns.log

getRecordID() {
	Action=RecordList
	SRC=$(printf "GETcns.api.qcloud.com/v2/index.php?Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s" $Action $Nonce $SecretId $SignatureMethod $Timestamp $Domain)
	Signature=$(echo -n $SRC | openssl dgst -sha1 -hmac $SecretKey -binary | base64)
	Params=$(printf "Action=%s&domain=%s&Nonce=%s&SecretId=%s&Signature=%s&SignatureMethod=%s&Timestamp=%s" $Action $Domain $Nonce $SecretId "$Signature" $SignatureMethod $Timestamp)
	AllRecord=$(curl -G -d "$Params" --data-urlencode "Signature=$Signature" "$URL" | sed 's/{/\n/g' | grep \"name\":\"$SubDomain\")
	RecordID=$(echo $AllRecord | awk -F [:,] '{print $2}')
	RecordIP=$(echo $AllRecord | awk -F [:,\"] '{print $13}')
}
getRecordID
[ -z "$RecordID" -o -z "$RecordIP" ] && echo "Get Record ID or IP Fail !!!" >> $Log && exit 1

changeRecordModify() {
	Action=RecordModify
	RecordType=A
	RecordLine='默认'
	
	# get public ip address
	RecordValue=$(curl -q ip.3322.net)
	[ $RecordValue ] || RecordValue=$(curl -q ip.cip.cc)
    	if [ $RecordValue = $RecordIP ]; then
		echo "$(date +"%F %T") The Record_IP($RecordIP) is same as Public_IP($getPublicIP) ." >> $Log
	else
		SRC=$(printf "GETcns.api.qcloud.com/v2/index.php?Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s&recordId=%s&recordLine=%s&recordType=%s&subDomain=%s&value=%s" $Action $Nonce $SecretId $SignatureMethod $Timestamp $Domain $RecordID $RecordLine $RecordType $SubDomain $RecordValue)
		Signature=$(echo -n $SRC | openssl dgst -sha1 -hmac $SecretKey -binary | base64)
		Params=$(printf "Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s&recordId=%s&recordLine=%s&recordType=%s&subDomain=%s&value=%s" $Action $Nonce $SecretId $SignatureMethod $Timestamp $Domain $RecordID $RecordLine $RecordType $SubDomain $RecordValue)
		curl -G -d "$Params" --data-urlencode "Signature=$Signature" "$URL"
			[ $? -eq 0 ] && echo "$(date +"%F %T") The Record_IP($RecordIP) is different as Public_IP($getPublicIP) , changeRecordModify success !" >> $Log || echo "$(date +"%F %T") The Record_IP($RecordIP) is different as Public_IP($getPublicIP) , but changeRecordModify fail !!!" >> $Log 
	fi
}
changeRecordModify
