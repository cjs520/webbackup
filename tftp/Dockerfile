# 使用 Alpine 作为基础镜像
FROM alpine

# 安装 tftp-hpa 包
RUN apk add --no-cache tftp-hpa

# 创建 TFTP 目录
RUN mkdir -p /tftpboot

# 下载 netboot.xyz.efi 文件并将其重命名为 amd.efi
RUN wget -O /tftpboot/amd.efi https://boot.netboot.xyz/ipxe/netboot.xyz.efi
RUN wget -O /tftpboot/arm.efi https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi

# 设置 TFTP 目录权限
RUN chmod -R 777 /tftpboot

# 暴露 TFTP 端口
EXPOSE 69/udp

# 启动 TFTP 服务
CMD ["tftpd", "-l", "-s", "/tftpboot"]