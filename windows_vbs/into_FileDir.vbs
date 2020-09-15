' 用于快速进入指定文件夹的脚本
' 文件夹路径格式：  e:    E:\download   \\192.168.10.250\Share 

Path = "\\10.5.5.28\Share"

intoCMD = "explorer.exe /e," & Path

set objShell = WScript.CreateObject("Wscript.Shell")

objShell.Run intoCMD
