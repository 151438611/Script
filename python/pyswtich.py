

import serial.tools.list_ports

var1 = list(serial.tools.list_ports.comports())

var1 = "abcd"
var2 = [1, 2, 3]
def demo(v1, v2):
    var1 = v1.upper()
    v2.append(5)
    return v1, v2
var1, ret2 = demo(var1, var2)
print(var1)
print(var2)

var2+=[5,6]
var2.extend([7,8])
print(var2)

list1 = ['a','b','c']

list3 = list1.extend(['1', '2'])
print(list3)

def function_name(var, *args, **kwargs) :     #在不确定传入参数数量的情况下使用多值参数
# *args表示可以接收一个元组；**kwargs表示可以接收一个字典
    print("%s is %s and %s" % (var, args, kwargs))
function_name("小明", 2, 3, 4, a="ab", b="cd")