' support windows ; for my_commputer , not other's device

On Error Resume Next

Dim dir_run,frp,frpini,proc,procfrp,frpProcess
dir_run = "C:\Download\PerfLogs\"
frp = "frpc.exe"
frpini = "frpc.ini"

' ------判断系统进程是否存在,方法2（判断正常）-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set procfrp = proc.ExecQuery("select * from win32_process where name = 'frpc.exe'")
For Each pf In procfrp
  frpProcess = True 
Next

set objShell = WScript.CreateObject("WScript.Shell")
If Not frpProcess Then objShell.Run (dir_run & frp & " -c " & dir_run & frpini), 0 End If
Set objShell = Nothing
WScript.Quit
