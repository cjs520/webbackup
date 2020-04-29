
tmp=1
read -p "请选择你的系统类型, Centos输入 1 ，Ubuntu输入 2  : " tmp
if [ "$tmp" == "1" ];then
  sudo yum update -y
  sudo yum install -y  curl  git yum-utils device-mapper-persistent-data lvm2
  sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  sudo yum makecache fast
  sudo yum -y install docker-ce
  sudo systemctl enable docker
  sudo systemctl start docker

  
elif [ "$tmp" == "2" ];then
  sudo apt remove docker docker-engine docker.io containerd runc
  sudo apt update -y
  sudo apt install -y  curl  git apt-transport-https ca-certificates gnupg-agent software-properties-common
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo systemctl enable docker
  sudo systemctl start docker

fi
echo "docker运行cloudreve主程序"
dir=“/root”
read -p "请输入你的安装目录:(默认root) " dir
mkdir -p $dir/uploads &&touch $dir/conf.ini && touch $dir/cloudreve.db
docker run -itd --name=cloudreve -e PUID=1000   -e PGID=1000 -e TZ="Asia/Shanghai"  -p 5212:5212  --restart=unless-stopped  -v $dir/uploads:/cloudreve/uploads -v $dir/conf.ini:/cloudreve/conf.ini -v $dir/cloudreve.db:/cloudreve/cloudreve.db cjs520/cloudreve-docker
echo "配置caddy反代"
wget https://raw.githubusercontent.com/cjs520/webbackup/master/caddy.sh&&bash caddy.sh
rm -rf caddy.sh
dir1=“/home/aria2”

echo "docker运行aria2"
read -p "请输入你的aria2安装目录:(默认home/aria2) " dir1
mkdir -p $dir1/config &&touch $dir1/downloads
ww=qaz123
read -p "请输入你的aria2的RPC密钥:(默认qaz123) " ww
docker run -d --name aria2 --restart unless-stopped --log-opt max-size=1m -e PUID=1000 -e PGID=1000 -e RPC_SECRET=$ww -p 6800:6800 -p 6888:6888 -p 6888:6888/udp --network my-network -v $dir1/config:/config -v $dir1/downloads:/downloads p3terx/aria2-pro
sleep 3

echo && echo -e " aria2 RPC密钥: $ww
aria2下载目录：$dir1/downloads
 cloudreve-docker安装完成！" && echo



