# 使用官方的tftp-hpa镜像作为基础镜像
FROM haxorof/tftp-hpa

# 设置镜像维护者信息
LABEL maintainer="yourname@example.com"

# 下载netboot.xyz.efi文件并将其重命名为amd.efi
RUN wget -O /tftpboot/amd.efi https://boot.netboot.xyz/ipxe/netboot.xyz.efi
RUN wget -O /tftpboot/arm.efi https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi

# 暴露TFTP端口
EXPOSE 69/udp

# 启动TFTP服务
CMD ["tftpd", "-l", "-s", "/tftpboot"]