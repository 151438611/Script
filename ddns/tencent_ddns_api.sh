#!/bin/bash
# Tencent Domain ddns API, Only support x86_64/arm64 Linux、Synogly-DSM 6.x
# Dependencies command: curl、openssl、base64、printf

Domain=xxy1.ltd
SubDomain=n2n
# ===== Change SecretId / SecretKey ===========
SecretId="RaAKIDKZhmrmwGH661s2xUOoxulTv5oOhj46xx"
SecretKey="MG82yeDYP4TciiRIu3xb0BGCTZVCfrpExx"
# =============================================
Timestamp=$(date +%s)
Nonce=$(head -n 8 /dev/urandom | tr -cd 0-9 | head -c 5)
SignatureMethod=HmacSHA1
URL="https://cns.api.qcloud.com/v2/index.php"
DDNSLog=/tmp/tencent_ddns.log

getRecordID() {
	Action=RecordList
	SRC=$(printf "GETcns.api.qcloud.com/v2/index.php?Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s" \
		$Action $Nonce $SecretId $SignatureMethod $Timestamp $Domain)
	Signature=$(echo -n $SRC | openssl dgst -sha1 -hmac $SecretKey -binary | base64)
	Params=$(printf "Action=%s&domain=%s&Nonce=%s&SecretId=%s&Signature=%s&SignatureMethod=%s&Timestamp=%s" \
		$Action $Domain $Nonce $SecretId "$Signature" $SignatureMethod $Timestamp)
	AllRecord=$(curl -G -d "$Params" --data-urlencode "Signature=$Signature" "$URL" | sed 's/{/\n/g' | grep \"name\":\"$SubDomain\")
	RecordID=$(echo $AllRecord | awk -F [:,] '{print $2}')
	RecordIP=$(echo $AllRecord | awk -F [:,\"] '{print $13}')
}
getRecordID
[ -z "$RecordID" -o -z "$RecordIP" ] && echo "Get Record ID or IP Fail !!!" >> $DDNSLog && exit 1

changeRecordModify() {
	Action=RecordModify
	RecordType=A
	RecordLine='默认'
	
	# get public ip address
	RecordValue=$(curl -4 -q ip.3322.net)
	[ "$RecordValue" ] || RecordValue=$(curl -4 -q ip.cip.cc)
	
    	if [ "$RecordValue" = "$RecordIP" -o -z "$RecordValue" ]; then
		echo "$(date +"%F %T") The Record_IP and Public_IP are the same is  $RecordIP " >> $DDNSLog
	else
		SRC=$(printf "GETcns.api.qcloud.com/v2/index.php?Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s&recordId=%s&recordLine=%s&recordType=%s&subDomain=%s&value=%s" \
			$Action $Nonce $SecretId $SignatureMethod $Timestamp $Domain $RecordID $RecordLine $RecordType $SubDomain $RecordValue)
		Signature=$(echo -n $SRC | openssl dgst -sha1 -hmac $SecretKey -binary | base64)
		Params=$(printf "Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s&recordId=%s&recordLine=%s&recordType=%s&subDomain=%s&value=%s" \
			$Action $Nonce $SecretId $SignatureMethod $Timestamp $Domain $RecordID $RecordLine $RecordType $SubDomain $RecordValue)
		curl -G -d "$Params" --data-urlencode "Signature=$Signature" "$URL"
		[ $? -eq 0 ] && echo "$(date +"%F %T") The Record_IP: $RecordIP is different as Public_IP: $RecordValue , changeRecordModify success !" >> $DDNSLog || \
			echo "$(date +"%F %T") The Record_IP: $RecordIP is different as Public_IP: $RecordValue , but changeRecordModify fail !!!" >> $DDNSLog 
	fi
}
changeRecordModify

