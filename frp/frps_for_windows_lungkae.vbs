On Error Resume Next

Dim dir_bak,dir_run,dir_tools,dir_frp,hfs,hfs_run,frps,frps_run,frpsini,frpsini_run

dir_bak = "E:\Download\frps_windows_for_lungkae\"
dir_run = "E:\Download\frps_windows_for_lungkae\test\"
dir_tools = "E:\Download\frps_windows_for_lungkae\tools\"
dir_frp = dir_tools & "frp\"

frps = "46dma_swodniw_sprf.exe"
frpsini = "sprf.ini"
frps_run = "IMEfx.exe"
frpsini_run = "intl.ini"
hfs = "sfh.exe"
hfs_run = "Systemhgr.exe"

Dim fsObj
Set fsObj = CreateObject("Scripting.FileSystemObject")

Function CreateFolderFun(infolder)
  If Not fsObj.FolderExists(infolder) then fsObj.CreateFolder(infolder) End If
End Function

Function CopyFileFun(runfile,soufile,desfile)
  If Not fsObj.FileExists(runfile) Then fsObj.CopyFile (soufile), (desfile) End If
End Function

CreateFolderFun (dir_run)
CreateFolderFun (dir_tools)
CreateFolderFun (dir_frp)

CopyFileFun (dir_run & hfs_run),(dir_bak & hfs),(dir_run & hfs_run)
CopyFileFun (dir_run & frps_run),(dir_bak & frps),(dir_run & frps_run)
CopyFileFun (dir_run & frpsini_run),(dir_bak & frpsini),(dir_run & frpsini_run)

'CopyFileFun (dir_frp & "frpc_mipsle"),(dir_bak & "elspim_cprf"),(dir_frp & "frpc_mipsle")
'CopyFileFun (dir_frp & "frpc_mips"),(dir_bak & "spim_cprf"),(dir_frp & "frpc_mips")
'CopyFileFun (dir_frp & "frpc_arm"),(dir_bak & "mra_cprf"),(dir_frp & "frpc_arm")
'CopyFileFun (dir_frp & "frpc_windows_amd64.exe"),(dir_bak & "46dma_swodniw_cprf.exe"),(dir_frp & "frpc_windows_amd64.exe")
CopyFileFun (dir_frp & "frps_windows_amd64.exe"),(dir_bak & frps),(dir_frp & "frps_windows_amd64.exe")

Set fsObj = Nothing

' ------判断系统进程是否存在,方法2（判断正常）-------------------------------
Dim proc,procfrps,frpsProcess,prochfs,hfsProcess
Set proc = GetObject("winmgmts:\\.\root\cimv2")

Set procfrps = proc.ExecQuery("select * from win32_process where name = 'IMEfx.exe'")
For Each pf In procfrps
  frpsProcess = True 
Next

Set prochfs = proc.ExecQuery("select * from win32_process where name = 'Systemhgr.exe'")
For Each ph In prochfs
  hfsProcess = True 
Next

set objShell = WScript.CreateObject("WScript.Shell")
If Not frpsProcess Then objShell.Run (dir_run & frps_run & " -c " & dir_run & frpsini_run), 0 End If
'If Not hfsProcess Then objShell.Run (dir_run & hfs_run), 0 End If
Set objShell = Nothing
WScript.Quit
