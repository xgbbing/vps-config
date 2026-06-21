#!/bin/bash

# =====================
# 配置区
# =====================
PROJECT_DIR="你的项目路径"
PROJECT_NAME="你的项目名"
EMAIL="你的邮箱地址"
LOG_FILE="/var/log/docker-compose-monitor.log"
STATE_FILE="/tmp/docker_compose_state_${PROJECT_NAME}.txt"

# =====================
# 进入项目目录
# =====================
cd "$PROJECT_DIR" || exit 1

# =====================
# 获取状态
# =====================
echo "开始获取 Docker Compose 状态..."
STATUS=$(docker compose ps --format json 2>/dev/null)
if [ $? -ne 0 ]; then
    MSG="[ERROR] docker compose 命令执行失败或 Docker 未运行"
    echo "$(date) $MSG" >> "$LOG_FILE"
    echo -e "Subject: [Docker Alert] $PROJECT_NAME Docker 失败\n\n$MSG" | msmtp "$EMAIL"
    exit 1
fi

# =====================
# 判断异常状态
# =====================
echo "开始检查 Docker Compose 异常状态..."
FAILED=$(docker compose ps --format json | grep -E '"State":"(exited|dead|unhealthy|restarting)"')

if [ -n "$FAILED" ]; then

    CURRENT_HASH=$(echo "$FAILED" | md5sum | awk '{print $1}')

    OLD_HASH=$(cat "$STATE_FILE" 2>/dev/null)

    if [ "$CURRENT_HASH" != "$OLD_HASH" ]; then

        echo "$CURRENT_HASH" > "$STATE_FILE"

        MSG="检测到 Docker Compose 异常容器：\n\n$FAILED"

        echo "$(date) $MSG" >> "$LOG_FILE"

        echo -e "Subject: [Docker Alert] $PROJECT_NAME 容器异常\n\n$MSG" | msmtp "$EMAIL"
    fi
else
    echo "$(date) Docker Compose 正常运行！"
    # 如果恢复正常，清除状态
    rm -f "$STATE_FILE"
fi