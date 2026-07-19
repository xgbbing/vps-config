# 删除依赖目录和锁文件

```
rm -rf node_modules package-lock.json
```

# 清除 npm 缓存

```
npm cache clean --force
```

# 强制重新安装依赖

```
npm install --force
```

# 查看node基于哪种芯片版本

```
node -p process.arch
```

# 查看npm 配置

```
npm config get
npm config get proxy
npm config get https-proxy
```

# 设置npm代理

```
npm config set proxy http://127.0.0.1:1080
npm config set https-proxy http://127.0.0.1:1080
```

# 配置npm源

```
# npm官网
npm config set registry https://registry.npmjs.org/

# npm国内镜像
npm config set registry https://registry.npmmirror.com/
```

# npm 发包

```
npm login
```

# 发布

```
npm publish
```
