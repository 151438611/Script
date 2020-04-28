company = {"name1": "10gtek",
           "count1": 220,
           "swtich": "cisco 3232"
           }
tmp_dict = {"height":180, "count1":800}
# 从字典中取值,若指定的key不存在则报错
print(company["name1"])
# 从字典中增加键值对，若键不存在，则新增
company["speed"] = "1/10/40G"
# 从字典中修改键值对，，若键存在，则修改
company["count1"] = 3232
print(company)
# 删除字典
company.pop("count1")
print(company)
# 统计字典中的键值对数量
print(len(company))
#合并字典
company.update(tmp_dict)
print(company)
# 清空字典元素
#company.clear()
#print(company)

# 遍历字典 key1变量这每次循环中获取的key
for key1 in company:
    print("%s - %s" % (key1,company[key1]))
