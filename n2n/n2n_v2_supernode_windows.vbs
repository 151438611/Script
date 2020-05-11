' support windows 
' 1、Edge 需要安装 Windows TAP Adapter Driver (Supernode不需要此驱动); OpenVPN安装包自带TAP驱动,仅勾选TAP安装即可，安装完成可在服务中关闭OpenVPN相关服务
' 2、准备2个文件( edge.exe edge.vbs )复制到 dir_run 目录，并修改相应变量名和路径
' 2、测试 edge.vbs 是否可正常运行
' 3、开机启动目录 C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup ; 需要登陆系统才能运行，建议使用计划任务
' 4、添加进计划任务：schtasks.exe /create /tn "start_edge" /tr "C:\PerfLogs\edge.vbs" /sc onstart

On Error Resume Next
Dim dir_run, n2n
' 注意dir_run目录后面要带反斜杠 \
dir_run = "C:\PerfLogs\"
n2n = "supernode.exe -l 49452"
' ------判断系统进程是否存在-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set exeProc = proc.ExecQuery("select * from win32_process where name = 'supernode.exe'")
For Each pr In exeProc
  exeProcess = True 
Next
set objShell = WScript.CreateObject("WScript.Shell")
If Not exeProcess Then objShell.Run (dir_run & n2n), 0 End If
WScript.Quit
