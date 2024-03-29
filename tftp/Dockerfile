# 使用 Alpine 作为基础镜像
FROM alpine:latest

#  设置镜像源为阿里云的 Alpine 镜像源
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装 TFTP 服务器和相关工具
RUN apk add --no-cache tftp-hpa

# 创建 TFTP 目录并设置权限
RUN mkdir -p /srv/tftp && \
    chmod -R 755 /srv/tftp && \
    addgroup -S tftpd && \
    adduser -s /bin/false -S -D -H -h /data -G tftpd tftpd

# 下载 netboot.xyz.efi 文件并将其重命名为 amd.efi
RUN wget -O /srv/tftp/amd.efi https://boot.netboot.xyz/ipxe/netboot.xyz.efi && \
    wget -O /srv/tftp/arm.efi https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi && \
    chmod 644 /srv/tftp/amd.efi && \
    chmod 644 /srv/tftp/arm.efi

# 暴露 TFTP 端口
EXPOSE 69/udp

# 设置 VOLUME
VOLUME ["/srv/tftp"]

# 启动 TFTP 服务
CMD ["in.tftpd" ,"-L","-v","-s","-u","tftpd","/srv/tftp"]