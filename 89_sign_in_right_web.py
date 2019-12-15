#!/usr/bin/env python3
#coding:utf-8

import time
from selenium import webdriver

# 浏览器驱动存放路径,格式："D:\Python37\Scripts\chromedriver.exe"；若在环境变量中可不写
driver_path="D:\Python37\Scripts\chromedriver.exe"
# 打开网页
options = webdriver.ChromeOptions()
#options.add_argument("--headless")  # 使用无界面选项
#options.add_argument("--disable-gpu")   # 如果不加这个选项 有时候定位会出现问题,定位会偏左
if driver_path:
    browser = webdriver.Chrome(options=options, executable_path=driver_path)
else:
    browser = webdriver.Chrome(options=options)
browser.implicitly_wait(5)
username = "xx."
password = "xx"
def login():
    browser.get("https://www.right.com.cn/forum/")
    browser.find_element_by_xpath("//input[@id='ls_username' and @name='username' and @type='text']").send_keys(username)
    browser.find_element_by_xpath("//input[@id='ls_password' and @name='password' and @type='password']").send_keys(password)
    browser.find_element_by_xpath("//button[@type='submit' and @class='pn vm']/em").click()
    time.sleep(3)
    try:
        if browser.find_element_by_xpath("//a[@id='myitem' and @class='showmenu']"):
            print(f"登陆成功！", browser.find_element_by_xpath("//a[@id='myitem' and @class='showmenu']").text)
            browser.find_element_by_link_text("斐讯无线路由器以及其它斐迅网络设备").click()
    except:
        print(f"登陆失败！！！")

def main():
    login()

if __name__ == "__main__":
    main()
