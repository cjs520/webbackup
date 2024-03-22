#!/bin/bash

Red="\033[31m" # 红色
Green="\033[32m" # 绿色
Yellow="\033[33m" # 黄色
Blue="\033[34m" # 蓝色
Nc="\033[0m" # 重置颜色
Red_globa="\033[41;37m" # 红底白字
Green_globa="\033[42;37m" # 绿底白字
Yellow_globa="\033[43;37m" # 黄底白字
Blue_globa="\033[44;37m" # 蓝底白字
Info="${Green}[信息]${Nc}"
Error="${Red}[错误]${Nc}"
Tip="${Yellow}[提示]${Nc}"

install_base(){
    OS=$(cat /etc/os-release | grep -o -E "Debian|Ubuntu|CentOS|Fedora" | head -n 1)    
    if [[ "$OS" == "Debian" || "$OS" == "Ubuntu" ]]; then
        commands=("netstat")
        apps=("net-tools")
        install=()
        for i in ${!commands[@]}; do
            [ ! $(command -v ${commands[i]}) ] && install+=(${apps[i]})
        done
        [ "${#install[@]}" -gt 0 ] && apt update -y && apt install -y ${install[@]}
    elif [[ "$OS" == "CentOS" || "$OS" == "Fedora" ]]; then
        commands=("netstat")
        apps=("net-tools")
        install=()
        for i in ${!commands[@]}; do
            [ ! $(command -v ${commands[i]}) ] && install+=(${apps[i]})
        done
        [ "${#install[@]}" -gt 0 ] && dnf update -y && dnf install -y ${install[@]}
    else
        echo -e "${Error} 很抱歉，你的系统不受支持！"
        exit 1
    fi
}

set_port(){
    echo -e "${Tip} 请设置ssh端口号!（默认为 22）"
    read -p "设置ssh端口号：" sshport
    if [ -z "$sshport" ]; then
        sshport=22
    elif [[ $sshport -lt 22 || $sshport -gt 65535 || $(netstat -tuln | grep -w "$sshport") && "$sshport" != "22" ]]; then
        echo -e "${Tip} 设置的端口无效或被占用，默认设置为 22 端口"
        sshport=22
    fi
}

set_passwd(){
    echo -e "${Tip} 请设置root密码!"
    read -p "设置root密码：" passwd
    if [ -z "$passwd" ]; then
        echo -e "${Error} 未输入密码，无法执行操作，请重新运行脚本并输入密码！"
        exit 1
    fi
}

set_ssh(){
    echo root:$passwd | chpasswd root
    sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?passwdAuthentication.*/passwdAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?RSAAuthentication.*/RSAAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    rm -rf /etc/ssh/sshd_config.d/* && rm -rf /etc/ssh/ssh_config.d/*

    # 重启SSH服务
    /etc/init.d/ssh* restart >/dev/null 2>&1

    # 输出结果
    echo
    echo -e "${Info} root密码设置 ${Green}成功${Nc}
================================
${Info} ssh端口 :      ${Red_globa} $sshport ${Nc}
================================
${Info} VPS用户名 :    ${Red_globa} root ${Nc}
================================
${Info} VPS root密码 : ${Red_globa} $passwd ${Nc}
================================"
    echo

    # 终止除当前终端会话之外的所有会话
    current_tty=$(tty)
    pts_list=$(who | awk '{print $2}')
    for pts in $pts_list; do
        if [ "$current_tty" != "/dev/$pts" ]; then
            pkill -9 -t $pts
        fi
    done
}

if [[ $(whoami) == "root" ]]; then
    install_base
    set_port
    set_passwd
    set_ssh
else
    echo -e "${Error}请执行 ${Green}sudo -i${Nc} 后以${Green}root${Nc}权限执行此脚本！"
    exit 1
fi
