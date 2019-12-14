#!/usr/bin/env python3
#coding:utf-8
# Author: XJ Date: 20191214
# 用于淘宝网的抢购活动，准备工作：
#   1、安装软件和浏览器驱动：pip install selenium==3.14.1
#   2、因密码登陆需要划块验证，无法通过；建议提前3~5分钟运行，使用手机app扫码手动登陆
#   3、需要将活动商品事先添加进购物车，脚本只负责到时间提交(大概在10秒内)
# 脚本工作流程：
#   打开购物车---若未登陆则自动跳转登陆页面---扫码登陆---判断抢购时间---进入购物车---点击结算---提交订单---手动付款完成
import time, datetime
from selenium import webdriver

# 先定义抢购时间，格式："2020-01-01 00:01:00"
buy_time = "2019-12-14 23:50:00"
# 浏览器驱动存放路径,格式："D:\Python37\Scripts\chromedriver.exe"；若在环境变量中可不写
driver_path="D:\Python37\Scripts\chromedriver.exe"
# 打开网页
options = webdriver.ChromeOptions()
# options.add_argument("--headless")  # 使用无界面选项
# options.add_argument("--disable-gpu")   # 如果不加这个选项 有时候定位会出现问题,定位会偏左
if driver_path:
    browser = webdriver.Chrome(options=options, executable_path=driver_path)
else:
    browser = webdriver.Chrome(options=options)

def login():
    # 购物网站地址，格式(一定要加前缀)： https://xxx.com
    browser.get("https://cart.taobao.com/cart.htm")
    # 打开网页后等待页面加载完成，根据网速不同，需要一点时间
    time.sleep(3)
    #browser.find_element_by_link_text("亲，请登录").click()
    # 登陆方式：默认扫码登陆0 密码登陆1
    password_login = 0
    if password_login == 0:
        #pass
        input("请打开 手机淘宝 扫码网页上的二维码登陆，完成后按 Enter键 继续执行后面的代码")
        time.sleep(1)
    elif password_login == 1:
        # 密码登陆无法输入划块验证，建议使用扫码登陆
        browser.find_element_by_link_text("密码登录").click()
        browser.find_element_by_id("TPL_username_1").send_keys("username")
        browser.find_element_by_id("TPL_password_1").send_keys("password")
        browser.find_element_by_id("J_SubmitStatic").click()
        time.sleep(3)
    # 检查是否登陆成功，判断是否出现 "消息"
    try:
        if browser.find_element_by_xpath("//span[@class='J_Tmsg_Logo_Text tmsg_logo_text']"):
            print(f"登陆成功！", browser.find_element_by_xpath("//span[@class='J_Tmsg_Logo_Text tmsg_logo_text']").text)
    except:
        print(f"登陆失败，请重新登陆！！！")
        exit(1)

def shoping():
    while True:
        now_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
        if now_time > buy_time:
            print(f"现在时间：",now_time," ,正在抢购......")
            # 登陆购物车
            browser.get("https://cart.taobao.com/cart.htm")
            time.sleep(2)
            try:
                if browser.find_element_by_xpath("//span[@class='J_Tmsg_Logo_Text tmsg_logo_text']"):
                    print(f"已登陆成功！", browser.find_element_by_xpath("//span[@class='J_Tmsg_Logo_Text tmsg_logo_text']").text)
            except:
                print(f"登陆已失败，正在重新登陆......")
                login()
            # 勾选购物车列表：1表示全选 0表示手动勾选
            method = 1
            if method == 1:
                while True:
                    try:
                        if browser.find_element_by_id("J_SelectAll1"):
                            browser.find_element_by_id("J_SelectAll1").click()
                            time.sleep(3)
                            print(f"已勾选所有商品，等待结算......")
                            break
                    except:
                        print(f"没有找到全选按钮,请检查：购物车是否为空 或 cookies是否已失效 ？？？")
                        exit(1)
            else:
                input("请手动勾选商品列表，完成后按 Enter回车键 继续执行后面代码")
            # 到了抢购时间，开始结算
            while True:
                try:
                    if browser.find_element_by_id("J_SmallSubmit"):
                        browser.find_element_by_id("J_SmallSubmit").click()
                        print(f"正在提交结算.....")
                        time.sleep(3)
                        break
                except:
                    pass
            while True:
                try:
                    if browser.find_element_by_link_text("提交订单"):
                        browser.find_element_by_link_text("提交订单").click()
                        print(f"提交订单成功，请尽快付款 ！！！")
                        break
                except:
                    pass
            break
        else:
            #print(f"未到抢购时间：", now_time, " ，请耐心等待......")
            time.sleep(1)

def main():
    login()
    shoping()

if __name__ == "__main__":
    main()
