' support windows ; for my_commputer , not other's device
' 1、准备3个文件( frp.exe、frp.ini、frp.vbs )复制到 dir_run 目录，并修改相应变量名和路径
' 2、测试 frp.vbs 是否可正常运行
' 3、开机启动目录 C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup ; 需要登陆系统才能运行，建议使用计划任务
' 4、添加进计划任务：schtasks.exe /create /tn "frpc" /tr "C:\PerfLogs\frpc.vbs" /sc onstart

On Error Resume Next
Dim dir_run,frp,frpini
' 注意dir_run目录后面要带反斜杠 \
dir_run = "C:\PerfLogs\"
frp = "frpc.exe"
frpini = "frpc.ini"
' ------判断系统进程是否存在-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set procfrp = proc.ExecQuery("select * from win32_process where name = 'frpc.exe'")
For Each pf In procfrp
  frpProcess = True 
Next
set objShell = WScript.CreateObject("WScript.Shell")
If Not frpProcess Then objShell.Run (dir_run & frp & " -c " & dir_run & frpini), 0 End If
WScript.Quit
