import keyword

def multiple_table():
    """9 9 乘法表"""
    row = 1         # row 行    col列
    while row <= 9:
        col = 1
        while col <= row:
            print("%d * %d = %d" % (col, row, row * col), end="\t")
            col += 1
        print("")
        row += 1


a = keyword.kwlist

print(len(a))