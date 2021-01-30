apt install -y git
git clone https://gitee.com/jayson0201/cloudinstall.git
mv cloudinstall/* ./

tar -xvf cloudreve_3.2.1_linux_amd64.tar.gz
rm -rf cloudreve_3.2.1_linux_amd64.tar.gz
rm -rf cloudinstall/
rm -rf cloudinstall/
rm -rf LICENSE README.*

./cloudreve >>passwd.txt &
sleep 3

pid=`ps -ef | grep cloudreve | grep -v grep | awk '{print $2}'`;kill $pid


cat passwd.txt





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

echo "安装完成，请用上面的账号密码登录，如若不行，请放行5212端口"

rm -rf centos_cloudinstall.sh
