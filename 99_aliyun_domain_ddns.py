#!/usr/bin/python3
#coding=utf-8
# create date: 20190920 by xj
# First need installed : pip3 install aliyun-python-sdk-core-v3 aliyun-python-sdk-alidns
# Aliyun_API: https://api.aliyun.com/?spm=a2c4e.11153940.0.0.71e757fcrl4KBh#/?product=Alidns&api=DescribeSubDomainRecords&params={}&tab=DEMO&lang=PYTHON

import os, json
from aliyunsdkcore.client import AcsClient
from aliyunsdkalidns.request.v20150109.DescribeSubDomainRecordsRequest import DescribeSubDomainRecordsRequest
from aliyunsdkalidns.request.v20150109.UpdateDomainRecordRequest import UpdateDomainRecordRequest

# 输入下列信息； domainName表示被自动修改IP的域名名称
client = AcsClient('AccessKeyID', 'AccessKeySecret', 'cn-hangzhou')
domainName = "frp.xiongxinyi.cn"

def getRealIP():
    ipInfo = os.popen("curl https://ip.cn").read()
    getIP = ipInfo.split('"')[3]
    if len(getIP) == 0 :
        print("ip is empty, Get IP is Fail !!!")
        exit()
    return getIP

def getDomainRecords(demain_ch):
    # 传入被修改的域名，示例: frp.xiongxinyi.cn
    request = DescribeSubDomainRecordsRequest()
    request.set_accept_format('json')
    request.set_SubDomain(demain_ch)
    response = client.do_action_with_exception(request)
    #print(str(response, encoding='utf-8'))
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
    print(str(response, encoding='utf-8'))

myIP = getRealIP()
recordRR, recordValue, recordRecordId, recordType = getDomainRecords(domainName)
if myIP != recordValue :
    updateDomainRecord(recordRR, myIP, recordRecordId, recordType)

