'On Error Resume Next

' ------判断系统进程是否存在，存在不操作，不存在就启动程序-------------------------------

Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set frpc = proc.ExecQuery("select * from win32_process where name = 'frpc.exe'")

For Each pf In frpc
  existfrpc = True 
Next

set obj = WScript.CreateObject("WScript.Shell")

If Not existfrpc Then obj.Run "C:\PerfLogs\frpc.exe -c C:\PerfLogs\frpc.ini", 0 End If
