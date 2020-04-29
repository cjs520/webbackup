

yum install -y curl
curl https://getcaddy.com | bash -s personal
name=https://www.baidu.com
read -p "请输入你的域名:(默认：https://www.baidu.com)  : " name
email=admin@cloudreve.org
read -p "请输入你的邮箱:(默认：admin@cloudreve.org)  : " email
address=admin@cloudreve.org
read -p "请输入你反代的地址:(默认：http://127.0.0.1:5212)  : " address
echo "$name {
gzip
tls $email
proxy / $address
}" > /usr/local/bin/Caddyfile

ulimit -n 8192


echo "caddy 启动完毕"
