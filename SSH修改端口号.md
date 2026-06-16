# 修改 ssh 端口号

切换 root 用户
```
sudo -i
```
1. 修改 ssh 配置文件
```
vi /etc/ssh/sshd_config
```

修改端口号 （比如新端口号为 2222）
```
PORT 2222

# 允许密码登录
PasswordAuthentication yes

# 允许 root 登录
PermitRootLogin yes
```
重启 ssh 服务
```
systemctl restart ssh
```
2. utw allow ssh 新端口
```
utw allow ssh 2222/tcp
```
推荐用限制
```
utw limit ssh 2222/tcp
```

重启防火墙
```
ufw reload
```

查看防火墙状态
```
ufw status
```

确认 ssh 服务正常运行
```
systemctl status ssh
```

3. 新开一个窗口验证新端口
```
ssh -p 2222 你的用户名@你的服务器ip
```
确认 ssh 登录成功后再关闭旧连接窗口

3. 禁用 ssh 旧端口
```
ufw deny 22/tcp

ufw reload
```
查看防火墙状态
```
ufw status
```
