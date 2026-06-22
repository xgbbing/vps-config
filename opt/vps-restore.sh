#!/bin/bash

# 服务器恢复脚本
# 功能：在新服务器上恢复docker compose配置、服务及相关配置文件

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1"
}

# 检查是否以root身份运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以root身份运行，请使用sudo执行"
        exit 1
    fi
}

# 检查必要参数
if [ $# -ne 1 ]; then
    log_error "用法: $0 <backup_archive.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "备份文件 $BACKUP_FILE 不存在"
    exit 1
fi

# 检查必要工具
check_tools() {
    log_info "检查必要工具..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装Docker Compose"
        exit 1
    fi
    
    if ! command -v tar &> /dev/null; then
        log_error "tar 未安装"
        exit 1
    fi
}

# 解压备份文件
extract_backup() {
    log_info "解压备份文件: $BACKUP_FILE"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    log_info "创建临时目录: $TEMP_DIR"
    
    # 解压备份文件
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
    
    # 检查解压结果
    if [ $? -ne 0 ]; then
        log_error "解压失败"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    log_info "备份文件解压完成"
    echo "$TEMP_DIR"  # 返回临时目录路径
}

# 安装Docker和Docker Compose（如果未安装）
install_docker() {
    log_info "检查并安装Docker..."

    if ! command -v docker &> /dev/null; then
        log_info "正在安装Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
    else
        log_info "Docker已安装"
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_info "正在安装Docker Compose..."
        apt install docker-compose-plugin -y
    else
        log_info "Docker Compose已安装"
    fi
}

# 恢复Docker相关文件
restore_docker_files() {
    local temp_dir=$1
    
    log_info "恢复Docker相关文件..."
    
    if [ -d "$temp_dir/docker-app" ]; then
        mkdir -p /opt/docker-app
        cp -r "$temp_dir/docker-app/"* /opt/docker-app/
        log_info "Docker Compose项目文件已恢复到 /opt/docker-app/"
    else
        log_warn "未找到docker-app目录，跳过Docker Compose配置恢复"
    fi
    
    # 恢复Docker镜像
    if [ -f "$temp_dir/docker-images.tar" ]; then
        log_info "正在加载Docker镜像..."
        docker load -i "$temp_dir/docker-images.tar"
        log_info "Docker镜像加载完成"
    else
        log_warn "未找到Docker镜像文件，将从远程仓库拉取镜像"
    fi
}

# 恢复系统配置文件
restore_system_configs() {
    local temp_dir=$1
    
    log_info "恢复系统配置文件..."
    
    # 恢复nginx配置
    if [ -d "$temp_dir/nginx-config" ]; then
        mkdir -p /etc/nginx/conf.d/
        cp -r "$temp_dir/nginx-config/"* /etc/nginx/conf.d/
        log_info "Nginx配置已恢复"
    fi
    
    # 恢复fail2ban配置
    if [ -f "$temp_dir/fail2ban-jail-local" ]; then
        mkdir -p /etc/fail2ban/
        cp "$temp_dir/fail2ban-jail-local" /etc/fail2ban/jail.local
        log_info "Fail2ban配置已恢复"
    fi
    
    # 恢复fail2ban action配置
    if [ -d "$temp_dir/fail2ban-action" ]; then
        mkdir -p /etc/fail2ban/action.d/
        cp -r "$temp_dir/fail2ban-action/"* /etc/fail2ban/action.d/
        log_info "Fail2ban action配置已恢复"
    fi
    
    # 恢复logrotate配置
    if [ -f "$temp_dir/logrotate-nginx" ]; then
        cp "$temp_dir/logrotate-nginx" /etc/logrotate.d/nginx
        log_info "Logrotate Nginx配置已恢复"
    fi
    
    # 恢复msmtp配置
    if [ -f "$temp_dir/msmtprc" ]; then
        mkdir -p "$HOME"
        cp "$temp_dir/msmtprc" "$HOME/.msmtprc"
        chmod 600 "$HOME/.msmtprc"
        log_info "Msmtp配置已恢复"
    fi
    
    # 恢复SSL证书
    if [ -d "$temp_dir/ssl-certificates" ]; then
        mkdir -p /etc/letsencrypt/
        cp -r "$temp_dir/ssl-certificates/"* /etc/letsencrypt/
        log_info "SSL证书已恢复"
    fi
    
    # 恢复数据库文件
    if [ -d "$temp_dir/database" ]; then
        mkdir -p /data/myapp/
        cp -r "$temp_dir/database/"* /data/myapp/
        log_info "数据库文件已恢复"
    fi
}

# 恢复脚本文件
restore_scripts() {
    local temp_dir=$1
    
    log_info "恢复脚本文件..."
    
    # 恢复监控脚本
    if [ -f "$temp_dir/vps-monitor.sh" ]; then
        cp "$temp_dir/vps-monitor.sh" /opt/vps-monitor.sh
        chmod +x /opt/vps-monitor.sh
        log_info "VPS监控脚本已恢复"
    fi
    
    if [ -f "$temp_dir/docker-compose-monitor.sh" ]; then
        cp "$temp_dir/docker-compose-monitor.sh" /opt/docker-compose-monitor.sh
        chmod +x /opt/docker-compose-monitor.sh
        log_info "Docker Compose监控脚本已恢复"
    fi
    
    if [ -f "$temp_dir/f2b-send-mail.sh" ]; then
        cp "$temp_dir/f2b-send-mail.sh" /opt/f2b-send-mail.sh
        chmod +x /opt/f2b-send-mail.sh
        log_info "Fail2ban邮件发送脚本已恢复"
    fi
}

# 恢复cron任务
restore_cron() {
    log_info "恢复Cron任务..."
    
    # 备份当前的cron任务
    crontab -l > /tmp/current_crontab 2>/dev/null || echo "" > /tmp/current_crontab
    
    # 添加新的监控任务
    {
        cat /tmp/current_crontab
        echo "# Docker Compose监控任务"
        echo "*/2 * * * * /bin/bash /opt/docker-compose-monitor.sh >> /var/log/docker-compose-monitor.log 2>&1"
        echo "# 系统监控任务"
        echo "*/2 * * * * /bin/bash /opt/vps-monitor.sh >> /var/log/vps-monitor.log 2>&1"
    } > /tmp/new_crontab
    
    # 应用新的cron任务
    crontab /tmp/new_crontab
    log_info "Cron任务已更新"
    
    # 清理临时文件
    rm /tmp/current_crontab /tmp/new_crontab
}

# 启动Docker Compose服务
start_docker_services() {
    log_info "启动Docker Compose服务..."
    
    cd /opt/docker-app
    
    # 构建并启动服务
    docker-compose up -d
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    log_info "Docker Compose服务状态:"
    docker-compose ps
    
    # 显示服务日志
    log_info "Docker Compose服务日志:"
    docker-compose logs --tail=20
}

# 重启相关服务
restart_services() {
    log_info "重启相关服务..."
    
    # 重启fail2ban
    if systemctl is-active --quiet fail2ban; then
        systemctl restart fail2ban
    else
        systemctl start fail2ban
        systemctl enable fail2ban
    fi
    log_info "Fail2ban服务已重启"
    
    # 检查端口占用
    log_info "当前端口占用情况:"
    ss -tlnp
}

# 主函数
main() {
    log_info "开始服务器恢复流程..."
    
    check_root
    check_tools
    
    log_info "开始解压备份文件..."
    TEMP_DIR=$(extract_backup)
    
    log_info "安装Docker环境..."
    install_docker
    
    log_info "恢复Docker相关文件..."
    restore_docker_files "$TEMP_DIR"
    
    log_info "恢复系统配置文件..."
    restore_system_configs "$TEMP_DIR"
    
    log_info "恢复脚本文件..."
    restore_scripts "$TEMP_DIR"
    
    log_info "恢复Cron任务..."
    restore_cron
    
    log_info "启动Docker Compose服务..."
    start_docker_services
    
    log_info "重启相关服务..."
    restart_services
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    log_info "临时目录已清理"
    
    log_info "服务器恢复完成！"
    log_info "请检查以下内容："
    log_info "- Docker Compose服务状态: docker-compose ps"
    log_info "- 服务日志: docker-compose logs"
    log_info "- 端口监听: ss -tlnp"
    log_info "- 监控脚本运行: tail -f /var/log/vps-monitor.log"
    log_info "- Fail2ban状态: fail2ban-client status"
}

# 执行主函数
main