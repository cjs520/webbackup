#!/bin/bash
export LANG=en_US.UTF-8
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
bblue='\033[0;34m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit
#[[ -e /etc/hosts ]] && grep -qE '^ *172.65.251.78 gitlab.com' /etc/hosts || echo -e '\n172.65.251.78 gitlab.com' >> /etc/hosts
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else
red "脚本不支持当前的系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
red "脚本不支持当前的 $op 系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
latcore=v`curl -Ls https://data.jsdelivr.com/v1/package/gh/klzgrad/naiveproxy | sed -n 4p | tr -d ',"' | awk '{print $1}'`
inscore=`cat /etc/caddy/version 2>/dev/null | head -n 1`
insV=$(cat /etc/caddy/v 2>/dev/null)
latestV=$(curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "更新内容" 'NR>2 {print $1; exit}')
version=$(uname -r | cut -d "-" -f1)
vi=$(systemd-detect-virt 2>/dev/null)
bit=$(uname -m)
if [[ $bit = x86_64 ]]; then
cpu=amd64
elif [[ $bit = aarch64 ]]; then
cpu=arm64
else
red "目前脚本不支持 $bit 架构" && exit
fi
if [[ -n $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk -F ' ' '{print $3}') ]]; then
bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`
elif [[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]]; then
bbr="Openvz版bbr-plus"
else
bbr="Openvz/Lxc"
fi
if [ ! -f nayg_update ]; then
green "首次安装Naiveproxy-yg脚本必要的依赖……"
if [[ -z $vi ]]; then
apt update iproute2 systemctl -y
fi
update(){
if [ -x "$(command -v apt-get)" ]; then
apt update -y
elif [ -x "$(command -v yum)" ]; then
yum update -y && yum install epel-release -y
elif [ -x "$(command -v dnf)" ]; then
dnf update -y
fi
}
if [[ $release = Centos && ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
cd
fi
update
packages=("curl" "openssl" "jq" "tar" "qrencode" "wget" "cron")
inspackages=("curl" "openssl" "jq" "tar" "qrencode" "wget" "cron")
for i in "${!packages[@]}"; do
package="${packages[$i]}"
inspackage="${inspackages[$i]}"
if ! command -v "$package" &> /dev/null; then
if [ -x "$(command -v apt-get)" ]; then
apt-get install -y "$inspackage"
elif [ -x "$(command -v yum)" ]; then
yum install -y "$inspackage"
elif [ -x "$(command -v dnf)" ]; then
dnf install -y "$inspackage"
fi
fi
done
if [ -x "$(command -v yum)" ] || [ -x "$(command -v dnf)" ]; then
if [ -x "$(command -v yum)" ]; then
yum install -y cronie
elif [ -x "$(command -v dnf)" ]; then
dnf install -y cronie
fi
fi
update
touch nayg_update
fi
if [[ $vi = openvz ]]; then
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then
red "检测到未开启TUN，现尝试添加TUN支持" && sleep 4
cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then
green "添加TUN支持失败，建议与VPS厂商沟通或后台设置开启" && exit
else
echo '#!/bin/bash' > /root/tun.sh && echo 'cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun' >> /root/tun.sh && chmod +x /root/tun.sh
grep -qE "^ *@reboot root bash /root/tun.sh >/dev/null 2>&1" /etc/crontab || echo "@reboot root bash /root/tun.sh >/dev/null 2>&1" >> /etc/crontab
green "TUN守护功能已启动"
fi
fi
fi
v4v6(){
v4=$(curl -s4m5 icanhazip.com -k)
v6=$(curl -s6m5 icanhazip.com -k)
}
warpcheck(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}
v6(){
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4=$(curl -s4m5 icanhazip.com -k)
if [ -z $v4 ]; then
yellow "检测到 纯IPV6 VPS，添加DNS64"
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
fi
fi
}
close(){
systemctl stop firewalld.service >/dev/null 2>&1
systemctl disable firewalld.service >/dev/null 2>&1
setenforce 0 >/dev/null 2>&1
ufw disable >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -t mangle -F >/dev/null 2>&1
iptables -F >/dev/null 2>&1
iptables -X >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
if [[ -n $(apachectl -v 2>/dev/null) ]]; then
systemctl stop httpd.service >/dev/null 2>&1
systemctl disable httpd.service >/dev/null 2>&1
service apache2 stop >/dev/null 2>&1
systemctl disable apache2 >/dev/null 2>&1
fi
sleep 1
blue "执行开放端口，关闭防火墙完毕"
echo "----------------------------------------------------"
}
openyn(){
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
readp "是否开放端口，关闭防火墙？\n1、是，执行 (回车默认)\n2、否，我自已手动\n请选择：" action
if [[ -z $action ]] || [[ "$action" = "1" ]]; then
close
elif [[ "$action" = "2" ]]; then
echo
else
red "输入错误,请重新选择" && openyn
fi
}
forwardproxy(){
go env -w GO111MODULE=on
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
}
rest(){
if [[ ! -f /root/caddy ]]; then
red "caddy2-naiveproxy构建失败，脚本退出" && exit
fi
chmod +x caddy
mv caddy /usr/bin/
}
inscaddynaive(){
echo
naygvsion=`curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | head -n 1`
yellow "一、请选择安装或者更新 naiveproxy 内核方式:"
readp "1. 已编译的caddy2-naiveproxy版本：$naygvsion (安装快速，强烈推荐，回车默认）\n2. 在线编译caddy2-naiveproxy版本：$latcore (安装缓慢，存在编译失败可能)\n请选择：" chcaddynaive
if [ -z "$chcaddynaive" ] || [ $chcaddynaive == "1" ]; then
cd /root
wget -qN https://gitlab.com/rwkgyg/naiveproxy-yg/raw/main/caddy2-naive-linux-${cpu}.tar.gz
wget -qN https://gitlab.com/rwkgyg/naiveproxy-yg/raw/main/version
tar zxvf caddy2-naive-linux-${cpu}.tar.gz
rm caddy2-naive-linux-${cpu}.tar.gz -f
cd
rest
elif [ $chcaddynaive == "2" ]; then
if [[ $release = Centos ]] && [[ ${vsid} =~ 8 ]]; then
green "Centos 8 系统建议使用编译好的caddy2-naiveproxy版本" && inscaddynaive
fi
cd /root
if [[ $release = Centos ]]; then
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install golang && forwardproxy
elif [[ $release = Debian ]]; then
apt install software-properties-common -y
apt update
$GOLANG_VERSION = `curl -Ls https://golang.google.cn/dl/ | grep -oE "go[0-9.]+.linux-$cpu.tar.gz" | head -n 1 | cut  -c3-8`
wget -c https://golang.google.cn/dl/go$GOLANG_VERSION.linux-$cpu.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-$cpu.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
source /etc/profile
forwardproxy
else
apt install software-properties-common -y
add-apt-repository ppa:longsleep/golang-backports
apt update
apt install golang-go && forwardproxy
fi
cd
rest
lastvsion=v`curl -Ls https://data.jsdelivr.com/v1/package/gh/klzgrad/naiveproxy | sed -n 4p | tr -d ',"' | awk '{print $1}'`
echo $lastvsion > /root/version
else
red "输入错误，请重新选择" && inscaddynaive
fi
version(){
if [[ ! -d /etc/caddy/ ]]; then
mkdir /etc/caddy >/dev/null 2>&1
fi
mv version /etc/caddy/
}
version
echo "----------------------------------------------------"
}
inscertificate(){
echo
yellow "二、Naiveproxy协议证书申请方式选择如下:"
readp "1. acme一键申请证书脚本（支持常规80端口模式与dns api模式），已用此脚本申请的证书则自动识别（回车默认）\n2. 自定义证书路径（非/root/ygkkkca路径）\n请选择：" certificate
if [ -z "${certificate}" ] || [ $certificate == "1" ]; then
if [[ -f /root/ygkkkca/cert.crt && -f /root/ygkkkca/private.key ]] && [[ -s /root/ygkkkca/cert.crt && -s /root/ygkkkca/private.key ]] && [[ -f /root/ygkkkca/ca.log ]]; then
blue "经检测，之前已使用此acme脚本申请过证书"
readp "1. 直接使用原来的证书（回车默认）\n2. 删除原来的证书，重新申请证书\n请选择：" certacme
if [ -z "${certacme}" ] || [ $certacme == "1" ]; then
ym=$(cat /root/ygkkkca/ca.log)
blue "检测到的域名：$ym ，已直接引用"
elif [ $certacme == "2" ]; then
curl https://get.acme.sh | sh
bash /root/.acme.sh/acme.sh --uninstall
rm -rf /root/ygkkkca
rm -rf ~/.acme.sh acme.sh
sed -i '/--cron/d' /etc/crontab
[[ -z $(/root/.acme.sh/acme.sh -v 2>/dev/null) ]] && green "acme.sh卸载完毕" || red "acme.sh卸载失败"
sleep 2
bash <(curl -Ls https://gitlab.com/rwkgyg/acme-script/raw/main/acme.sh)
ym=$(cat /root/ygkkkca/ca.log)
if [[ ! -f /root/ygkkkca/cert.crt && ! -f /root/ygkkkca/private.key ]] && [[ ! -s /root/ygkkkca/cert.crt && ! -s /root/ygkkkca/private.key ]]; then
red "证书申请失败，脚本退出" && exit
fi
fi
else
bash <(curl -Ls https://gitlab.com/rwkgyg/acme-script/raw/main/acme.sh)
ym=$(cat /root/ygkkkca/ca.log)
if [[ ! -f /root/ygkkkca/cert.crt && ! -f /root/ygkkkca/private.key ]] && [[ ! -s /root/ygkkkca/cert.crt && ! -s /root/ygkkkca/private.key ]]; then
red "证书申请失败，脚本退出" && exit
fi
fi
certificatec='/root/ygkkkca/cert.crt'
certificatep='/root/ygkkkca/private.key'
elif [ $certificate == "2" ]; then
readp "请输入已放置好的公钥文件crt的路径（/a/b/……/cert.crt）：" cerroad
blue "公钥文件crt的路径：$cerroad "
readp "请输入已放置好的密钥文件key的路径（/a/b/……/private.key）：" keyroad
blue "密钥文件key的路径：$keyroad "
certificatec=$cerroad
certificatep=$keyroad
readp "请输入已解析好的域名:" ym
blue "已解析好的域名：$ym "
else
red "输入错误，请重新选择" && inscertificate
fi
echo "----------------------------------------------------"
}
insport(){
echo
readp "三、设置Naiveproxy端口[1-65535]（回车跳过为2000-65535之间的随机端口）：" port
if [[ -z $port ]]; then
port=$(shuf -i 2000-65535 -n 1)
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义端口:" port
done
else
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义端口:" port
done
fi
blue "已确认端口：$port"
echo "----------------------------------------------------"
}
insuser(){
echo
readp "四、设置用户名，必须为3位字符以上（回车跳过为随机3位字符）：" user
if [[ -z ${user} ]]; then
user=`date +%s%N |md5sum | cut -c 1-3`
else
if [[ 3 -ge ${#user} ]]; then
until [[ 3 -le ${#user} ]]
do
[[ 3 -ge ${#user} ]] && yellow "\n用户名必须为3位字符以上！请重新输入" && readp "\n设置用户名：" user
done
fi
fi
blue "已确认用户名：${user}"
echo "----------------------------------------------------"
}
inspswd(){
echo
readp "五、设置密码，必须为5位字符以上（回车跳过为随机5位字符）：" pswd
if [[ -z ${pswd} ]]; then
pswd=`date +%s%N |md5sum | cut -c 1-5`
else
if [[ 5 -ge ${#pswd} ]]; then
until [[ 5 -le ${#pswd} ]]
do
[[ 5 -ge ${#pswd} ]] && yellow "\n用户名必须为5位字符以上！请重新输入" && readp "\n设置密码：" pswd
done
fi
fi
blue "已确认密码：${pswd}"
echo "----------------------------------------------------"
}
insweb(){
echo
readp "六、设置伪装网址，注意：不要带http(s)://（回车跳过，默认为 甬哥博客地址：ygkkk.blogspot.com ）：" web
if [[ -z ${web} ]]; then
naweb=ygkkk.blogspot.com
else
naweb=$web
fi
blue "已确认伪装网址：${naweb}"
echo "----------------------------------------------------"
}
insconfig(){
echo
readp "七、设置caddy2-naiveproxy监听端口[1-65535]（回车跳过为2000-65535之间的随机端口）：" caddyport
if [[ -z $caddyport ]]; then
caddyport=$(shuf -i 2000-65535 -n 1)
if [[ $caddyport == $port ]]; then
yellow "\n端口被占用，请重新输入端口" && readp "自定义caddy2-naiveproxy监听端口:" caddyport
fi
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]]
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义端口:" caddyport
done
else
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]]
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义端口:" caddyport
done
fi
blue "已确认端口：$caddyport\n"
green "设置naiveproxy的配置文件、服务进程……\n"
mkdir /root/naive >/dev/null 2>&1
mkdir /etc/caddy >/dev/null 2>&1
cat << EOF >/etc/caddy/Caddyfile
{
http_port $caddyport
}
:$port, $ym:$port {
tls ${certificatec} ${certificatep}
route {
 forward_proxy {
   basic_auth ${user} ${pswd}
   hide_ip
   hide_via
   probe_resistance
  }
 reverse_proxy  https://$naweb {
   header_up  Host  {upstream_hostport}
   header_up  X-Forwarded-Host  {host}
  }
}
}
EOF
cat <<EOF > /root/naive/v2rayn.json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://${user}:${pswd}@${ym}:$port"
}
EOF
cat << EOF >/etc/systemd/system/caddy.service
[Unit]
Description=YGKKK-Caddy2-naiveproxy
Documentation=https://gitlab.com/rwkgyg/naiveproxy-yg
After=network.target network-online.target
Requires=network-online.target
[Service]
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
PrivateTmp=false
NoNewPrivileges=yes
ProtectHome=false
ProtectSystem=false
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable caddy >/dev/null 2>&1
systemctl start caddy
}
stclre(){
if [[ ! -f '/etc/caddy/Caddyfile' ]]; then
green "未正常安装naiveproxy" && exit
fi
green "naiveproxy服务执行以下操作"
readp "1. 重启\n2. 关闭\n0. 返回上层\n请选择：" action
if [[ $action == "1" ]]; then
systemctl enable caddy
systemctl start caddy
systemctl restart caddy
green "naiveproxy服务重启\n"
elif [[ $action == "2" ]]; then
systemctl stop caddy
systemctl disable caddy
green "naiveproxy服务关闭\n"
else
na
fi
}
changeserv(){
if [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && ! -f '/etc/caddy/Caddyfile' ]]; then
red "未正常安装naiveproxy" && exit
fi
green "naiveproxy配置变更选择如下:"
readp "1. 添加或删除多端口复用(每执行一次添加一个端口)\n2. 变更主端口\n3. 变更用户名\n4. 变更密码\n5. 重新申请证书或变更证书路径\n6. 变更伪装网页\n0. 返回上层\n请选择：" choose
if [ $choose == "1" ];then
duoport
elif [ $choose == "2" ];then
changeport
elif [ $choose == "3" ];then
changeuser
elif [ $choose == "4" ];then
changepswd
elif [ $choose == "5" ];then
inscertificate
oldcer=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 5p | awk '{print $2}'`
oldkey=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 5p | awk '{print $3}'`
sed -i "s#$oldcer#${certificatec}#g" /etc/caddy/Caddyfile
sed -i "s#$oldkey#${certificatep}#g" /etc/caddy/Caddyfile
sed -i "s#$oldcer#${certificatec}#g" /etc/caddy/reCaddyfile
sed -i "s#$oldkey#${certificatep}#g" /etc/caddy/reCaddyfile
oldym=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 4p | awk '{print $2}'| awk -F":" '{print $1}'`
sed -i "s/$oldym/${ym}/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile /root/naive/URL.txt /root/naive/v2rayn.json
sussnaiveproxy
elif [ $choose == "6" ];then
changeweb
else
na
fi
}
duoport(){
naiveports=`cat /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}' | grep : | tr -d ',:'`
green "\n当前naiveproxy代理正在使用的端口："
blue "$naiveports"
readp "\n1. 添加多端口复用\n2. 恢复仅一个主端口\n0. 返回上层\n请选择：" choose
if [ $choose == "1" ]; then
oldport1=`cat /etc/caddy/reCaddyfile 2>/dev/null | sed -n 4p | awk '{print $1}'| tr -d ',:'`
insport
sed -i "s/$oldport1/$port/g" /etc/caddy/reCaddyfile
cat /etc/caddy/reCaddyfile 2>/dev/null | tail -15 >> /etc/caddy/Caddyfile
sussnaiveproxy
elif [ $choose == "2" ]; then
sed -i '19,$d' /etc/caddy/Caddyfile 2>/dev/null
sussnaiveproxy
else
changeserv
fi
}
changeuser(){
olduserc=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 8p | awk '{print $2}'`
echo
blue "当前正在使用的用户名：$olduserc"
echo
insuser
sed -i "s/$olduserc/${user}/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile /root/naive/URL.txt /root/naive/v2rayn.json
sussnaiveproxy
}
changepswd(){
oldpswdc=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 8p | awk '{print $3}'`
echo
blue "当前正在使用的密码：$oldpswdc"
echo
inspswd
sed -i "s/$oldpswdc/${pswd}/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile /root/naive/URL.txt /root/naive/v2rayn.json
sussnaiveproxy
}
changeport(){
oldport1=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 4p | awk '{print $1}'| tr -d ',:'`
echo
blue "当前正在使用的主端口：$oldport1"
echo
insport
sed -i "s/$oldport1/$port/g" /etc/caddy/Caddyfile /root/naive/v2rayn.json /root/naive/URL.txt
sussnaiveproxy
}
changeweb(){
oldweb=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 13p | awk '{print $2}'`
echo
blue "当前正在使用的伪装网址：$oldweb"
echo
insweb
sed -i "s/$oldweb/$naweb/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile
sussnaiveproxy
}
acme(){
bash <(curl -L -s https://gitlab.com/rwkgyg/acme-script/raw/main/acme.sh)
}
cfwarp(){
bash <(curl -Ls https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh)
}
bbr(){
bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
}
lnna(){
curl -sL -o /usr/bin/na https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/naiveproxy.sh
chmod +x /usr/bin/na
}
upnayg(){
if [[ ! -f '/etc/caddy/Caddyfile' ]]; then
red "未正常安装Naiveproxy-yg" && exit
fi
lnna
curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "更新内容" 'NR>2 {print $1; exit}' > /etc/caddy/v
green "Naiveproxy-yg安装脚本升级成功" && sleep 5 && na
}
upnaive(){
if [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && ! -f '/etc/caddy/Caddyfile' ]]; then
red "未正常安装naiveproxy" && exit
fi
green "\n升级naiveproxy内核版本\n"
inscaddynaive
systemctl restart caddy
green "naiveproxy内核版本升级成功" && na
}
unins(){
systemctl stop caddy >/dev/null 2>&1
systemctl disable caddy >/dev/null 2>&1
rm -f /etc/systemd/system/caddy.service
rm -rf /usr/bin/caddy /etc/caddy /root/naive /usr/bin/na /root/nayg_update
green "naiveproxy卸载完成！"
}
sussnaiveproxy(){
systemctl restart caddy
if [[ -n $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
green "naiveproxy服务启动成功" && naiveproxyshare
else
red "naiveproxy服务启动失败，请运行systemctl status caddy查看服务状态并反馈，脚本退出" && exit
fi
}
naiveproxyshare(){
if [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && ! -f '/etc/caddy/Caddyfile' ]]; then
red "未正常安装naiveproxy" && exit
fi
red "======================================================================================"
naiveports=`cat /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}' | grep : | tr -d ',:'`
green "\n当前naiveproxy代理正在使用的端口：" && sleep 2
blue "$naiveports\n"
green "当前v2rayn客户端配置文件v2rayn.json内容如下，保存到 /root/naive/v2rayn.json\n"
yellow "$(cat /root/naive/v2rayn.json)\n" && sleep 2
green "当前naiveproxy节点分享链接如下，保存到 /root/naive/URL.txt"
yellow "$(cat /root/naive/URL.txt)\n" && sleep 2
green "当前naiveproxy节点二维码分享链接如下(Nekobox)"
qrencode -o - -t ANSIUTF8 "$(cat /root/naive/URL.txt)"
}
insna(){
if [[ -f '/etc/caddy/Caddyfile' ]]; then
green "已安装naiveproxy，重装请先执行卸载功能" && exit
fi
rm -f /etc/systemd/system/caddy.service
rm -rf /usr/bin/caddy /etc/caddy /root/naive /usr/bin/na
v6 ; openyn ; inscaddynaive ; inscertificate ; insport ; insuser ; inspswd ; insweb ; insconfig
if [[ -n $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
green "naiveproxy服务启动成功"
lnna
curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "更新内容" 'NR>2 {print $1; exit}' > /etc/caddy/v
cp -f /etc/caddy/Caddyfile /etc/caddy/reCaddyfile >/dev/null 2>&1
if [[ ! $vi =~ lxc|openvz ]]; then
sysctl -w net.core.rmem_max=8000000 >/dev/null 2>&1
sysctl -p >/dev/null 2>&1
fi
else
red "naiveproxy服务启动失败，请运行systemctl status caddy查看服务状态并反馈，脚本退出" && exit
fi
red "======================================================================================"
url="naive+https://${user}:${pswd}@${ym}:$port?padding=true#Naive-$(hostname)"
echo ${url} > /root/naive/URL.txt
green "\nnaiveproxy代理服务安装完成，生成脚本的快捷方式为 na" && sleep 3
green "\nv2rayn客户端配置文件v2rayn.json保存到 /root/naive/v2rayn.json\n"
yellow "$(cat /root/naive/v2rayn.json)\n"
green "分享链接保存到 /root/naive/URL.txt" && sleep 3
yellow "${url}\n"
green "二维码分享链接如下(Nekobox)" && sleep 2
qrencode -o - -t ANSIUTF8 "$(cat /root/naive/URL.txt)"
}
nalog(){
echo
red "退出 Naiveproxy 日志查看，请按 Ctrl+c"
echo
journalctl -u caddy --output cat -f
}
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
white "甬哥Github项目  ：github.com/yonggekkk"
white "甬哥Blogger博客 ：ygkkk.blogspot.com"
white "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
green "Naiveproxy-yg脚本安装成功后，再次进入脚本的快捷方式为 na"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green " 1. 安装Naiveproxy"
green " 2. 卸载Naiveproxy"
white "----------------------------------------------------------------------------------"
green " 3. 变更配置（多端口复用、用户名密码、证书、伪装网页）"
green " 4. 关闭、重启Naiveproxy"
green " 5. 更新Naiveproxy-yg安装脚本"
green " 6. 更新Naiveproxy内核版本"
white "----------------------------------------------------------------------------------"
green " 7. 显示Naiveproxy分享链接、V2rayN配置文件、二维码"
green " 8. 查看Naiveproxy运行日志"
green " 9. 管理 Acme 申请域名证书"
green "10. 管理 Warp 查看Netflix、ChatGPT解锁情况"
green "11. 一键原版BBR+FQ加速"
green " 0. 退出脚本"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [ -f /etc/caddy/v ]; then
if [ "$insV" = "$latestV" ]; then
echo -e "当前 Naiveproxy-yg 脚本最新版：${bblue}${insV}${plain} (已安装)"
else
echo -e "当前 Naiveproxy-yg 脚本版本号：${bblue}${insV}${plain}"
echo -e "检测到最新 Naiveproxy-yg 脚本版本号：${yellow}${latestV}${plain} (可选择5进行更新)"
echo -e "${yellow}$(curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "更新内容" 'NR>2 {print $1}')${plain}"
fi
else
echo -e "当前 Naiveproxy-yg 脚本版本号：${bblue}${latestV}${plain}"
echo -e "请先选择 1 ，安装 Naiveproxy-yg 脚本"
fi
if [ -f /etc/caddy/v ]; then
if [ "$inscore" = "$latcore" ]; then
echo -e "当前 Naiveproxy 最新内核版本：${bblue}${inscore}${plain} (已安装)"
else
echo -e "当前 Naiveproxy 已安装内核版本：${bblue}${inscore}${plain}"
echo -e "检测到最新 Naiveproxy 内核版本：${yellow}${latcore}${plain}  (可选择6进行更新)"
fi
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "VPS状态如下："
echo -e "系统:$blue$op$plain  \c";echo -e "内核:$blue$version$plain  \c";echo -e "处理器:$blue$cpu$plain  \c";echo -e "虚拟化:$blue$vi$plain  \c";echo -e "BBR算法:$blue$bbr$plain"
v4v6
if [[ "$v6" == "2a09"* ]]; then
w6="【WARP】"
fi
if [[ "$v4" == "104.28"* ]]; then
w4="【WARP】"
fi
if [[ -z $v4 ]]; then
vps_ipv4='无IPV4'
vps_ipv6="$v6"
elif [[ -n $v4 && -n $v6 ]]; then
vps_ipv4="$v4"
vps_ipv6="$v6"
else
vps_ipv4="$v4"
vps_ipv6='无IPV6'
fi
echo -e "本地IPV4地址：$blue$vps_ipv4$w4$plain   本地IPV6地址：$blue$vps_ipv6$w6$plain"
naiveports=$(cat /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}' | grep : | tr -d ',:' | tr '\n' ' ')
if [[ -n $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
echo -e "Naiveproxy状态：$green运行中$plain     可代理端口：$green$naiveports$plain"
elif [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
echo -e "Naiveproxy状态：$yellow未启动，可选择4重启，依旧如此选择8查看日志并反馈，建议卸载重装Naiveproxy-yg$plain"
else
echo -e "Naiveproxy状态：$red未安装$plain"
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
readp "请输入数字【0-11】:" Input
case "$Input" in
 1 ) insna;;
 2 ) unins;;
 3 ) changeserv;;
 4 ) stclre;;
 5 ) upnayg;;
 6 ) upnaive;;
 7 ) naiveproxyshare;;
 8 ) nalog;;
 9 ) acme;;
10 ) cfwarp;;
11 ) bbr;;
 * ) exit;;
esac
