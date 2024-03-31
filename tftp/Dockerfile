# 使用 BuildKit 的多架构构建功能
# syntax=docker/dockerfile:1.2

# 为 x86_64 架构指定基础镜像
FROM --platform=linux/amd64 alpine:latest AS amd64

# 为 arm64 架构指定基础镜像
FROM --platform=linux/arm64 alpine:latest AS arm64

# 为 arm32 架构指定基础镜像
FROM --platform=linux/arm/v7 alpine:latest AS arm32

# 为所有架构执行相同的操作
# 注意：这里只是一个示例，具体的操作可能需要根据实际需求进行调整

# 安装 TFTP 服务器和相关工具
RUN apk add --no-cache tftp-hpa

# 创建 TFTP 目录并设置权限
RUN mkdir -p /srv/tftp && \
    chmod -R 755 /srv/tftp && \
    addgroup -S tftpd && \
    adduser -s /bin/false -S -D -H -h /data -G tftpd tftpd

# 下载 netboot.xyz.efi 文件并将其重命名
# 注意：这里需要根据不同的架构下载对应的 EFI 文件
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
