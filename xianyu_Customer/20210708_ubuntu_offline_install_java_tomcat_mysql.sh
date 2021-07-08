#!/bin/bash
# ￥200元
# 需求：在 ubuntu 16.04.7-server-amd64 系统中离线安装 java-1.8、mysql-5.6、tomcat-8.5
# 脚本和安装包必须放在相同目录下，安装命令格式：bash /xx/xx.sh
# 安装文件: install.sh、jdk1.8.x.tar.gz、mysql-5.6.x.tar.gz、apache-tomcat-8.5.x.tar.gz、libaio.so.1
# jdk1.8.x下载: https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html
# mysql-5.6.x.tar.gz下载:http://mirrors.163.com/mysql/Downloads/MySQL-5.6/mysql-5.6.50-linux-glibc2.12-x86_64.tar.gz
# apache-tomcat-8.5.x.tar.gz下载: https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.12/bin/apache-tomcat-8.5.12.tar.gz
# 因 ubuntu 系统默认未安装 libaio1 软件包, mysql 依赖 libaio.so.1 否则无法安装。单独提取此文件和脚本放在一起安装
# 1、仅支持单次运行,重复运行此脚本会删除之前的安装目录数据,并重新安装
# 2、安装完会自动启动 mysql tomcat 服务，并设置开机自启动
# 3、mysql的root默认密码修改为root ; tomcat修改默认端口为8088

#clear
install_dir=/opt
java_home=$install_dir/java
tomcat_home=$install_dir/tomcat
mysql_home=$install_dir/mysql
profile=/etc/profile
install_log=/tmp/install.log

# 获取脚本所在的绝对路径
file_path=$(readlink -f $0)
dir_path=$(dirname $file_path)

blue_echo() {
	echo -e "\033[36m$1\033[0m" | tee -a $install_log
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m" | tee -a $install_log
}
red_echo() {
	echo -e "\033[31m$1\033[0m" | tee -a $install_log
}

# 指定安装包名
java_tgz="$(ls $dir_path/jdk-8*.tar.gz)"
java_tgz_md5="66902b60fb9b45c0af9e90002ac3a711"
#[ "$(md5sum $java_tgz | awk '{print $1}')" != "$java_tgz_md5" ] && red_echo "$(date +"%F %T") exit！ Check if the java.tgz installation package is complete. " && exit 2

tomcat_tgz="$(ls $dir_path/apache-tomcat-8*.tar.gz)"
tomcat_tgz_md5="c2e6eca5a0642d1e30fbe3573b96ab75"
#[ "$(md5sum $tomcat_tgz | awk '{print $1}')" != "$tomcat_tgz_md5" ] && red_echo "$(date +"%F %T") exit！ Check if the tomcat.tgz installation package is complete. " && exit 2

mysql_tgz="$(ls $dir_path/mysql-5*.tar.gz)"
mysql_tgz_md5="dc436a1bd4939a377ed50cf531a55782"
#[ "$(md5sum $mysql_tgz | awk '{print $1}')" != "$mysql_tgz_md5" ] && red_echo "$(date +"%F %T") exit！ Check if the mysql.tgz installation package is complete. " && exit 2

[ $EUID -ne 0 ] && red_echo "$(date +"%F %T") exit！ Please run as root or administrator ." && exit 2

# 创建临时目录
tmp_dir=/tmp/tmp_dir
mkdir -p $tmp_dir

install_java() {
	# 全新安装时,删除之前目录; 
	killall java &> $install_log
	[ -d $java_home ] && rm -r $java_home
	mkdir -p $(dirname $java_home)
	# 解压安装包
	tar -zxf $java_tgz -C $tmp_dir
	mv -f $tmp_dir/$(\ls $tmp_dir | grep jdk) $java_home	
	[ -d "$java_home/bin" ] || { red_echo "$(date +"%F %T") $java_home : No such directory, error exit "; exit 2; }
	
	[ "$(grep -i 'JAVA_HOME=' $profile)" ] || echo -e "\nexport JAVA_HOME=$java_home" >> $profile
	[ "$(grep -i 'PATH=' $profile | grep -i JAVA_HOME/bin)" ] || echo 'export PATH=$JAVA_HOME/bin:$PATH' >> $profile
	source $profile
	java -version && blue_echo "\n$(date +"%F %T") JAVA is already installed\n" || { red_echo "\n$(date +"%F %T") JAVA is not installed. error exit \n"; exit 2; }
}

