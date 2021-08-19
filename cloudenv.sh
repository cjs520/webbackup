tmp=1
read -p "请选择你的系统类型, Centos输入 1 ，Ubuntu输入 2  : " tmp
if [ "$tmp" == "1" ];then
  sudo yum install -y  curl 
  sleep 5
  echo "安装node，npm，yarn"
  curl -sL https://deb.nodesource.com/setup_13.x | sudo bash -
  yum install -t nodejs
  npm install -g n
  n latest
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  sudo yum install -y yarn
elif [ "$tmp" == "2" ];then
  sudo apt install -y  curl
  sleep 5
  echo "安装node，npm，yarn"
  curl -sL https://deb.nodesource.com/setup_13.x | sudo bash -
  sudo apt-get install -y nodejs
  npm install -g n
  n latest
 rm -rf /usr/bin/node
ln -s /usr/local/bin/node /usr/bin/node
 curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
 echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt install -y yarn
fi

sleep 10

echo "安装go"
wget https://studygolang.com/dl/golang/go1.15.10.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.15.10.linux-amd64.tar.gz
echo "
export GOROOT=/usr/local/go
export GOPATH=/root/go
export PATH=$PATH:/usr/local/go/bin
">>~/.bashrc

sleep 10

source  ~/.bashrc


sleep 5
echo "安装docker"
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
sleep 5
service docker start
sleep 5
echo "安装docker-compose"
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
sleep 5
docker pull karalabe/xgo-latest
sleep 10
go get github.com/karalabe/xgo