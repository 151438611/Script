
def sum_num(num):
    if num == 1:
        return 1
    temp = sum_num(num - 1)
    return num + temp


print(sum_num(500))
print(sum_num(600))