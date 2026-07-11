#!/bin/bash

WEBROOT="/usr/share/nginx/html/webapp"
OUTPUT="/opt/docker-app/nginx/conf.d/webapp.conf"

cat > "$OUTPUT" <<EOF
# 自动生成，请勿手动修改
EOF

for dir in "$WEBROOT"/*; do
    [ -d "$dir" ] || continue

    app=$(basename "$dir")

    # 没有 index.html 就跳过
    [ -f "$dir/index.html" ] || continue

    cat >> "$OUTPUT" <<EOF

location ^~ /webapp/$app/ {
    alias $WEBROOT/$app/;
    index index.html;
    try_files \$uri \$uri/ /webapp/$app/index.html;
    add_header Cache-Control "no-cache";
}

location = /webapp/$app {
    return 301 /webapp/$app/;
}

EOF

done