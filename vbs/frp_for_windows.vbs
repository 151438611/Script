' 用于windows启动脚本，注意执行路径中不能有空格。
'On Error Resume Next

Dim frp, frpini, proc, procOfFrp, frpProc, ObjShell
frp = "E:\kodexplorer\frpc\frpc.exe"
frpini = "E:\kodexplorer\frpc\frpc.ini"


Set proc = GetObject("winmgmts:\\.\root\cimv2")
' name = 需要手动输入程序名，使用变量无法识别
Set procOfFrp = proc.ExecQuery("select * from win32_process where name = 'frpc.exe'")

  frpProc = False
For Each pf In procOfFrp
  frpProc = True 
Next
'MsgBox "frpProc is " & frpProc
Set ObjShell = WScript.CreateObject("WScript.Shell")
If Not frpProc Then ObjShell.Run (frp & " -c " & frpini), 0 End If
Set ObjShell = Nothing
WScript.Quit
