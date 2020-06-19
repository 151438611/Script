#!/bin/bash
# tencent domain ddns , Only support x86_64/arm64 Linux

domain=xxy1.ltd
subDomain=test1
# ===== Change SecretId / SecretKey ===========
sId=""
sKey=""
# =============================================

timestamp=$(date +%s)
nonce=$(head -n 8 /dev/urandom | tr -cd 0-9 | head -c 5)
signatureMethod=HmacSHA1
url="https://cns.api.qcloud.com/v2/index.php"

getRecordId() {
	action=RecordList
	
	src=$(printf "GETcns.api.qcloud.com/v2/index.php?Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s" $action $nonce $sId $signatureMethod $timestamp $domain)
	signature=$(echo -n $src | openssl dgst -sha1 -hmac $sKey -binary | base64)

	params=$(printf "Action=%s&domain=%s&Nonce=%s&SecretId=%s&Signature=%s&SignatureMethod=%s&Timestamp=%s" $action $domain $nonce $sId "$signature" $signatureMethod $timestamp)

	
	recordId=$(curl -G -d "$params" --data-urlencode "Signature=$signature" "$url" | \
	grep "$subDomain" | awk -F \"name\":\""'$subDomain'"\" '{print $1}' | awk -F \{ '{print $NF}' | awk -F \, '{print $1}' | tr -cd 0-9)
}

getRecordId
[ -z "$recordId" ] && echo "Get recordId Fail !!!" && exit 1

changeRecordModify() {
	
	action=RecordModify
	recordType=A
	recordLine='默认'
	
	# get public ip address
	getIP=$(curl -q http://ip.sb)
	value=$getIP

	src=$(printf "GETcns.api.qcloud.com/v2/index.php?Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s&recordId=%s&recordLine=%s&recordType=%s&subDomain=%s&value=%s" $action $nonce $sId $signatureMethod $timestamp $domain $recordId $recordLine $recordType $subDomain $value)

	signature=$(echo -n $src | openssl dgst -sha1 -hmac $sKey -binary | base64)

	params=`printf "Action=%s&Nonce=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&domain=%s&recordId=%s&recordLine=%s&recordType=%s&subDomain=%s&value=%s" $action $nonce $sId $signatureMethod $timestamp $domain $recordId $recordLine $recordType $subDomain $value`

	curl -G -d "$params" --data-urlencode "Signature=$signature" "$url"
}

changeRecordModify
