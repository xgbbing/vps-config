#!/bin/bash

# 服务器配置导出脚本
# 功能：复制并打包Docker镜像、配置文件、服务脚本等

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 默认参数
BACKUP_DIR="/tmp/vps-backup-$(date +%Y%m%d-%H%M%S)"
DOCKER_APP_PATH="/opt/docker-app"
INCLUDE_IMAGES=false
EXCLUDE_DATA=false

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -d DIR      指定备份目录路径 (默认: $BACKUP_DIR)"
    echo "  -i          包含Docker镜像 (默认: 不包含)"
    echo "  -x          排除数据卷 (默认: 包含)"
    echo "  -h          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                          # 使用默认设置导出"
    echo "  $0 -d /backup/vps         # 指定备份目录"
    echo "  $0 -i -d /backup/vps      # 包含Docker镜像并指定备份目录"
}

# 解析命令行参数
while getopts "d:ixh" opt; do
    case $opt in
        d)
            BACKUP_DIR="$OPTARG"
            ;;
        i)
            INCLUDE_IMAGES=true
            ;;
        x)
            EXCLUDE_DATA=true
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            log_error "无效选项: -$OPTARG"
            show_help
            exit 1
            ;;
    esac
done

log_info "开始导出服务器配置..."
log_info "备份目录: $BACKUP_DIR"

# 检查源目录是否存在
if [ ! -d "$DOCKER_APP_PATH" ]; then
    log_error "Docker应用目录不存在: $DOCKER_APP_PATH"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 复制Docker应用配置
log_info "正在复制Docker应用配置..."
cp -r "$DOCKER_APP_PATH" "$BACKUP_DIR/docker-app"

# 如果排除数据，则删除数据卷相关目录
if [ "$EXCLUDE_DATA" = true ]; then
    log_info "排除数据卷..."
    # 删除可能的数据卷挂载目录（如果存在）
    find "$BACKUP_DIR/docker-app" -name "data" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$BACKUP_DIR/docker-app" -name "database" -type d -exec rm -rf {} + 2>/dev/null || true
fi

# 复制系统配置文件
log_info "正在复制系统配置文件..."

# Nginx配置
NGINX_CONF_DIR="$BACKUP_DIR/system-config/nginx"
mkdir -p "$NGINX_CONF_DIR"
cp -r /etc/nginx/nginx.conf "$NGINX_CONF_DIR/" 2>/dev/null || log_warn "无法复制nginx.conf"
cp -r /etc/nginx/conf.d/ "$NGINX_CONF_DIR/conf.d/" 2>/dev/null || log_warn "无法复制conf.d目录"
cp -r /etc/nginx/sites-enabled/ "$NGINX_CONF_DIR/sites-enabled/" 2>/dev/null || log_warn "无法复制sites-enabled目录"

# Xray配置
XRAY_CONF_DIR="$BACKUP_DIR/system-config/xray"
mkdir -p "$XRAY_CONF_DIR"
cp -r /usr/local/etc/xray/config.json "$XRAY_CONF_DIR/" 2>/dev/null || log_warn "无法复制xray config.json"

# Fail2ban配置
FAIL2BAN_CONF_DIR="$BACKUP_DIR/system-config/fail2ban"
mkdir -p "$FAIL2BAN_CONF_DIR"
cp -r /etc/fail2ban/jail.local "$FAIL2BAN_CONF_DIR/" 2>/dev/null || log_warn "无法复制jail.local"
cp -r /etc/fail2ban/action.d/ "$FAIL2BAN_CONF_DIR/action.d/" 2>/dev/null || log_warn "无法复制fail2ban action.d目录"

# Logrotate配置
LOGROTATE_CONF_DIR="$BACKUP_DIR/system-config/logrotate"
mkdir -p "$LOGROTATE_CONF_DIR"
cp -r /etc/logrotate.d/nginx "$LOGROTATE_CONF_DIR/" 2>/dev/null || log_warn "无法复制nginx logrotate配置"

# Crontab配置
CRONTAB_FILE="$BACKUP_DIR/system-config/crontab"
mkdir -p "$(dirname "$CRONTAB_FILE")"
crontab -l > "$CRONTAB_FILE" 2>/dev/null || log_warn "无法获取当前用户的crontab"

