' support windows 
' 1��Edge ��Ҫ��װ Windows TAP Adapter Driver (Supernode����Ҫ������); OpenVPN��װ���Դ�TAP����,����ѡTAP��װ���ɣ���װ��ɿ��ڷ����йر�OpenVPN��ط���
' 2��׼��2���ļ�( edge.exe edge.vbs )���Ƶ� dir_run Ŀ¼�����޸���Ӧ��������·��
' 2������ edge.vbs �Ƿ����������
' 3����������Ŀ¼ C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup ; ��Ҫ��½ϵͳ�������У�����ʹ�üƻ�����
' 4����ӽ��ƻ�����schtasks.exe /create /tn "start_edge" /tr "C:\PerfLogs\edge.vbs" /sc onstart

' On Error Resume Next
Dim dir_run, exec
' ע��dir_runĿ¼����Ҫ����б�� \
dir_run = "C:\PerfLogs\nginx\"
exec = "nginx.exe -p " 
' ------�ж�ϵͳ�����Ƿ����-------------------------------

Set proc = GetObject("winmgmts:\\.\root\cimv2")
Set exeProc = proc.ExecQuery("select * from win32_process where name = 'nginx.exe'")
For Each pr In exeProc
  exeProcess = True 
Next
set objShell = WScript.CreateObject("WScript.Shell")
'set objShell = CreateObject("WScript.Shell")
If Not exeProcess Then objShell.Run (dir_run & exec & dir_run), 0 End If
WScript.Quit
