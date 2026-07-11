#!/bin/bash

WEBROOT="/opt/docker-app/html/webapp"
OUTPUT="/opt/docker-app/nginx/conf.d/webapp.conf"

# 确保输出目录存在
mkdir -p "$(dirname "$OUTPUT")"

# 清空旧配置并写入头部
cat > "$OUTPUT" <<EOF
# 自动生成，请勿手动修改
EOF

for dir in "$WEBROOT"/*; do

    echo "checking $dir"

    [ -d "$dir" ] || {
        echo "not dir"
        continue
    }

    app=$(basename "$dir")

    # 没有 index.html 就跳过
     [ -f "$dir/index.html" ] || {
        echo "no index"
        continue
    }

    echo "generate $(basename "$dir")"

    cat >> "$OUTPUT" <<EOF

location ^~ /webapp/$app/ {
    alias "$WEBROOT/$app/";
    index index.html;
    try_files \$uri \$uri/ "/webapp/$app/index.html";
    add_header Cache-Control "no-cache";
}

location = /webapp/$app {
    return 301 /webapp/$app/;
}

EOF

done

echo "Done."