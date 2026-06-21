# Docker 容器迁移方案

## 迁移前备份
## nginx 配置
```
vi /etc/nginx/nginx.conf
vi /etc/nginx/conf.d/default.conf
vi /etc/nginx/sites-enabled/default
```
 
## 端口占用
```
ss -tlnp
```

## 前端文件

/var/www/html

## node 信息
node 服务目录 /opt/node-server
node 启动命令 'node app.js'
node 用的端口  3000
node 环境变量 PORT=3000 NODE_ENV=production

## 数据库文件
/data/myapp/database

## xray 配置
xray 配置文件 /usr/local/etc/xray/config.json

## cron 配置
```
vi /opt/monitor.sh
```

## 日志论证 logrotate 配置
```
vi /etc/logrotate.d/nginx
```

## fail2ban 配置
```
vi /etc/fail2ban/jail.local
```

## msmtp 配置

## 证书目录
/etc/letsencrypt

## Certbot 配置

## 迁移准备
          
## 安装 Docker 和 Docker Compose
```
# 安装 Docker
curl -fsSL https://get.docker.com | sh

# 添加当前用户到 docker 组
sudo usermod -aG docker $USER

# 安装 Docker Compose
apt install docker-compose-plugin -y

# 验证 Docker 和 Docker Compose是否安装成功：
docker --version
docker-compose --version

# 开机启动 Docker
systemctl start docker
systemctl enable docker
```

## 创建 docker 项目结构
```
mkdir -p /opt/docker-app
cd /opt/docker-app
```

## 项目目录结构如下

```
/opt/docker-app/
├── docker-compose.yml
├── nginx/
│   └── default.conf # nginx 配置文件
|
├── html/
│   ├── home # 主页前端资源
│   └── admin # 后台管理系统前端资源
│   └── h5 # 移动端页面前端资源
│   └── app1 # app1 前端资源
│   └── app2 # app2 前端资源
|
├── node/
│   ├── Dockerfile
│   ├── package.json
│   ├── package-lock.json
│   └── dist/...
└── xray/
    └── config.json
```

## node 迁移
```
cp -r /opt/node-server/dist /opt/node-server/package*.json /opt/docker-app/node/
```

## 编写 node/Dockerfile

[node/Dockerfile 示例](https://github.com/xgbbing/vps-config/blob/main/docker-app/node/Dockerfile)

## 编写 node/.dockerignore

[node/.dockerignore 示例](https://github.com/xgbbing/vps-config/blob/main/docker-app/node/.dockerignore)

## nginx 迁移

```
cp -r /etc/nginx/conf.d/default.conf /opt/docker-app/nginx/
```

## 编写 nginx/default.conf

```
vi /opt/docker-app/nginx/default.conf
```

[nginx/default.conf 示例](https://github.com/xgbbing/vps-config/blob/main/docker-app/nginx/default.conf)

## 前端 迁移

```
cp -r /var/www/html/* /opt/docker-app/html/
```

## xray 迁移

```
cp -r /usr/local/etc/xray/config.json /opt/docker-app/xray/
```

## 编写 xray 配置

[xray/config.json 示例](https://github.com/xgbbing/vps-config/blob/main/docker-app/xray/config.json)

## 编写 docker-compose.yml 文件

```
vi /opt/docker-app/docker-compose.yml
```

[docker-compose.yml 示例](https://github.com/xgbbing/vps-config/blob/main/docker-app/docker-compose.yml)

## 修改日志轮转服务 todo
```
vi /etc/logrotate.d/nginx
```

```
# 修改为 docker 方式重载
postrotate
    docker exec nginx nginx -s reopen
```

## 修改 Fail2ban 配置 todo

```
vi /etc/fail2ban/jail.local
```

```
# 新增：监控 nginx 容器日志
[nginx-http-auth]
enabled = true
prot = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
```

```
# 重启 fail2ban 服务
systemctl restart fail2ban
```

## Cron 添加容器状态监控 todo

```
vi /opt/vps-monitor.sh
```

```
# 监控容器是否正常运行 如果异常则发送邮件报警 msmtp todo

```

## 开始迁移（停机操作）
```
# 确认所有配置文件都已经备份好&复制好
ls /opt/docker-app

# 停掉现有服务
pm2 stop all

systemctl stop nginx
systemctl disable nginx

systemctl stop xray
systemctl disable xray

# 进入项目
cd /opt/docker-app

# 构建并启动容器
docker-compose up -d

# 查看容器状态
docker compose ps

# 查看日志确认正常
docker compose logs -f

# 测试网站是否正常
curl http://xgbbing.com
curl http://www.xgbbing.com

```

## docker 迁移回滚
```
# 停掉 docker 容器
docker compose down

# 重新宿主机服务
systemctl start nginx
systemctl enable nginx
systemctl start xray
systemctl enable xray
pm2 start all
```

## docker 容器常用命令
｜ 命令	｜ 说明	 ｜ 适用你的场景 ｜ 
｜ `docker compose build <服务名>` ｜ 构建镜像（会拉取镜像）。 ｜ 创建镜像时，会拉取镜像。 ｜
｜ `docker compose up -d`	｜ 后台启动所有服务。如果镜像不存在会先拉取。｜修改 docker-compose.yml 后，必须用此命令重建容器以应用新配置。 ｜ 
｜ `docker compose stop`	｜ 停止所有容器（不会删除容器）。 ｜ 临时暂停服务。 ｜ 
｜ `docker compose start`	｜ 启动已被停止的容器。	｜ 恢复暂停的服务。 ｜ 
｜ `docker compose restart` ｜ 重启所有容器（不会应用 yml 文件的改动）。 ｜ 仅当容器卡死、需要重新加载进程时使用（不解决配置问题）。 ｜ 
｜ `docker compose down`	｜ 停止并删除所有容器、网络（默认不删除数据卷）。	｜ 彻底清理环境，准备全新重建时使用。 ｜ 
|  `docker compose down --volumes` ｜ 删除所有容器、网络、卷（数据卷）。 ｜ 彻底清理环境，准备全新重建时使用。 ｜ 
｜ `docker logs -f xray` ｜ 查看 xray 的实时日志 ｜ |
｜ `docker logs xray` ｜ 查看 xray 的历史日志 ｜ |
｜ `docker exec -it xray /bin/bash` ｜ 进入 xray 容器 ｜ |
｜ `docker stats nginx --no-stream` ｜ 显示 nginx 容器的实时资源使用情况 ｜ |
| `docker-compose ps` ｜ 显示所有容器的状态 ｜|
| `docker inspect xray | grep IPAddress` ｜ 显示 xray 容器的 IP 地址 | |
| `netstat -tlnp | grep 443` | 应该只看到 Xray 在监听 443 | |
| `docker exec -it xray ping nginx` |  检查容器间通信 应该能通 | |
｜ `docker compose exec xray sh` | 进入 xray 容器 | 适合docker-compose 创建的容器 |
| `docker exec -it xray sh` | 进入 xray 容器 | 适合 docker 创建的容器 |
｜ `docker compose exec nginx cat /etc/nginx/default.conf` | 不进入容器直接查看 nginx 配置 ｜ ｜
｜ `docker compose exec nginx ps aux` | 查看 nginx 进程 ｜ ｜
| `docker compose exec nginx nginx -t` | 检查 Nginx 配置文件 | ｜

## 进入容器后如何退出容器
进入容器后，要退回到宿主机，执行以下任一操作即可：

- 输入 exit 然后按回车（最标准的方式）
- 按快捷键 Ctrl + D（快速退出）
- 按 Ctrl + C（如果进程卡住，强制中断退出）