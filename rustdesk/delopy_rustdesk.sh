#!/bin/bash
set -e

# 配置参数（可根据需要修改）
SERVER_IP=$(hostname -I | awk '{print $1}')  # 自动获取本机IP
DATA_DIR="./rustdesk_data"
API_PORT="21114"
RUSTDESK_VERSION="1.2.4"  # 指定稳定版本

# 创建数据目录
mkdir -p ${DATA_DIR}/{hbbs,hbbr,api}

# 输出彩色日志函数
log() {
    echo -e "\033[32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

# 部署核心服务
deploy_core_services() {
    log "启动 RustDesk 核心服务 (hbbs/hbbr)"
    
    # hbbr 服务
    docker run -d --name hbbr \
        --restart unless-stopped \
        --network host \
        -v ${DATA_DIR}/hbbr:/root \
        rustdesk/rustdesk-server:${RUSTDESK_VERSION} \
        hbbr

    # hbbs 服务
    docker run -d --name hbbs \
        --restart unless-stopped \
        --network host \
        -v ${DATA_DIR}/hbbs:/root \
        rustdesk/rustdesk-server:${RUSTDESK_VERSION} \
        hbbs -r ${SERVER_IP}:21117

    # 等待密钥生成
    log "等待密钥生成（最长60秒）"
    timeout 60s bash -c "until docker exec hbbs ls /root/id_ed25519.pub >/dev/null 2>&1; do sleep 1; done"

    if [ $? -ne 0 ]; then
        log "错误：hbbs密钥文件未生成，请检查容器日志"
        exit 1
    fi
}

# 部署API服务
deploy_api_service() {
    local PUB_KEY=$(docker exec hbbs cat /root/id_ed25519.pub | tr -d '\n\r')
    
    log "启动 RustDesk API 服务"
    docker run -d --name rustdesk-api \
        --restart unless-stopped \
        -p ${API_PORT}:21114 \
        -v ${DATA_DIR}/api:/app/data \
        -e TZ=Asia/Shanghai \
        -e RUSTDESK_API_LANG=zh-CN \
        -e RUSTDESK_API_RUSTDESK_ID_SERVER=${SERVER_IP}:21116 \
        -e RUSTDESK_API_RUSTDESK_RELAY_SERVER=${SERVER_IP}:21117 \
        -e RUSTDESK_API_RUSTDESK_API_SERVER=http://${SERVER_IP}:21114 \
        -e RUSTDESK_API_RUSTDESK_KEY="${PUB_KEY}" \
        lejianwen/rustdesk-api

    log "API 服务密钥已自动注入: ${PUB_KEY:0:15}******"
}

# 验证部署
verify_deployment() {
    log "\n部署验证："
    echo -e "------------------------------------------"
    echo -e "服务状态："
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n关键信息："
    echo -e "ID 服务器地址：\t${SERVER_IP}:21116"
    echo -e "中继服务器地址：\t${SERVER_IP}:21117"
    echo -e "API 服务地址：\thttp://${SERVER_IP}:${API_PORT}"
    echo -e "密钥文件位置：\t${DATA_DIR}/hbbs/id_ed25519.pub"
    echo -e "------------------------------------------"
}

# 防火墙配置建议
firewall_tips() {
    log "防火墙配置建议："
    echo "sudo ufw allow 21115:21119/tcp"
    echo "sudo ufw allow 21116/udp"
    echo "sudo ufw allow ${API_PORT}/tcp"
}

main() {
    deploy_core_services
    deploy_api_service
    verify_deployment
    firewall_tips
}

main