install_mysql() {
	# 全新安装时,删除之前目录; 
	killall mysqld &> $install_log 
	[ -d $mysql_home ] && rm -r $mysql_home
	mkdir -p $(dirname $mysql_home)
	
	blue_echo "Decompressing Mysql.tar.gz, Please wait 30 seconds"
	# 解压安装包
	tar -zxf $mysql_tgz -C $tmp_dir
	mv -f $tmp_dir/$(\ls $tmp_dir | grep mysql) $mysql_home	
	[ -d "$java_home/bin" ] || { red_echo "$(date +"%F %T") $java_home : No such directory, error exit "; exit 2; }
	# 添加mysql配置
	cat << EOL > /etc/my.cnf
[mysql]
default-character-set = utf8
[mysqld]
lower_case_table_names = 1
user = mysql
port = 3306
bind_address = 0.0.0.0
socket = /tmp/mysql.sock
pid-file = $mysql_home/mysql.pid
basedir = $mysql_home
datadir = $mysql_home/data
max_connections = 200
character-set-server = utf8
default-storage-engine = INNODB
skip-name-resolve
default-time-zone = '+08:00'
max_allowed_packet = 64M
explicit_defaults_for_timestamp = true
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES

EOL
	chmod 664 /etc/my.cnf
	mkdir -p $mysql_home/data
	
	# 添加mysql用户
	[ "$(id mysql 2> /dev/null)" ] || useradd -M -s /bin/false mysql
	chown -R mysql:mysql $mysql_home
	 
	[ "$(grep -i 'MYSQL_HOME=' $profile)" ] || echo -e "\nexport MYSQL_HOME=$mysql_home" >> $profile
	[ "$(grep -i 'PATH=' $profile | grep -i MYSQL_HOME/bin)" ] || echo 'export PATH=$PATH:$MYSQL_HOME/bin:$MYSQL_HOME/lib' >> $profile
	source $profile
	
	blue_echo "Now is initializing Mysql ."
	# 初始化mysql
	# 出错:mysqld: error while loading shared libraries: libaio.so.1: cannot open shared object file: No such file or directory
	# 解决: apt install libaio1 或用以下的命令复制函数库到系统中
	libaio_so=$dir_path/libaio.so.1
	[ -f "$libaio_so" ] || {
		red_echo "$(date +"%F %T") shared libraries: libaio.so.1: No such file or directory; Mysql depends it ; Install Mysql Fail. error exit"
		exit 2
	}
	[ -f /lib/x86_64-linux-gnu/libaio.so.1 ] || cp -f $libaio_so /lib/x86_64-linux-gnu/
	# 进入 mysql 目录, 否则会出现FATAL ERROR: Could not find ./bin/my_print_defaults
	cd $mysql_home
	$mysql_home/scripts/mysql_install_db --defaults-file=/etc/my.cnf --user=mysql &> $install_log
	sleep 2
	# 启动mysql
	cp -f $mysql_home/support-files/mysql.server /etc/init.d/mysql
	systemctl daemon-reload
	systemctl enable mysql &> $install_log
	systemctl restart mysql
	sleep 2
	# 设置root密码
	mysql -uroot -e 'update mysql.user set password=password("root") where user="root" and host="localhost";'
	# 创建新用户
	#mysql -uroot -proot -e ''
	# 刷新数据库
	mysql -uroot -e 'flush privileges;'
	
	# 测试mysql数据库
	mysql -uroot -proot -e 'show variables like "version";' && blue_echo "\n$(date +"%F %T") MYSQL is already installed\n" || { red_echo "\n$(date +"%F %T") MYSQL is not installed. error exit \n"; exit 2; }
}

install_tomcat() {
	# 全新安装时,删除之前目录; 
	[ -d $tomcat_home ] && rm -r $tomcat_home
	mkdir -p $(dirname $tomcat_home)
	# 解压安装包
	tar -zxf $tomcat_tgz -C $tmp_dir
	mv -f $tmp_dir/$(\ls $tmp_dir | grep tomcat) $tomcat_home
	[ -d "$tomcat_home/bin" ] || { red_echo "$(date +"%F %T") $tomcat_home : No such directory, error exit "; exit 2; }
	
	tomcat_server_conf=$tomcat_home/conf/server.xml
	# 修改8080为8088端口
	line_server_port=$(grep -n "Connector port" $tomcat_server_conf | awk -F : '/8080/ {print $1}')
	if [ "$line_server_port" ]; then
		sed -i ''"$line_server_port"'s;8080;8088;' $tomcat_server_conf
		blue_echo "$(date +"%F %T") Modify the tomcat http port 8080 to 8088 Success ."
	else
		red_echo "$(date +"%F %T") Modify the tomcat http port to 8088 Fail ."
		exit 2
	fi 
	
	[ "$(grep -i 'CATALINA_HOME=' $profile)" ] || echo -e "\nexport CATALINA_HOME=$tomcat_home" >> $profile
	#[ "$(grep -i 'CATALINA_BASE=' $profile)" ] || echo "export CATALINA_BASE=$tomcat_home" >> $profile
	#[ "$(grep -i 'PATH=' $profile | grep -i CATALINA_HOME/bin)" ] || echo 'export PATH=$PATH:$CATALINA_HOME/bin' >> $profile
	source $profile
	
	# 配置启动服务
	cp -f $tomcat_home/bin/catalina.sh /etc/init.d/tomcat
	sed -i '3c export JAVA_HOME='"$java_home"'' /etc/init.d/tomcat
	sed -i '4c export CATALINA_HOME='"$tomcat_home"'' /etc/init.d/tomcat
	
	systemctl daemon-reload	
	systemctl enable tomcat &> $install_log
	systemctl restart tomcat
	
	# 测试Tomcat运行是否运行正常
	$tomcat_home/bin/version.sh && blue_echo "\n$(date +"%F %T") Tomcat is already installed\n" || { red_echo "\n$(date +"%F %T") Tomcat is not installed. error exit \n"; exit 2; }
}

# ==================== 开始操作安装流程 ====================
echo -e "\n注意: 安装/重装会删除之前的安装目录数据,请谨慎选择! \n"
read -p "是否需要安装/重装 Java < Yes / No > : " is_java
read -p "是否需要安装/重装 Mysql < Yes / No > : " is_mysql
read -p "是否需要安装/重装 Tomcat < Yes / No > : " is_tomcat
echo

[ "$(echo $is_java | grep -i yes)" ] && install_java
[ "$(echo $is_mysql | grep -i yes)" ] && install_mysql
[ "$(echo $is_tomcat | grep -i yes)" ] && install_tomcat

[ -d "$tmp_dir" ] && rm -rf $tmp_dir