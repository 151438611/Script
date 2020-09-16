' 用于快速进入指定文件夹的脚本
' 文件夹路径格式：  e:    E:\download   \\192.168.10.250\Share 
' 需要先依赖 edge 程序已运行

dirPath = "\\10.5.5.28\Share"

perCMD = "C:\PerfLogs\n2n_v2_edge_windows.vbs"
intoCMD = "explorer.exe /e," & dirPath

' ------判断 edge 进程是否存在-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set exeProc = proc.ExecQuery("select * from win32_process where name = 'edge.exe'")
For Each pr In exeProc
  exeProcess = True 
Next
set objShell = WScript.CreateObject("Wscript.Shell")
If Not exeProcess Then 
	objShell.Run perCMD
	WScript.Sleep 3000
End If

objShell.Run intoCMD
