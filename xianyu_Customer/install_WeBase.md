### &#10161; **闲鱼客户：安装WeBase**
```
客户提供文档：https://webasedoc.readthedocs.io/zh_CN/latest/docs/WeBASE-Install/developer.html

WeBASE_version: 1.4.1
Mysql_version: 10.3.25
Python3_version: 3.8.5
Java_version: 11.0.8+10-LTS

坑： Java版本测试11.0.8版本和13版本正常; 测试1.8和11.0.9版本均无法使用,Front服务报错,无法启动5002端口

apt install openssl curl wget unzip nginx
apt install mariadb-server python3-pip
systemctl restart mariadb.service
mysql_secure_installation
mysql -uroot-p
    mysql > select user,host,password,plugin from mysql.user; 
    mysql > update mysql.user set plugin = 'mysql_native_password' where user='root' and plugin = 'unix_socket';
    mysql > GRANT ALL PRIVILEGES ON *.* TO 'test'@% IDENTIFIED BY '123456' WITH GRANT OPTION;
    mysql > FLUSH PRIVILEGES;
pip3 install PyMySQL
cd Webase-master/deploy
vi common.properties          # 配置数据库帐号
# 一键部署
    部署并启动所有服务        python3 deploy.py installAll
    停止一键部署的所有服务    python3 deploy.py stopAll
    启动一键部署的所有服务    python3 deploy.py startAll
# 各子服务启停
    启动FISCO-BCOS节点:      python3 deploy.py startNode
    停止FISCO-BCOS节点:      python3 deploy.py stopNode
    启动WeBASE-Web:          python3 deploy.py startWeb
    停止WeBASE-Web:          python3 deploy.py stopWeb
    启动WeBASE-Node-Manager: python3 deploy.py startManager
    停止WeBASE-Node-Manager: python3 deploy.py stopManager
    启动WeBASE-Sign:         python3 deploy.py startSign
    停止WeBASE-Sign:         python3 deploy.py stopSign
    启动WeBASE-Front:        python3 deploy.py startFront
    停止WeBASE-Front:        python3 deploy.py stopFront
# 可视化部署
    部署并启动可视化部署的所有服务  python3 deploy.py installWeBASE
    停止可视化部署的所有服务  python3 deploy.py stopWeBASE
    启动可视化部署的所有服务  python3 deploy.py startWeBASE

打开浏览器访问webase web界面:  IP:5000
```

