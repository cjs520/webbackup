#!/bin/bash

# 创建目录并进入
if [ "$(basename "$PWD")" != "wg-easy" ]; then
    mkdir -p wg-easy && cd wg-easy
    echo "创建并进入 wg-easy 目录"
else
    echo "已在 wg-easy 目录中"
fi

# 安装 bc 命令行计算器（修复缺失依赖）
if ! command -v bc &> /dev/null; then
    echo "安装 bc 命令行计算器..."
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update
        sudo apt-get install -y bc
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y bc
    else
        echo "警告：无法自动安装 bc，数学计算可能出错"
    fi
fi

# 安装 yamllint（用于YAML文件验证）
if ! command -v yamllint &> /dev/null; then
    echo "安装 yamllint..."
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update
        sudo apt-get install -y yamllint
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y epel-release
        sudo yum install -y yamllint
    elif [ -x "$(command -v pip)" ]; then
        pip install yamllint
    elif [ -x "$(command -v pip3)" ]; then
        pip3 install yamllint
    else
        echo "警告：无法自动安装 yamllint，将使用基本YAML验证"
    fi
fi

# 从用户文档中提取的 Docker CE 软件源列表（已过滤）
mirror_list_docker_ce=(
    "mirrors.aliyun.com/docker-ce"
    "mirrors.tencent.com/docker-ce"
    "mirrors.huaweicloud.com/docker-ce"
    "mirrors.cmecloud.cn/docker-ce"
    "mirrors.163.com/docker-ce"
    "mirrors.volces.com/docker"
    "mirror.azure.cn/docker-ce"
    "mirrors.tuna.tsinghua.edu.cn/docker-ce"
    "mirrors.pku.edu.cn/docker-ce"
    "mirrors.zju.edu.cn/docker-ce"
    "mirrors.nju.edu.cn/docker-ce"
    "mirror.sjtu.edu.cn/docker-ce"
    "mirrors.ustc.edu.cn/docker-ce"
    "mirror.iscas.ac.cn/docker-ce"
)

# GitHub Raw 文件镜像源列表（已过滤）
github_raw_mirrors=(
    "https://ghfast.top"
    "https://ghproxy.1888866.xyz"
    "https://github.mspk0.eu.org"
    "http://154.17.231.39:8800"
    "http://45.8.114.2:9001"
    "http://45.78.59.158:7778"
    "http://199.195.251.136:8880"
    "http://8.217.217.133:12345"
    "http://213.189.53.91:3501"
    "https://github.skysr.cn"
    "https://git.xiaok.de"
    "http://8.218.248.173:5000"
    "https://fkgithub.45246326.xyz"
    "https://mirror.888908.xyz"
    "https://ghproxy.net"
    "https://hub.951111.xyz"
)

# 全能代理镜像源（支持4种以上仓库，优先级最高）
universal_mirrors=(
    "ghproxy.1888866.xyz"
    "github.mspk0.eu.org"
    "github.skysr.cn"
    "git.xiaok.de"
    "fkgithub.45246326.xyz"
    "mirror.888908.xyz"
    "hub.951111.xyz"
    "docker.1ms.run"
    "dockerproxy.net"
    "docker.m.daocloud.io"
    "ghcr.nju.edu.cn"
    "ghcr.m.daocloud.io"
    "ghcr.1ms.run"
    "ghcr.chenby.cn"
)

# GitHub 代理镜像源（支持 ghcr.io、docker.pkg.github.com 等）
github_proxy_mirrors=(
    "ghproxy.1888866.xyz"
    "github.mspk0.eu.org"
    "github.skysr.cn"
    "git.xiaok.de"
    "fkgithub.45246326.xyz"
    "mirror.888908.xyz"
    "hub.951111.xyz"
    "docker.1ms.run"
    "dockerproxy.net"
    "docker.m.daocloud.io"
    "ghcr.nju.edu.cn"
    "ghcr.m.daocloud.io"
    "ghcr.1ms.run"
    "ghcr.chenby.cn"
)

# Docker 代理镜像源（支持 docker.io）
docker_proxy_mirrors=(
    "ghproxy.1888866.xyz"
    "github.mspk0.eu.org"
    "github.skysr.cn"
    "git.xiaok.de"
    "fkgithub.45246326.xyz"
    "mirror.888908.xyz"
    "hub.951111.xyz"
    "docker.1ms.run"
    "dockerproxy.net"
    "docker.m.daocloud.io"
    "ghcr.nju.edu.cn"
    "ghcr.m.daocloud.io"
    "ghcr.1ms.run"
    "ghcr.chenby.cn"
)

