
tmp=1
read -p "请选择你的系统类型, Centos输入 1 ，Ubuntu输入 2  : " tmp
if [ "$tmp" == "1" ];then
  
elif [ "$tmp" == "2" ];then
  
fi
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

