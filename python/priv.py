

class Woman:
    def __init__(self, name):
        self.name = name
        self.age = 20

    def secret(self):
        print("%s 的年龄是 %d" % (self.name, self.age))

xiaofang = Woman("小芳")
xiaofang.secret()