# GHCR 专用镜像源
ghcr_mirrors=(
    "ghproxy.1888866.xyz"
    "github.mspk0.eu.org"
    "github.skysr.cn"
    "git.xiaok.de"
    "fkgithub.45246326.xyz"
    "mirror.888908.xyz"
    "docker.1ms.run"
    "dockerproxy.net"
    "docker.m.daocloud.io"
    "ghcr.nju.edu.cn"
    "ghcr.m.daocloud.io"
    "ghcr.1ms.run"
    "ghcr.chenby.cn"
)

# Docker Registry 仓库列表（已过滤和分类，按优先级排序）
mirror_list_registry=(
    # 全能代理源（优先级最高，支持4种以上仓库）
    "${universal_mirrors[@]}"
    # GitHub 代理源（支持GitHub相关仓库）
    "${github_proxy_mirrors[@]}"
    # Docker 代理源
    "${docker_proxy_mirrors[@]}"
    # GHCR 专用源
    "${ghcr_mirrors[@]}"
    # 阿里云镜像仓库
    "registry.cn-hangzhou.aliyuncs.com"
    "registry.cn-shanghai.aliyuncs.com"
    "registry.cn-qingdao.aliyuncs.com"
    "registry.cn-beijing.aliyuncs.com"
    "registry.cn-zhangjiakou.aliyuncs.com"
    "registry.cn-huhehaote.aliyuncs.com"
    "registry.cn-wulanchabu.aliyuncs.com"
    "registry.cn-shenzhen.aliyuncs.com"
    "registry.cn-heyuan.aliyuncs.com"
    "registry.cn-guangzhou.aliyuncs.com"
    "registry.cn-chengdu.aliyuncs.com"
    "registry.cn-hongkong.aliyuncs.com"
    "registry.ap-northeast-1.aliyuncs.com"
    "registry.ap-southeast-1.aliyuncs.com"
    "registry.ap-southeast-3.aliyuncs.com"
    "registry.ap-southeast-5.aliyuncs.com"
    "registry.eu-central-1.aliyuncs.com"
    "registry.eu-west-1.aliyuncs.com"
    "registry.us-west-1.aliyuncs.com"
    "registry.us-east-1.aliyuncs.com"
    "registry.me-east-1.aliyuncs.com"
    # 腾讯云镜像仓库
    "mirror.ccs.tencentyun.com"
    # 其他镜像源
    "docker.mirrors.ustc.edu.cn"
    "hub-mirror.c.163.com"
    "mirror.baidubce.com"
)

# 公网/内网地址映射
mirror_list_extranet=(
    "mirrors.aliyun.com/docker-ce"
    "mirrors.tencent.com/docker-ce"
    "mirrors.huaweicloud.com/docker-ce"
    "mirrors.volces.com/docker"
)

mirror_list_intranet=(
    "mirrors.cloud.aliyuncs.com/docker-ce"
    "mirrors.tencentyun.com/docker-ce"
    "mirrors.myhuaweicloud.com/docker-ce"
    "mirrors.ivolces.com/docker"
)

