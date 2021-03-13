
tmp=1
read -p "请选择你的系统类型, Centos输入 1 ，Ubuntu输入 2  : " tmp
if [ "$tmp" == "1" ];then
  sudo yum update
  sudo yum install -y curl
elif [ "$tmp" == "2" ];then
  
  sudo apt update
  sudo apt install -y curl
 
fi

ulimit -n 8192
wget https://github.com/caddyserver/caddy/releases/download/v2.3.0/caddy_2.3.0_linux_amd64.tar.gz
tar -vxf caddy_2.3.0_linux_amd64.tar.gz 
mv ./caddy /usr/local/bin/
name="www.baidu.com"
read -p "请输入你的域名:(示例：www.baidu.com)  : " name
email="admin@cloudreve.org"
read -p "请输入你的邮箱:(示例：admin@cloudreve.org)  : " email
address="http://127.0.0.1:5212"
read -p "请输入你反代的地址:(示例：http://127.0.0.1:5212)  : " address
echo "$name {

reverse_proxy / $address
}" > /usr/local/bin/Caddyfile



if ! wget --no-check-certificate https://raw.githubusercontent.com/cjs520/webbackup/master/manager/caddy -O /etc/init.d/caddy; then
			echo -e " Caddy服务 管理脚本下载失败 ! 下载备用脚本" && wget --no-check-certificate https://gitee.com/jayson0201/webbackup/raw/master/manager/caddy -O /etc/init.d/caddy
fi
chmod +x /etc/init.d/caddy
chkconfig --add caddy
chkconfig caddy on



echo && echo -e " Caddy 使用命令：${caddy_conf_file}
 日志文件：cat /tmp/caddy.log
 使用说明：service caddy start | stop | restart | status
 或者使用：/etc/init.d/caddy start | stop | restart | status
  Caddy 安装完成！" && echo
