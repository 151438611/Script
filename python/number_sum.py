def num_sum(num1,num2):
    """
    输出二个数字的相加
    :param num1:
    :param num2:
    """
    if num1 == "":
        num1 = 0
    elif num2 == "":
        num2 = 0
    result = num1 + num2
    print("%d + %d = %d" %(num1,num2,result))
 #   return result

num_sum(2,5)

name_list=["wwu","lisi","zhsh"]
name_list.remove()