# 改进的中国大陆网络检测
is_china_network() {
    # 方法1: 使用多个IP地理位置服务进行交叉验证
    china_count=0
    total_checks=0
    
    # 检测1: ipapi.co
    country_code=$(curl -sL --connect-timeout 3 -m 5 https://ipapi.co/country_code 2>/dev/null || echo "XX")
    total_checks=$((total_checks + 1))
    if [[ "$country_code" == "CN" ]]; then
        china_count=$((china_count + 1))
    fi
    
    # 检测2: ipinfo.io
    country=$(curl -sL --connect-timeout 3 -m 5 https://ipinfo.io/country 2>/dev/null || echo "XX")
    total_checks=$((total_checks + 1))
    if [[ "$country" == "CN" ]]; then
        china_count=$((china_count + 1))
    fi
    
    # 检测3: ip-api.com
    country_code2=$(curl -sL --connect-timeout 3 -m 5 http://ip-api.com/csv?fields=countryCode 2>/dev/null | cut -d, -f2 || echo "XX")
    total_checks=$((total_checks + 1))
    if [[ "$country_code2" == "CN" ]]; then
        china_count=$((china_count + 1))
    fi
    
    # 如果超过一半的检测返回CN，认为是中国大陆
    if [[ $china_count -gt $((total_checks / 2)) ]]; then
        return 0
    fi
    
    # 方法2: 测试特定网站的访问速度（中国大陆访问国外网站慢）
    # 测试GitHub访问速度
    github_time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 --max-time 5 https://github.com 2>/dev/null || echo "999")
    
    # 测试百度访问速度
    baidu_time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 --max-time 5 https://www.baidu.com 2>/dev/null || echo "999")
    
    # 如果GitHub访问时间明显长于百度，可能在中国大陆
    if [[ "$github_time" != "999" && "$baidu_time" != "999" ]]; then
        # 使用bc进行浮点数比较
        if command -v bc &> /dev/null; then
            ratio=$(echo "scale=2; $github_time / $baidu_time" | bc 2>/dev/null || echo "1")
            # 如果GitHub访问时间是百度的3倍以上，认为在中国大陆
            if (( $(echo "$ratio > 3" | bc 2>/dev/null || echo 0) )); then
                return 0
            fi
        fi
    fi
    
    # 方法3: DNS解析测试（中国大陆DNS污染）
    if command -v dig &> /dev/null; then
        # 测试google.com的DNS解析
        google_ip=$(dig +short +time=2 +tries=1 @8.8.8.8 google.com 2>/dev/null | head -n1)
        
        # 测试baidu.com的DNS解析
        baidu_ip=$(dig +short +time=2 +tries=1 @223.5.5.5 baidu.com 2>/dev/null | head -n1)
        
        # 如果google.com无法解析但baidu.com可以，可能在中国大陆
        if [[ -z "$google_ip" && -n "$baidu_ip" ]]; then
            return 0
        fi
    fi
    
    # 方法4: 时区检测（不绝对可靠，但可作为参考）
    timezone=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo "")
    if [[ -n "$timezone" ]]; then
        # 检查是否为中国时区
        case "$timezone" in
            "Asia/Shanghai"|"Asia/Beijing"|"Asia/Chongqing"|"Asia/Urumqi"|"Asia/Harbin")
                return 0
                ;;
        esac
    fi
    
    # 方法5: 语言环境检测
    lang=$(echo $LANG | cut -d'_' -f1 2>/dev/null || echo "")
    if [[ "$lang" == "zh" ]]; then
        # 结合其他条件判断
        if ping -c 1 -W 2 baidu.com &> /dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# 检测镜像源是否支持多仓库代理
is_proxy_mirror() {
    mirror="$1"
    # 检查是否在各类代理镜像列表中
    for proxy in "${universal_mirrors[@]}" "${github_proxy_mirrors[@]}" "${docker_proxy_mirrors[@]}" "${ghcr_mirrors[@]}"; do
        if [[ "$mirror" == "$proxy" ]]; then
            return 0
        fi
    done
    return 1
}

# 获取镜像源类型
get_mirror_type() {
    mirror="$1"
    for proxy in "${universal_mirrors[@]}"; do
        if [[ "$mirror" == "$proxy" ]]; then
            echo "全能代理"
            return
        fi
    done
    for proxy in "${github_proxy_mirrors[@]}"; do
        if [[ "$mirror" == "$proxy" ]]; then
            echo "GitHub代理"
            return
        fi
    done
    for proxy in "${docker_proxy_mirrors[@]}"; do
        if [[ "$mirror" == "$proxy" ]]; then
            echo "Docker代理"
            return
        fi
    done
    for proxy in "${ghcr_mirrors[@]}"; do
        if [[ "$mirror" == "$proxy" ]]; then
            echo "GHCR代理"
            return
        fi
    done
    echo "普通镜像源"
}

# 测试镜像源的可用性和代理能力
test_mirror_capability() {
    mirror="$1"
    
    # 测试基本连通性
    url="https://$mirror"
    time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "$url" 2>/dev/null)
    
    if [[ ! $time =~ ^[0-9.]+$ ]]; then
        echo "999999"
        return 1
    fi
    
    # 如果是代理镜像，测试代理能力
    if is_proxy_mirror "$mirror"; then
        # 测试代理拉取镜像（使用Docker Registry API）
        proxy_url="https://$mirror/v2/"
        test_result=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$proxy_url" 2>/dev/null)
        
        # 如果返回200或401（需要认证），说明代理可用
        if [[ "$test_result" == "200" || "$test_result" == "401" ]]; then
            echo "$time"
            return 0
        else
            echo "999999"
            return 1
        fi
    fi
    
    echo "$time"
    return 0
}

# 搜索可用的GitHub镜像源（优先选择支持Docker代理的）
find_github_mirror() {
    fastest_mirror=""
    min_time=999
    is_proxy=false
    
    # 调试信息输出到stderr
    echo "[检测] 测试 GitHub 镜像源可用性..." >&2
    
    for mirror in "${github_raw_mirrors[@]}"; do
        # 计算响应时间（3秒超时）
        time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "$mirror" 2>/dev/null)
        
        # 验证是否为有效数字
        if [[ $time =~ ^[0-9.]+$ ]] && (( $(echo "$time < $min_time" | bc -l) )); then
            min_time=$time
            fastest_mirror="$mirror"
            
            # 检查是否支持Docker代理
            domain=$(echo "$mirror" | sed 's|https://||' | sed 's|http://||')
            if is_proxy_mirror "$domain"; then
                is_proxy=true
            fi
        fi
    done
    
    if [[ -n "$fastest_mirror" ]]; then
        if [[ "$is_proxy" == "true" ]]; then
            echo "[优选] 选择支持Docker代理的GitHub镜像源: $fastest_mirror" >&2
        else
            echo "[标准] 选择普通GitHub镜像源: $fastest_mirror" >&2
        fi
    else
        echo "[警告] 未找到可用的GitHub镜像源，使用官方源" >&2
        fastest_mirror="https://raw.githubusercontent.com"
    fi
    
    # 只输出URL到stdout
    echo "$fastest_mirror"
}

