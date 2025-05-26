#!/bin/bash

# RustDesk 服务器一键部署脚本
# 支持启动、停止、重启、查看状态等功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
INSTALL_DIR="$HOME/rustdesk-server"
COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"
DATA_DIR="$INSTALL_DIR/data"
DEFAULT_IMAGE="rustdesk/rustdesk-server:latest"
CHINA_IMAGE="d.svideo.site/rustdesk/rustdesk-server:latest"
SELECTED_IMAGE=""

# 打印彩色信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测并选择镜像源
select_image_source() {
    print_info "检测网络环境并选择镜像源..."
    
    # 尝试检测是否在中国
    local is_china=false
    
    # 方法1: 检测IP地理位置
    if command -v curl &> /dev/null; then
        local country=$(curl -s --connect-timeout 5 ipinfo.io/country 2>/dev/null || echo "")
        if [[ "$country" == "CN" ]]; then
            is_china=true
        fi
    fi
    
    # 方法2: 检测语言环境
    if [[ "$LANG" =~ zh_CN ]] || [[ "$LC_ALL" =~ zh_CN ]]; then
        is_china=true
    fi
    
    # 方法3: 检测时区
    if [[ "$(date +%Z)" == "CST" ]] || [[ "$(timedatectl show --property=Timezone --value 2>/dev/null)" =~ Asia/Shanghai|Asia/Chongqing ]]; then
        is_china=true
    fi
    
    # 根据检测结果选择镜像
    if [[ "$is_china" == true ]]; then
        print_info "检测到您在中国，将使用国内镜像源以提高下载速度"
        SELECTED_IMAGE="$CHINA_IMAGE"
        print_success "已选择镜像源: $CHINA_IMAGE"
    else
        # 询问用户是否要使用中国镜像
        echo ""
        print_info "请选择镜像源："
        echo "1) 官方镜像 (默认): $DEFAULT_IMAGE"
        echo "2) 中国镜像 (推荐中国用户): $CHINA_IMAGE"
        echo ""
        read -p "请选择 (1-2, 默认为1): " choice
        
        case "$choice" in
            "2")
                SELECTED_IMAGE="$CHINA_IMAGE"
                print_success "已选择中国镜像源: $CHINA_IMAGE"
                ;;
            *)
                SELECTED_IMAGE="$DEFAULT_IMAGE"
                print_success "已选择官方镜像源: $DEFAULT_IMAGE"
                ;;
        esac
    fi
}
check_dependencies() {
    print_info "检查系统依赖..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        echo "安装命令："
        echo "curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    print_success "依赖检查通过"
}

# 创建目录结构
create_directories() {
    print_info "创建目录结构..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DATA_DIR"
    print_success "目录创建完成"
}

# 创建 docker-compose.yml 文件
create_compose_file() {
    print_info "创建 Docker Compose 配置文件..."
    
    cat > "$COMPOSE_FILE" << EOF
version: '3.8'

services:
  hbbs:
    container_name: rustdesk-hbbs
    image: ${SELECTED_IMAGE}
    command: hbbs
    volumes:
      - ./data:/root
    network_mode: "host"
    depends_on:
      - hbbr
    restart: unless-stopped
    environment:
      - RUST_LOG=info

  hbbr:
    container_name: rustdesk-hbbr
    image: ${SELECTED_IMAGE}
    command: hbbr
    volumes:
      - ./data:/root
    network_mode: "host"
    restart: unless-stopped
    environment:
      - RUST_LOG=info
EOF
    
    print_success "Docker Compose 配置文件创建完成"
    print_info "使用镜像: $SELECTED_IMAGE"
}

# 启动服务
start_service() {
    print_info "启动 RustDesk 服务器..."
    cd "$INSTALL_DIR"
    
    # 拉取最新镜像
    print_info "拉取最新镜像..."
    docker-compose pull
    
    # 启动服务
    docker-compose up -d
    
    print_success "RustDesk 服务器启动完成"
    
    # 等待服务启动
    sleep 5
    show_status
}

# 停止服务
stop_service() {
    print_info "停止 RustDesk 服务器..."
    cd "$INSTALL_DIR"
    docker-compose down
    print_success "RustDesk 服务器已停止"
}

# 重启服务
restart_service() {
    print_info "重启 RustDesk 服务器..."
    stop_service
    start_service
}

# 查看服务状态
show_status() {
    print_info "查看服务状态..."
    cd "$INSTALL_DIR"
    
    echo ""
    echo "=== 容器状态 ==="
    docker-compose ps
    
    echo ""
    echo "=== 服务端口 ==="
    print_info "RustDesk 使用以下端口："
    echo "  - TCP 21115: hbbs (信号服务器)"
    echo "  - TCP 21116: hbbs (NAT类型测试)"
    echo "  - TCP 21117: hbbr (中继服务器)"
    echo "  - UDP 21116: hbbs (ID注册与心跳服务)"
    
    # 检查密钥文件
    if [ -f "$DATA_DIR/id_ed25519.pub" ]; then
        echo ""
        echo "=== 服务器公钥 ==="
        print_success "公钥文件已生成："
        cat "$DATA_DIR/id_ed25519.pub"
        echo ""
        print_warning "请将此公钥配置到 RustDesk 客户端中"
    fi
}

# 查看日志
show_logs() {
    print_info "查看服务日志..."
    cd "$INSTALL_DIR"
    docker-compose logs -f
}

