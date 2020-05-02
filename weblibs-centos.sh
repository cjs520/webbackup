#!/bin/bash
sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
tmp=6
read -p "Please select the centos version , input 6 or 7 or 8 : " tmp
if [ "$tmp" == "6" ];then
  sudo yum install -y wget
  sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
  yum install -y epel-release
  sudo wget http://rpms.remirepo.net/enterprise/remi-release-6.rpm
  rpm -Uvh remi-release-6.rpm
  sudo sed -i '10s/enabled=0/enabled=1/g' /etc/yum.repos.d/remi.repo
elif [ "$tmp" == "7" ];then
  sudo yum install -y wget
  sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
  sudo yum install -y epel-release
  sudo wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
  rpm -Uvh remi-release-7.rpm
  sudo sed -i '10s/enabled=0/enabled=1/g' /etc/yum.repos.d/remi.repo
elif ["$tmp"=="8"];then
  sudo yum install -y wget
  sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
  sudo yum install -y epel-release
  sudo wget http://rpms.remirepo.net/enterprise/remi-release-8.rpm
  rpm -Uvh remi-release-8.rpm
  sudo sed -i '10s/enabled=0/enabled=1/g' /etc/yum.repos.d/remi.repo
fi
yum clean all
yum makecache
yum update -y
mkdir ~/.pip
echo "[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
">> ~/.pip/pip.conf
web=nginx
isphp_jdk=1
####---- version selection ----begin####
tmpl=1
read -p "Please select the web of nginx/apache, input 1 or 2 : " tmpl
if [ "$tmpl" == "1" ];then
  web=nginx
  sudo yum install -y nginx
  tmp2=1
  read -p "Please select the web of php/tomcat, input 1 or 2: " tmp2
  if [ "$tmp2" == "1" ];then
	 isphp_jdk=1
	 tmp21=1
         read -p "Please select the php version of 5.6.40, input 1 : " tmp21
	 if [ "$tmp21" == "1" ];then
	   sudo yum install -y --enablerepo=remi --enablerepo=remi-php56 php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-pecl-xhprof php-fpm php-bcmath
           systemctl start php-fpm.service
           systemctl enable php-fpm.service         
	 fi
   elif [ "$tmp2" == "2" ];then
	 isphp_jdk=2
	 tmp22=1
	 read -p "Please select the jdk version of 1.8.0, input 1: " tmp22
	 if [ "$tmp22" == "1" ];then
	   sudo yum install -y java-1.8.0-openjdk*
           sudo chmod 777 /etc/profile
           echo "#set java environment  

           export JAVA_HOME=/usr/lib/jvm/java
           export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/rt.jar
           export PATH=$PATH:$JAVA_HOME/bin">> /etc/profile
           sudo chmod 644 /etc/profile
           source /etc/profile
	 fi
	 tmp23=1
	 read -p "Please select the tomcat version of 7.0.76, input 1: " tmp23
	 if [ "$tmp13" == "1" ];then
           sudo yum -y install tomcat
           sudo chmod 777 /etc/profile
           echo "CATALINA_BASE=/usr/share/tomcat

CATALINA_HOME=/usr/share/tomcat

export JAVA_HOME PATH CLASSPATH CATALINA_BASE CATALINA_HOME">>/etc/profile
           sudo chmod 644 /etc/profile
           source /etc/profile
           systemctl start tomcat.serviced
	 fi
   fi
  echo "installed nginx"
elif [ "$tmpl" == "2" ];then
  web=apache
  sudo yum install -y httpd
  sudo systemctl start httpd.service
  sudo systemctl enable httpd.service
  sudo yum install -y --enablerepo=remi --enablerepo=remi-php56 php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-pecl-xhprof php-fpm php-bcmath
  sudo systemctl start php-fpm.service
  sudo systemctl enable php-fpm.service
  echo "installed apache"
fi



  

tmsp=1
read -p "Please select the mysql version of 5.7.29, input 1  : " tmsp
if [ "$tmsp" == "1" ];then
  mysql_version=5.7.29
  sudo wget -i -c http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm
  sudo yum -y install mysql57-community-release-el7-10.noarch.rpm
  sudo yum -y install mysql-community-server
  sudo systemctl start  mysqld.service
  sudo yum -y remove mysql57-community-release-el7-10.noarch
fi
sudo yum install -y nodejs
npm install -g n
n latest
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
sudo yum install -y yarn
