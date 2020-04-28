import pymysql

username = input("请输入mysql用户名: ")
passwd = input("请输入mysql登陆密码: ")
sql_command = "show databases"

conn = pymysql.connect(host="192.168.200.200",port=3306,user=username,password=passwd,db="product",charset="utf8")
curs = conn.cursor()
ret = curs.execute(sql_command)
curs.close()
conn.close()

if ret:
    print("登陆成功")
else:
    print("登陆失败")