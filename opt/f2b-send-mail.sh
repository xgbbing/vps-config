#!/bin/bash
set -e

IP="${1:-unknown}"
USER="${2:-unknown}"
MATCHES="${3:-unknown}"
FAILURES="${4:-unknown}"
TIME="${5:-unknown}"

TO="你的邮箱地址"

NOW=$(date '+%F %T %z')

echo "Fail2ban notice!

当前用户:$USER
ip地址:$IP
当前时间:$NOW
日志时间:$TIME
匹配失败次数:$FAILURES
日志内容:$MATCHES

Fail2ban notice." | msmtp $TO

echo "$NOW $USER fail2ban notice!"