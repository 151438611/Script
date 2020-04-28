import random

string1 = "  zXiongxinyi cheng yuxuan Jun  "
string2 = " yes or no qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq"

print(string1.startswith("Xio"))
print(string1.endswith("n"))
print(string1.find("abc "))
print(string1.replace("xinyi","yuxuan"))

print(string1.ljust(40, "-"))
print(string1.rjust(40, "-"))
print(string1.center(40, "-"))

print(string1.strip().center(35,"+"))

str1 = string1.split()
for str2 in str1:
    print("分隔的内容 %s" % str2)
print(string1.split("x"))
print(string1.join(string2))
print("hh" > "hebbb")



