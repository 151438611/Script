# 执行语句流程： 顺序、if分支、while循环
# while
# break continue

# 打印1-100所有整数相加的和
i = 0
result = 0
while i <= 100:
    result += i
    i += 1
print("1~100 sum is %d" % result)
# 打印1-100所有偶数相加的和
i = 0
result = 0
while i <= 100:
    if i % 2 ==0:
        result += i
    i += 1
print("1~100 中所有偶数的和 = %d" % result)