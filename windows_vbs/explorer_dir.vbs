' 用于快速进入指定文件夹的脚本
' 文件夹路径格式：  e:    E:\download   \\192.168.10.250\Share 
' 若进入共享远程文件夹，需要先手动让系统记住保存下网络凭据
' 若使用edge，需要先依赖 edge 程序已运行

' ====== for local =========================
dirPath = "\\192.168.200.250\Share"
intoCMD = "explorer.exe /e," & dirPath
set objShell = WScript.CreateObject("Wscript.Shell")
objShell.Run intoCMD

' ====== for n2n edge =========================
dirPath = "\\10.5.5.18\Share"
intoCMD = "explorer.exe /e," & dirPath
perCMD = "C:\PerfLogs\n2n_v2_edge_windows.vbs"

set objShell = WScript.CreateObject("Wscript.Shell")
' ------判断 edge 进程是否存在-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set exeProc = proc.ExecQuery("select * from win32_process where name = 'edge.exe'")
For Each pr In exeProc
  exeProcess = True 
Next
If Not exeProcess Then 
	objShell.Run perCMD
	WScript.Sleep 3000
End If

objShell.Run intoCMD
