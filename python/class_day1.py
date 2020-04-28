

# 小猫： 吃鱼 喝水
class Cat():

    def __init__(self,newName):
        self.name = newName
    def eat(self):
        print("名字叫 %s" % self.name)
        pass
    def drink(self):
        print("猫喝水")
        pass

tom = Cat("tom")
#tom.name = "tomson"
tom.eat()
tom.drink()
print(tom.name)