' support windows ; for my_commputer , not other's device
' 1、准备文件( edge.exe、edge.vbs )复制到 dir_run 目录，并修改相应变量名和路径
' 2、测试 edge.vbs 是否可正常运行
' 3、复制 edge.vbs 到系统开机启动目录并重命名为 systemstartup.vbs (并建议删除所有注释)---停用，改用计划任务
'    开机启动目录 C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup
' 4、添加进计划任务：schtasks.exe /create /tn "edge" /tr "C:\PerfLogs\edge.vbs" /sc daily /st 07:00:00

On Error Resume Next
Dim dir_run, edge
' 注意dir_run目录后面要带反斜杠 \
dir_run = "C:\PerfLogs\"
runCMD = "edge.exe -d edge -c n2n -a 10.0.0.x -s 255.255.255.0 -l frp.xiongxinyi.cn:44275"

' ------判断系统进程是否存在-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set procrun = proc.ExecQuery("select * from win32_process where name = 'edge.exe'")
For Each pr In procrun
  Processrun = True 
Next
set objShell = WScript.CreateObject("WScript.Shell")
If Not Processrun Then objShell.Run (dir_run & runCMD), 0 End If
WScript.Quit
