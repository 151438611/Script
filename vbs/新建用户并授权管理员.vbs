'On Error Resume Next

' 创建新用户并设置密码
set createUser=wscript.createobject("wscript.shell")
createUser.run "net user 用户名 密码  /add"
  
set wsnetwork=CreateObject("wscript.network") 
os="WinNT://"&wsnetwork.ComputerName 
Set ob=GetObject(os)      '得到adsi接口,绑定 
Set oe=GetObject(os&"/Administrators,group")     '属性,admin组 
Set od=ob.Create("user","test")         '建立用户test 
od.SetPassword "1234"                  '设置密码1234 
od.SetInfo                            '保存 
Set of=GetObject(os&"/test",user)     '得到用户 
oe.add os&"/test" 
