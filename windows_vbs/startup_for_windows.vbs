' 适用于Windows的程序启动脚本范例
' 建议设置计划任务：开机启动、定时启动

On Error Resume Next
Dim dir_run,exeFile,conFile
' 注意dir_run目录后面要带反斜杠 \
dir_run = "C:\PerfLogs\v2ray\"
exeFile = "frpc.exe"
conFile = "frpc.ini"

' ------判断系统进程是否存在-------------------------------
Set allProcess = GetObject("winmgmts:\\.\root\cimv2")
Set findProcess = allProcess.ExecQuery("select * from win32_process where name = 'frpc.exe'")
For Each fp In findProcess
  exeProcess = True
Next

set objShell = WScript.CreateObject("WScript.Shell")
If Not exeProcess Then objShell.Run (dir_run & exeFile & " -c " & dir_run & conFile), 0 End If
WScript.Quit
