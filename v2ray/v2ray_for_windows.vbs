' 适用于Windows的V2ray启动脚本
' 建议设置计划任务：开机启动、定时启动

On Error Resume Next
Dim dir_run,exeFile,conFile
' 注意dir_run目录后面要带反斜杠 \
dir_run = "C:\PerfLogs\v2ray\"
exeFile = "wv2ray.exe"
conFile = "config.json"

' ------判断系统进程是否存在-------------------------------
Set allProcess = GetObject("winmgmts:\\.\root\cimv2")
Set findProcess = allProcess.ExecQuery("select * from win32_process where name = 'wv2ray.exe'")
For Each fp In findProcess
  exeProcess = True
Next

set objShell = WScript.CreateObject("WScript.Shell")
If Not exeProcess Then objShell.Run (dir_run & exeFile & " -c " & dir_run & conFile) End If
WScript.Quit
