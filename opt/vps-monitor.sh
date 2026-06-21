#!/bin/bash

ALERT_EMAIL="你的邮箱地址"
DISK_THRESHOLD=80
MEM_THRESHOLD=90

DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
DISK_INFO=$(df -h /)

MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
MEM_INFO=$(free -h)

MEM_USAGE=${MEM_USAGE:-0}
DISK_USAGE=${DISK_USAGE:-0}

TIME=$(date '+%Y-%m-%d %H:%M:%S')

HOST=$(hostname)


if [ $DISK_USAGE -gt $DISK_THRESHOLD ]; then
	echo "disk usage warning!

	host:$HOST
	time:$TIME
	disk usage:$DISK_USAGE%
	threshold:$DISK_THRESHOLD%

	detail info:
	$DISK_INFO" | msmtp $ALERT_EMAIL
	echo "$TIME disk usage warning $DISK_USAGE%"
fi

if [ $MEM_USAGE -gt $MEM_THRESHOLD ]; then
	echo "memory usage waring!

	host:$HOST
	time:$TIME
	memory usage:$MEM_USAGE%
	threshold:$MEN_HTRESHOLD%

	detail info:
	$MEM_INFO" | msmtp $ALERT_EMAIL
	echo "$TIME memory warning $MEM_USAGE%"
fi

echo "$TIME disk usage:$DISK_USAGE% memory usage:$MEM_USAGE% normal"