# 更新服务
update_service() {
    print_info "更新 RustDesk 服务器..."
    cd "$INSTALL_DIR"
    
    # 获取当前使用的镜像
    current_image=$(grep "image:" "$COMPOSE_FILE" | head -1 | awk '{print $2}')
    SELECTED_IMAGE="$current_image"
    
    print_info "当前镜像: $SELECTED_IMAGE"
    print_info "停止服务..."
    docker-compose down
    
    print_info "拉取最新镜像..."
    docker-compose pull
    
    print_info "启动服务..."
    docker-compose up -d
    
    print_success "RustDesk 服务器更新完成"
    show_status
}

# 切换镜像源
switch_mirror() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "服务未安装，请先运行: $0 install"
        exit 1
    fi
    
    print_info "当前配置文件内容："
    current_image=$(grep "image:" "$COMPOSE_FILE" | head -1 | awk '{print $2}')
    echo "当前镜像: $current_image"
    
    echo ""
    print_info "请选择新的镜像源："
    echo "1) 官方镜像: $DEFAULT_IMAGE"
    echo "2) 中国镜像: $CHINA_IMAGE"
    echo ""
    read -p "请选择 (1-2): " choice
    
    case "$choice" in
        "1")
            SELECTED_IMAGE="$DEFAULT_IMAGE"
            ;;
        "2")
            SELECTED_IMAGE="$CHINA_IMAGE"
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac
    
    if [[ "$current_image" == "$SELECTED_IMAGE" ]]; then
        print_info "镜像源未发生变化"
        return
    fi
    
    print_info "切换镜像源到: $SELECTED_IMAGE"
    
    # 停止服务
    print_info "停止当前服务..."
    cd "$INSTALL_DIR"
    docker-compose down
    
    # 更新配置文件
    create_compose_file
    
    # 拉取新镜像
    print_info "拉取新镜像..."
    docker-compose pull
    
    # 启动服务
    print_info "启动服务..."
    docker-compose up -d
    
    print_success "镜像源切换完成！"
    show_status
}

# 卸载服务
uninstall_service() {
    print_warning "这将完全删除 RustDesk 服务器和所有数据"
    read -p "确认要卸载吗？(y/N): " confirm
    
    if [[ $confirm == [yY] ]]; then
        print_info "卸载 RustDesk 服务器..."
        
        if [ -d "$INSTALL_DIR" ]; then
            cd "$INSTALL_DIR"
            docker-compose down 2>/dev/null || true
            
            # 清理所有相关镜像
            docker rmi rustdesk/rustdesk-server:latest 2>/dev/null || true
            docker rmi d.svideo.site/rustdesk/rustdesk-server:latest 2>/dev/null || true
        fi
        
        rm -rf "$INSTALL_DIR"
        print_success "RustDesk 服务器已完全卸载"
    else
        print_info "取消卸载"
    fi
}

# 显示帮助信息
show_help() {
    echo "RustDesk 服务器管理脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  install    安装并启动 RustDesk 服务器"
    echo "  start      启动服务"
    echo "  stop       停止服务" 
    echo "  restart    重启服务"
    echo "  status     查看服务状态"
    echo "  logs       查看服务日志"
    echo "  update     更新服务到最新版本"
    echo "  mirror     切换镜像源"
    echo "  uninstall  卸载服务"
    echo "  help       显示帮助信息"
    echo ""
    echo "镜像源说明："
    echo "  官方镜像: rustdesk/rustdesk-server:latest"
    echo "  中国镜像: d.svideo.site/rustdesk/rustdesk-server:latest (推荐中国用户)"
    echo ""
    echo "首次使用请运行: $0 install"
}

# 安装服务
install_service() {
    print_info "开始安装 RustDesk 服务器..."
    
    check_dependencies
    select_image_source
    create_directories
    create_compose_file
    start_service
    
    echo ""
    print_success "RustDesk 服务器安装完成！"
    echo ""
    print_info "使用说明："
    echo "  启动服务: $0 start"
    echo "  停止服务: $0 stop"
    echo "  查看状态: $0 status"
    echo "  查看日志: $0 logs"
    echo ""
    print_warning "请确保防火墙已开放端口 21115-21117 (TCP) 和 21116 (UDP)"
}

# 主程序
main() {
    case "$1" in
        "install")
            install_service
            ;;
        "start")
            if [ ! -f "$COMPOSE_FILE" ]; then
                print_error "服务未安装，请先运行: $0 install"
                exit 1
            fi
            start_service
            ;;
        "stop")
            if [ ! -f "$COMPOSE_FILE" ]; then
                print_error "服务未安装"
                exit 1
            fi
            stop_service
            ;;
        "restart")
            if [ ! -f "$COMPOSE_FILE" ]; then
                print_error "服务未安装，请先运行: $0 install"
                exit 1
            fi
            restart_service
            ;;
        "status")
            if [ ! -f "$COMPOSE_FILE" ]; then
                print_error "服务未安装"
                exit 1
            fi
            show_status
            ;;
        "logs")
            if [ ! -f "$COMPOSE_FILE" ]; then
                print_error "服务未安装"
                exit 1
            fi
            show_logs
            ;;
        "update")
            if [ ! -f "$COMPOSE_FILE" ]; then
                print_error "服务未安装，请先运行: $0 install"
                exit 1
            fi
            update_service
            ;;
        "mirror")
            switch_mirror
            ;;
        "uninstall")
            uninstall_service
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主程序
main "$@"