# 选择最快的 Docker CE 镜像源
select_fastest_docker_ce_mirror() {
    fastest_mirror=""
    min_time=99999
    
    for mirror in "${mirror_list_docker_ce[@]}"; do
        url="https://$mirror"
        time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "$url" 2>/dev/null)
        
        if [[ $time =~ ^[0-9.]+$ ]] && (( $(echo "$time < $min_time" | bc -l) )); then
            min_time=$time
            fastest_mirror=$url
        fi
    done
    
    echo "${fastest_mirror:-https://download.docker.com}"
}

# 选择最优的 Docker Registry 镜像源（优先选择支持代理的）
select_best_registry_mirror() {
    best_mirror=""
    min_time=99999
    is_proxy=false
    mirror_type=""
    
    echo "[检测] 测试 Docker Registry 镜像源可用性..." >&2
    
    for mirror in "${mirror_list_registry[@]}"; do
        time=$(test_mirror_capability "$mirror")
        
        if [[ $time =~ ^[0-9.]+$ ]] && (( $(echo "$time < $min_time" | bc -l) )); then
            min_time=$time
            best_mirror="$mirror"
            is_proxy=true
            mirror_type=$(get_mirror_type "$mirror")
        fi
    done
    
    if [[ -n "$best_mirror" ]]; then
        if [[ "$is_proxy" == "true" ]]; then
            echo "[优选] 选择$mirror_type: $best_mirror" >&2
        else
            echo "[标准] 选择$mirror_type: $best_mirror" >&2
        fi
    else
        echo "[警告] 未找到可用的镜像源，使用默认" >&2
        best_mirror="registry-1.docker.io"
    fi
    
    echo "$best_mirror"
}

# 查找最快的 ghcr.io 镜像
find_fastest_ghcr_mirror() {
    fastest_mirror="ghcr.io"
    min_time=999
    is_proxy=false
    
    echo "[检测] 测试 GHCR 镜像源可用性..." >&2
    
    # 优先使用全能代理
    for mirror in "${universal_mirrors[@]}"; do
        url="https://$mirror/ghcr.io"
        time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "$url" 2>/dev/null)
        
        if [[ $time =~ ^[0-9.]+$ ]] && (( $(echo "$time < $min_time" | bc -l) )); then
            min_time=$time
            fastest_mirror="$mirror/ghcr.io"
            is_proxy=true
        fi
    done
    
    # 其次使用GitHub代理
    if [[ "$fastest_mirror" == "ghcr.io" ]]; then
        for mirror in "${github_proxy_mirrors[@]}"; do
            url="https://$mirror/ghcr.io"
            time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "$url" 2>/dev/null)
            
            if [[ $time =~ ^[0-9.]+$ ]] && (( $(echo "$time < $min_time" | bc -l) )); then
                min_time=$time
                fastest_mirror="$mirror/ghcr.io"
                is_proxy=true
            fi
        done
    fi
    
    # 再次使用GHCR专用代理
    if [[ "$fastest_mirror" == "ghcr.io" ]]; then
        for mirror in "${ghcr_mirrors[@]}"; do
            url="https://$mirror"
            time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "$url" 2>/dev/null)
            
            if [[ $time =~ ^[0-9.]+$ ]] && (( $(echo "$time < $min_time" | bc -l) )); then
                min_time=$time
                fastest_mirror="$mirror"
                is_proxy=true
            fi
        done
    fi
    
    # 如果还是没有，测试官方源
    if [[ "$fastest_mirror" == "ghcr.io" ]]; then
        time=$(curl -o /dev/null -s -w '%{time_total}\n' --connect-timeout 3 "https://ghcr.io" 2>/dev/null)
        if [[ $time =~ ^[0-9.]+$ ]]; then
            min_time=$time
        fi
    fi
    
    if [[ "$is_proxy" == "true" ]]; then
        echo "[优选] 选择GHCR代理镜像源: $fastest_mirror" >&2
    else
        echo "[标准] 使用官方GHCR源: $fastest_mirror" >&2
    fi
    
    echo "$fastest_mirror"
}

