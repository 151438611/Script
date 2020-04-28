import random
#player = int(input("请输入要出的拳：石头1 剪刀2 布3"))
player = random.randint(1,3)
if player == 1:
    player1 = "石头"
elif player == 2:
    player1 = "剪刀"
elif player == 3:
    player1 = "布"

computer = random.randint(1,3)
print("玩家输入的是 %d - 电脑出的拳 %d" % (player , computer))

# if (()
#      or ()
#      or ()):
if ((player == 1 and computer == 2)
        or (player == 2 and computer == 3)
        or (player == 3 and computer == 1)) :
    print("玩家胜利")
elif player == computer:
    print("平局")
else:
    print("电脑胜利")

computer = random.randint(0,100)
while True:
    player = int(input("请输入0-100间的任意数字："))
    if player==computer:
        print("恭喜，输入正确,游戏退出；电脑的数字为：%d" % computer)
        break
    elif player>computer:
        print("输入的数字比电脑数字大，请重新输入")
        continue
    elif player<computer:
        print("输入的数字比电脑数字小，请重新输入")
        continue