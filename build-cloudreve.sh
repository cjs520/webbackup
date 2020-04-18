
tmp=1
read -p "请选择你的系统类型, Centos输入 1 ，Ubuntu输入 2  : " tmp
if [ "$tmp" == "1" ];then
  sudo yum install -y go curl nodejs git
  npm install -g n
  n latest
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  sudo yum install -y yarn
elif [ "$tmp" == "2" ];then
  sudo apt install -y go curl nodejs git
  npm install -g n
  n latest
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  sudo yum install -y yarn
fi
git clone --recurse-submodules https://github.com/cloudreve/Cloudreve.git
cd Cloudreve
echo "构建静态资源"
cd assets/
yarn install
yarn upgrade
yarn run build
cd ..
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
go get github.com/rakyll/statik
~/go/bin/statik -src=assets/build/  -include=*.html,*.js,*.json,*.css,*.png,*.svg,*.ico -f
export COMMIT_SHA=$(git rev-parse --short HEAD)
export VERSION=$(git describe --tags)
go build

sleep 5

mv cloudreve ../
mv assets/build ../statics 
cd ..&&rm -rf Cloudreve

./cloudreve >>passwd.txt &

sleep 3

pid=`ps -ef | grep cloudreve | grep -v grep | awk '{print $2}'`;kill $pid
cat passwd.txt
tmp=1
read -p "请选择你的系统类型, Centos输入 1 ，Ubuntu输入 2  : " tmp
if [ "$tmp" == "1" ];then
  cloudpath=$(cd `dirname $0`; pwd)
cat >/usr/lib/systemd/system/cloudreve.service <<EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
Wants=network.target
[Service]
WorkingDirectory=$cloudpath
ExecStart=$cloudpath/cloudreve
Restart=on-abnormal
RestartSec=5s
KillMode=mixed
StandardOutput=null
StandardError=syslog
[Install]
WantedBy=multi-user.target
EOF

# 更新配置
systemctl daemon-reload
# 启动服务
systemctl start cloudreve
# 设置开机启动
systemctl enable cloudreve
elif [ "$tmp" == "2" ];then
  cloudpath=$(cd `dirname $0`; pwd)
cat >/lib/systemd/system/cloudreve.service <<EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
Wants=network.target
[Service]
WorkingDirectory=$cloudpath
ExecStart=$cloudpath/cloudreve
Restart=on-abnormal
RestartSec=5s
KillMode=mixed
StandardOutput=null
StandardError=syslog
[Install]
WantedBy=multi-user.target
EOF

# 更新配置
systemctl daemon-reload
# 启动服务
systemctl start cloudreve
# 设置开机启动
systemctl enable cloudreve
fi


echo && echo -e " Cloudreve V3 安装成功 
-- Jay | blog: https://www.dsza.xyz
修改statics里的index.html即可添加备案号,修改static里可修改样式
# 启动服务
systemctl start cloudreve
# 停止服务
systemctl stop cloudreve
 "&& echo



