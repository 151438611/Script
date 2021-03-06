#!/usr/bin/python3
#coding=utf-8
# create date: 20190920 by xj
# First installed : pip3 install aliyun-python-sdk-core-v3 aliyun-python-sdk-alidns
# Aliyun_API: https://api.aliyun.com/?spm=a2c4e.11153940.0.0.71e757fcrl4KBh#/?product=Alidns&api=DescribeSubDomainRecords&params={}&tab=DEMO&lang=PYTHON

import os, json
from aliyunsdkcore.client import AcsClient
from aliyunsdkalidns.request.v20150109.DescribeSubDomainRecordsRequest import DescribeSubDomainRecordsRequest
from aliyunsdkalidns.request.v20150109.UpdateDomainRecordRequest import UpdateDomainRecordRequest
from aliyunsdkalidns.request.v20150109.SetDomainRecordStatusRequest import SetDomainRecordStatusRequest

# 输入下列信息； domainName表示被自动修改IP的域名名称
client = AcsClient('accessKeyId', 'accessSecret', 'cn-hangzhou')
domainName = "frp1.xiongxinyi.cn"

def getRealIP():
    ipInfo = os.popen("curl https://ip.cn").read()
    getIP = ipInfo.split('"')[3]
    if len(getIP) == 0:
        print("IP is empty, Get IP is Fail !!!")
        exit()
    else:
        print("Get IP Success : %s \n" % getIP)
    return getIP

def getDomainRecords(demain_ch):
    # 传入被修改的域名，示例: frp.xiongxinyi.cn
    request = DescribeSubDomainRecordsRequest()
    request.set_accept_format('json')
    request.set_SubDomain(demain_ch)
    response = client.do_action_with_exception(request)
    print("GetDomainRecordsInfo Success : \n", str(response, encoding='utf-8'), "\n")
    response = json.loads(response)
    record = response['DomainRecords']["Record"][0]
    # RR 示例： frp
    recordRR = record["RR"]
    # Value 示例： 211.161.61.50
    recordValue = record["Value"]
    # RecordId (可通过DescribeSubDomainRecords查询) 示例：1668555555
    recordRecordId = record["RecordId"]
    # Type 类型示例： A、CNAME、AAAA ......
    recordType = record["Type"]
    return recordRR, recordValue, recordRecordId, recordType

def updateDomainRecord(RR, myIP, RecordId, Type):
    # 传入被修改的信息；RR域名前缀 myIP当前的IP地址
    request = UpdateDomainRecordRequest()
    request.set_RecordId(RecordId)
    request.set_RR(RR)
    request.set_Type(Type)
    request.set_Value(myIP)
    response = client.do_action_with_exception(request)
    print("UpdateDomainRecordInfo Success : \n", str(response, encoding='utf-8'), "\n")
	
def setDomainRecordStatus(recordId, status):
	# 传入被修改域名的RecordId和状态(Enable启动或Disable暂停)
	request = SetDomainRecordStatusRequest()
	request.set_RecordId(recordId)
	request.set_Status(status)
	response = client.do_action_with_exception(request)
	print("SetDomainRecordStatusInfo Success : \n", str(response, encoding='utf-8'), "\n")

def main():
	myIP = getRealIP()
	recordRR, recordValue, recordRecordId, recordType = getDomainRecords(domainName)
	if myIP == recordValue:
		print("Current IP is the same as DomainRecord %s \n" % myIP)
	else:
		updateDomainRecord(recordRR, myIP, recordRecordId, recordType)
		setDomainRecordStatus(recordRecordId, "Enable")
	
if __name__ == '__main__':
	main()