# 改进的YAML验证函数（不强制要求version字段）
validate_yaml() {
    file="$1"
    
    # 1. 基本文件检查
    if [[ ! -f "$file" ]]; then
        echo "错误：文件不存在"
        return 1
    fi
    
    if [[ ! -s "$file" ]]; then
        echo "错误：文件为空"
        return 1
    fi
    
    # 2. 检查文件大小（防止下载了错误页面）
    local file_size
    file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
    if [[ $file_size -lt 100 ]]; then
        echo "错误：文件太小 ($file_size bytes)，可能不是有效的YAML文件"
        return 1
    fi
    
    # 3. 检查是否是二进制文件
    if file "$file" 2>/dev/null | grep -q "binary"; then
        echo "错误：文件是二进制文件"
        return 1
    fi
    
    # 4. 检查HTML标签（防止下载了错误页面）
    if grep -iq '<!DOCTYPE\|<html' "$file" 2>/dev/null; then
        echo "错误：文件包含HTML标签，可能不是YAML文件"
        return 1
    fi
    
    # 5. 检查常见的错误页面关键词
    if grep -iq '404 not found\|403 forbidden\|500 internal server error\|bad gateway\|timeout\|error' "$file" 2>/dev/null; then
        echo "错误：文件包含错误页面内容"
        return 1
    fi
    
    # 6. 使用yamllint进行格式验证
    if command -v yamllint &> /dev/null; then
        if yamllint -d relaxed "$file" 2>/dev/null; then
            echo "YAML格式验证通过"
            return 0
        else
            echo "错误：YAML格式验证失败"
            yamllint -d relaxed "$file" 2>&1 | head -5
            return 1
        fi
    else
        # 7. 简单的YAML语法检查（备用方案）
        # 检查引号是否匹配
        local single_quotes=$(grep -o "'" "$file" | wc -l)
        local double_quotes=$(grep -o '"' "$file" | wc -l)
        
        if [[ $((single_quotes % 2)) -ne 0 ]]; then
            echo "错误：单引号数量不匹配"
            return 1
        fi
        
        if [[ $((double_quotes % 2)) -ne 0 ]]; then
            echo "错误：双引号数量不匹配"
            return 1
        fi
        
        echo "YAML文件基本验证通过（建议安装yamllint进行更严格的验证）"
        return 0
    fi
}

# 下载文件函数（支持curl和wget，增强验证）
download_file() {
    url="$1"
    output="$2"
    max_retries="5"
    
    # 优先使用wget，忽略证书
    if command -v wget &> /dev/null; then
        echo "使用 wget 下载文件..."
        for i in $(seq 1 $max_retries); do
            if wget --no-check-certificate --timeout=30 -q -O "$output" "$url"; then
                # 验证文件内容
                validation_result=$(validate_yaml "$output" 2>&1)
                if [[ $? -eq 0 ]]; then
                    echo "$validation_result"
                    echo "下载成功！"
                    return 0
                else
                    echo "文件验证失败: $validation_result"
                    rm -f "$output"
                fi
            fi
            
            if [ $i -lt $max_retries ]; then
                echo "下载失败($i/$max_retries)，重试中..."
                sleep $((i * 2))
            fi
        done
    # 备用使用curl
    elif command -v curl &> /dev/null; then
        echo "使用 curl 下载文件..."
        for i in $(seq 1 $max_retries); do
            if curl -k -sSL --connect-timeout 30 --max-time 60 -o "$output" "$url"; then
                # 验证文件内容
                validation_result=$(validate_yaml "$output" 2>&1)
                if [[ $? -eq 0 ]]; then
                    echo "$validation_result"
                    echo "下载成功！"
                    return 0
                else
                    echo "文件验证失败: $validation_result"
                    rm -f "$output"
                fi
            fi
            
            if [ $i -lt $max_retries ]; then
                echo "下载失败($i/$max_retries)，重试中..."
                sleep $((i * 2))
            fi
        done
    else
        echo "错误：系统未安装 wget 或 curl"
        return 1
    fi
    
    return 1
}

