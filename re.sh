cd assets/
rm -rf node_modules
rm -rf build
ls
echo " rm node_moudules"
yarn install
yarn run build
# 构建完成后删除映射文件
cd build
find . -name "*.map" -type f -delete
# 返回项目主目录打包静态资源
cd ../../
zip -r - assets/build >assets.zip
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
export COMMIT_SHA=$(git rev-parse --short HEAD)
export VERSION=$(git describe --tags)
go build

