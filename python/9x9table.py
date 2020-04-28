# row 行    col列
import function_study

row = 1
while row <= 9:
    col = 1
    while col <= row:
        print("%d * %d = %d" % (col, row, row * col), end="\t")
        col += 1
    print("")
    row += 1

function_study.multiple_table()