# 创建docker-compose.yml的备用方案（优化版，不需要用户名和密码）
create_docker_compose() {
    cat > docker-compose.yml << 'EOF'
services:
  wg-easy:
    environment:
      # ⚠️ Required:
      # Change this to your host's public address
      - WG_HOST=<🚨YOUR_PUBLIC_IP🚨>
      
      # Optional:
      # - WG_PORT=51820
      # - WG_DEFAULT_ADDRESS=10.8.0.x
      # - WG_DEFAULT_DNS=1.1.1.1
      # - WG_MTU=1420
      # - WG_ALLOWED_IPS=192.168.15.0/24, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
      # - WG_PRE_UP=echo "Pre Up" > /etc/wireguard/pre-up.txt
      # - WG_POST_UP=echo "Post Up" > /etc/wireguard/post-up.txt
      # - WG_PRE_DOWN=echo "Pre Down" > /etc/wireguard/pre-down.txt
      # - WG_POST_DOWN=echo "Post Down" > /etc/wireguard/post-down.txt
    
    image: ghcr.io/wg-easy/wg-easy:15
    container_name: wg-easy
    volumes:
      - ./etc_wireguard:/etc/wireguard
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
EOF
    echo "已创建默认的 docker-compose.yml 文件"
}

# 安装 Docker（使用优化方案）
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装..."
        
        if is_china_network; then
            echo "[优化] 中国大陆网络，启用加速方案"
            
            # 选择最快的镜像源
            docker_ce_mirror=$(select_fastest_docker_ce_mirror)
            echo "使用 Docker CE 镜像源: $docker_ce_mirror"
            
            # 检查内网地址映射
            for i in "${!mirror_list_extranet[@]}"; do
                if [[ "$docker_ce_mirror" == "https://${mirror_list_extranet[i]}" ]]; then
                    docker_ce_mirror="https://${mirror_list_intranet[i]}"
                    echo "切换到内网镜像源: $docker_ce_mirror"
                    break
                fi
            done
            
            # 安装 Docker
            if ! download_file "${docker_ce_mirror}/linux/get-docker.sh" "get-docker.sh"; then
                echo "[备用] Docker CE 镜像失效，使用中科大镜像"
                download_file "https://mirrors.ustc.edu.cn/docker-ce/linux/get-docker.sh" "get-docker.sh"
            fi
            
            sudo sh get-docker.sh
            
            # 配置镜像加速器（优先使用支持代理的源）
            echo "[配置] 写入镜像加速器"
            sudo mkdir -p /etc/docker
            
            # 选择最优的镜像源
            best_mirror=$(select_best_registry_mirror)
            
            # 构建镜像加速器配置
            registry_mirrors=()
            
            # 如果选中的是代理镜像，优先使用
            if is_proxy_mirror "$best_mirror"; then
                registry_mirrors+=("\"https://$best_mirror\"")
                echo "[代理] 使用$(get_mirror_type "$best_mirror"): $best_mirror"
                
                # 添加几个备用的代理镜像源
                proxy_count=1
                
                # 优先添加全能代理
                for proxy in "${universal_mirrors[@]}"; do
                    if [[ "$proxy" != "$best_mirror" && $proxy_count -lt 3 ]]; then
                        test_time=$(test_mirror_capability "$proxy")
                        if [[ $test_time =~ ^[0-9.]+$ ]] && (( $(echo "$test_time < 2" | bc -l) )); then
                            registry_mirrors+=("\"https://$proxy\"")
                            echo "[备用] 添加全能代理镜像源: $proxy"
                            proxy_count=$((proxy_count + 1))
                        fi
                    fi
                done
                
                # 添加GitHub代理
                for proxy in "${github_proxy_mirrors[@]}"; do
                    if [[ "$proxy" != "$best_mirror" && ${#registry_mirrors[@]} -lt 5 ]]; then
                        test_time=$(test_mirror_capability "$proxy")
                        if [[ $test_time =~ ^[0-9.]+$ ]] && (( $(echo "$test_time < 2" | bc -l) )); then
                            registry_mirrors+=("\"https://$proxy\"")
                            echo "[备用] 添加GitHub代理镜像源: $proxy"
                        fi
                    fi
                done
                
                # 添加Docker代理
                for proxy in "${docker_proxy_mirrors[@]}"; do
                    if [[ "$proxy" != "$best_mirror" && ${#registry_mirrors[@]} -lt 5 ]]; then
                        test_time=$(test_mirror_capability "$proxy")
                        if [[ $test_time =~ ^[0-9.]+$ ]] && (( $(echo "$test_time < 2" | bc -l) )); then
                            registry_mirrors+=("\"https://$proxy\"")
                            echo "[备用] 添加Docker代理镜像源: $proxy"
                        fi
                    fi
                done
                
                # 添加GHCR代理
                for proxy in "${ghcr_mirrors[@]}"; do
                    if [[ "$proxy" != "$best_mirror" && ${#registry_mirrors[@]} -lt 5 ]]; then
                        test_time=$(test_mirror_capability "$proxy")
                        if [[ $test_time =~ ^[0-9.]+$ ]] && (( $(echo "$test_time < 2" | bc -l) )); then
                            registry_mirrors+=("\"https://$proxy\"")
                            echo "[备用] 添加GHCR代理镜像源: $proxy"
                        fi
                    fi
                done
            else
                # 使用普通镜像源
                registry_mirrors+=("\"https://$best_mirror\"")
                echo "[标准] 使用普通镜像源: $best_mirror"
            fi
            
            # 如果配置的镜像源少于3个，补充其他可用源
            while [[ ${#registry_mirrors[@]} -lt 3 ]]; do
                for mirror in "${mirror_list_registry[@]}"; do
                    already_used=false
                    for used in "${registry_mirrors[@]}"; do
                        if [[ "\"https://$mirror\"" == "$used" ]]; then
                            already_used=true
                            break
                        fi
                    done
                    
                    if [[ "$already_used" == "false" ]]; then
                        test_time=$(test_mirror_capability "$mirror")
                        if [[ $test_time =~ ^[0-9.]+$ ]] && (( $(echo "$test_time < 3" | bc -l) )); then
                            registry_mirrors+=("\"https://$mirror\"")
                            echo "[补充] 添加镜像源: $mirror"
                            break
                        fi
                    fi
                done
                
                # 防止无限循环
                if [[ ${#registry_mirrors[@]} -eq 0 ]]; then
                    registry_mirrors+=("\"https://registry-1.docker.io\"")
                    break
                fi
            done
            
            # 写入配置文件
            sudo tee /etc/docker/daemon.json <<-EOF
{
    "registry-mirrors": [$(IFS=,; echo "${registry_mirrors[*]}")]
}
EOF
            
            echo "✅ 镜像加速器配置完成"
            echo "📋 配置的镜像源："
            printf "   %s\n" "${registry_mirrors[@]}"
            
            sudo systemctl daemon-reload
            sudo systemctl restart docker
            echo "✅ Docker 服务已重启"
        else
            echo "[标准] 国际网络，使用官方源"
            download_file "https://get.docker.com" "get-docker.sh"
            sudo sh get-docker.sh
        fi
    else
        echo "Docker 已安装"
    fi
}

# 网络环境检测和配置
echo "检测网络环境..."
if is_china_network; then
    echo "检测到中国大陆网络环境，正在优化配置..."
    USE_CHINA_MIRROR=true
    
    # 查找最快的GitHub镜像（优先支持Docker代理的）
    GITHUB_MIRROR=$(find_github_mirror)
    echo "使用 GitHub 镜像源: $GITHUB_MIRROR"
    
    # 设置文件下载URL
    GITHUB_RAW_URL="$GITHUB_MIRROR/https://raw.githubusercontent.com/wg-easy/wg-easy/master/docker-compose.yml"
    
    # 查找最快的 ghcr.io 镜像
    GHCR_MIRROR=$(find_fastest_ghcr_mirror)
    echo "使用 ghcr.io 镜像源: $GHCR_MIRROR"
    
    # 设置Docker镜像
    WG_IMAGE="$GHCR_MIRROR/wg-easy/wg-easy:15"
    
    # 安装 Docker
    install_docker
else
    echo "检测到国际网络环境，使用默认源"
    USE_CHINA_MIRROR=false
    GITHUB_RAW_URL="https://raw.githubusercontent.com/wg-easy/wg-easy/master/docker-compose.yml"
    WG_IMAGE="ghcr.io/wg-easy/wg-easy:15"
    
    # 确保Docker已安装
    if ! command -v docker &> /dev/null; then
        install_docker
    fi
fi

# 下载 docker-compose.yml（带智能重试和验证）
echo "下载配置文件..."
if ! download_file "$GITHUB_RAW_URL" "docker-compose.yml"; then
    echo "警告：无法从镜像源下载配置文件，尝试创建默认配置..."
    create_docker_compose
fi

# 替换镜像源（仅中国大陆）
if is_china_network; then
    echo "替换Docker镜像源..."
    sed -i "s|ghcr.io/wg-easy/wg-easy:15|$WG_IMAGE|g" docker-compose.yml
fi

# 验证最终的docker-compose.yml
echo "验证配置文件..."
validation_result=$(validate_yaml "docker-compose.yml" 2>&1)
if [[ $? -ne 0 ]]; then
    echo -e "\033[31m错误：配置文件验证失败\033[0m"
    echo "$validation_result"
    echo "尝试创建默认配置..."
    create_docker_compose
    
    # 再次替换镜像源
    if is_china_network; then
        sed -i "s|ghcr.io/wg-easy/wg-easy:15|$WG_IMAGE|g" docker-compose.yml
    fi
    
    # 再次验证
    validation_result=$(validate_yaml "docker-compose.yml" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31m严重错误：无法创建有效的配置文件\033[0m"
        exit 1
    fi
fi

# 提示用户修改配置
if grep -q "<🚨YOUR_PUBLIC_IP🚨>" docker-compose.yml; then
    echo ""
    echo -e "\033[33m⚠️  请注意：需要在 docker-compose.yml 中设置您的公网IP地址\033[0m"
    echo "编辑命令："
    echo "  nano docker-compose.yml"
    echo "或者："
    echo "  sed -i 's/<🚨YOUR_PUBLIC_IP🚨>/YOUR_PUBLIC_IP/g' docker-compose.yml"
    echo ""
fi

# 启动服务
echo "启动WireGuard服务..."
sudo docker compose up -d

# 显示结果
if [ $? -eq 0 ]; then
    echo -e "\n\033[32m部署成功！\033[0m"
    
    # 获取公网IP（带回退方案）
    PUBLIC_IP=$(curl -s --connect-timeout 3 icanhazip.com || curl -s --connect-timeout 3 ip.sb || curl -s --connect-timeout 3 ifconfig.me || echo "localhost")
    
    echo "======================================"
    echo " 管理界面: http://${PUBLIC_IP}:51821"
    echo "======================================"
    echo "提示: 首次访问无需密码，直接进入管理界面"
    
    # 显示Docker镜像加速信息
    if is_china_network && command -v docker &> /dev/null; then
        echo ""
        echo "🚀 Docker镜像加速已配置，支持以下仓库代理："
        
        # 获取配置的代理源
        proxy_sources=()
        if [[ -f /etc/docker/daemon.json ]]; then
            # 提取所有镜像源
            proxy_sources=($(grep -o '"https://[^"]*"' /etc/docker/daemon.json | sed 's/"//g' | sed 's/https:\/\///'))
        fi
        
        # 如果没有找到代理源，使用默认示例
        if [[ ${#proxy_sources[@]} -eq 0 ]]; then
            proxy_sources=("docker.m.daocloud.io" "ghcr.m.daocloud.io")
        fi
        
        echo ""
        echo "📋 使用方法示例："
        count=0
        for source in "${proxy_sources[@]}"; do
            if [[ $count -ge 3 ]]; then
                break
            fi
            
            # 检查是否是代理镜像
            if is_proxy_mirror "$source"; then
                mirror_type=$(get_mirror_type "$source")
                echo ""
                echo "   使用$mirror_type: $source"
                
                case "$mirror_type" in
                    "全能代理")
                        echo "   ┌─ Docker Hub: docker pull $source/nginx"
                        echo "   ├─ GHCR: docker pull $source/ghcr.io/user/image"
                        echo "   ├─ Quay: docker pull $source/quay.io/org/image"
                        echo "   ├─ K8s: docker pull $source/registry.k8s.io/pause:3.8"
                        echo "   ├─ GitHub: docker pull $source/docker.pkg.github.com/user/repo/image"
                        echo "   ├─ GCR: docker pull $source/gcr.io/project/image"
                        echo "   ├─ NVCR: docker pull $source/nvcr.io/nvidia/cuda"
                        echo "   └─ MCR: docker pull $source/mcr.microsoft.com/windows/servercore"
                        ;;
                    "GitHub代理")
                        echo "   ┌─ GHCR: docker pull $source/ghcr.io/wg-easy/wg-easy"
                        echo "   └─ GitHub: docker pull $source/docker.pkg.github.com/user/repo/image"
                        ;;
                    "Docker代理")
                        echo "   └─ Docker Hub: docker pull $source/nginx"
                        ;;
                    "GHCR代理")
                        echo "   └─ GHCR: docker pull $source/wg-easy/wg-easy"
                        ;;
                esac
                count=$((count + 1))
            else
                # 普通镜像源
                echo ""
                echo "   使用普通镜像源: $source"
                echo "   └─ Docker Hub: docker pull $source/library/nginx"
                count=$((count + 1))
            fi
        done
    fi
else
    echo -e "\n\033[31m启动失败，请检查错误信息\033[0m"
    sudo docker compose logs
    
    # 提供故障排除建议
    echo ""
    echo "故障排除建议："
    echo "1. 检查 docker-compose.yml 格式是否正确"
    echo "2. 确认端口 51820/udp 和 51821/tcp 未被占用"
    echo "3. 检查防火墙设置"
    echo "4. 查看 Docker 日志: sudo docker logs wg-easy"
    echo "5. 重新创建容器: sudo docker compose down && sudo docker compose up -d"
fi