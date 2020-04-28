import os

print(os.name)
os.chdir("C:\PerfLogs")
print(os.getcwd())
print(os.getenv("PATH"))
print(os.path.basename("/var/log/xx.log"))
print(os.path.dirname("/var/log/xx.log"))