# 自定义脚本
CUSTOM_SCRIPTS_DIR="$BACKUP_DIR/custom-scripts"
mkdir -p "$CUSTOM_SCRIPTS_DIR"
cp -r /opt/vps-monitor.sh "$CUSTOM_SCRIPTS_DIR/" 2>/dev/null || log_warn "无法复制vps-monitor.sh"
cp -r /opt/docker-compose-monitor.sh "$CUSTOM_SCRIPTS_DIR/" 2>/dev/null || log_warn "无法复制docker-compose-monitor.sh"
cp -r /opt/f2b-send-mail.sh "$CUSTOM_SCRIPTS_DIR/" 2>/dev/null || log_warn "无法复制f2b-send-mail.sh"

# MSMTP配置
MSMTP_CONF_DIR="$BACKUP_DIR/system-config/msmtp"
mkdir -p "$MSMTP_CONF_DIR"
cp -r ~/.msmtprc "$MSMTP_CONF_DIR/" 2>/dev/null || log_warn "无法复制.msmtp配置"

# 证书（如果存在）
CERTS_DIR="$BACKUP_DIR/certificates"
mkdir -p "$CERTS_DIR"
cp -r /etc/letsencrypt/ "$CERTS_DIR/letsencrypt/" 2>/dev/null || log_warn "无法复制Let's Encrypt证书"

# 导出Docker镜像（如果需要）
if [ "$INCLUDE_IMAGES" = true ]; then
    log_info "正在导出Docker镜像..."
    
    DOCKER_IMAGES_DIR="$BACKUP_DIR/docker-images"
    mkdir -p "$DOCKER_IMAGES_DIR"
    
    # 获取当前运行的服务中使用的镜像
    cd "$DOCKER_APP_PATH"
    IMAGES=$(docker-compose config | grep image: | awk '{print $2}' | sort -u)
    
    for image in $IMAGES; do
        log_info "正在导出镜像: $image"
        IMAGE_NAME=$(echo "$image" | sed 's/[/:]/_/g')
        docker save "$image" -o "$DOCKER_IMAGES_DIR/$IMAGE_NAME.tar"
    done
    
    # 也可以导出所有镜像（取消注释下面的代码）
    # docker save $(docker images --format "{{.Repository}}:{{.Tag}}") -o "$DOCKER_IMAGES_DIR/all_images.tar"
fi

# 保存端口占用信息
PORT_INFO_FILE="$BACKUP_DIR/port-info.txt"
log_info "正在收集端口占用信息..."
ss -tlnp > "$PORT_INFO_FILE"

# 保存系统服务状态
SERVICE_STATUS_FILE="$BACKUP_DIR/service-status.txt"
log_info "正在收集服务状态信息..."
systemctl list-units --type=service --state=running | grep -E "(nginx|xray|docker|fail2ban)" > "$SERVICE_STATUS_FILE"

# 创建备份清单
MANIFEST_FILE="$BACKUP_DIR/MANIFEST.txt"
log_info "正在生成备份清单..."
{
    echo "备份时间: $(date)"
    echo "备份目录: $BACKUP_DIR"
    echo "包含Docker镜像: $INCLUDE_IMAGES"
    echo "排除数据卷: $EXCLUDE_DATA"
    echo "Docker应用路径: $DOCKER_APP_PATH"
    echo ""
    echo "备份内容:"
    find "$BACKUP_DIR" -type f | sort
} > "$MANIFEST_FILE"

# 打包备份文件
ARCHIVE_NAME="vps-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
log_info "正在压缩备份文件到: $ARCHIVE_NAME"
tar -czf "$ARCHIVE_NAME" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"

# 清理临时目录
rm -rf "$BACKUP_DIR"

log_info "导出完成！备份文件: $ARCHIVE_NAME"
log_info "文件大小: $(du -h "$ARCHIVE_NAME" | cut -f1)"
log_info "备份路径: $(pwd)/$ARCHIVE_NAME"

echo ""
log_info "接下来您可以将 $ARCHIVE_NAME 传输到新的服务器，然后使用 restore.sh 脚本进行恢复。"