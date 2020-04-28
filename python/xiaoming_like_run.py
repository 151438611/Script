class Person:
    def __init__(self, name, weight):
        self.name = name
        self.weight = weight

    def __str__(self):
        return "我的名字是 %s ,我的体重是 %.2f kg" % (self.name,self.weight)

    def run(self):
        print("%s 爱跑步，跑步锻炼身体" % self.name)
        self.weight -= 0.5
        pass
    def eat(self):
        print("%s 吃东西易长胖" % self.name)
        self.weight += 1.5
        pass

xm = Person("xiaoming",75)
#xm.run()
xm.eat()
print(xm)