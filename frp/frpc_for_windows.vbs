' support windows ; for my_commputer , not other's device
On Error Resume Next

Dim frp,frpini,proc,procfrp,frpProcess
frp = "C:\Download\PerfLogs\frpc.exe"
frpini = "C:\Download\PerfLogs\frpc.ini"

' ------判断系统进程是否存在,方法2（判断正常）-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set procfrp = proc.ExecQuery("select * from win32_process where name = 'frpc.exe'")
For Each pf In procfrp
  frpProcess = True 
Next

set objShell = WScript.CreateObject("WScript.Shell")
If Not frpProcess Then objShell.Run (frp & " -c " & frpini), 0 End If

WScript.Quit
