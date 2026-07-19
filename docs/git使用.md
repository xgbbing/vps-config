# 设置git全局 HTTPS 代理为

```
git config --global https.proxy http://127.0.0.1:1080
```

# 同时也设置 HTTP 代理 (以防万一)

```
git config --global http.proxy http://127.0.0.1:1080
```

# 更改git仓库地址

```
git remote set-url origin https://github.com/xgbbing/react-pc-app1.git
```

# 查看git 代理

```
git config --global --get https.proxy
git config --global --get http.proxy
```

# 增加git缓冲区

```
git config --global http.postBuffer 524288000
```

# 强制使用 HTTP/1.1

```
git config --global http.version HTTP/1.1
```

# 恢复默认

```
git config --global --unset http.version
```

# macOS 默认文件系统大小写不敏感

```
# 推荐用 git mv 重命名文件
git mv src/pages/Home src/pages/temp
git mv src/pages/temp src/pages/home

git commit -m "fix: rename Home to home"
git push
```

# 删除 dist 目录

```
git rm -r --cached dist
```

# 彻底从 Git 历史记录中抹除 dist

```
# 安装清理工具
pip install git-filter-repo

# 执行历史清洗
git filter-repo --path dist --invert-paths --force

# 强制推送到 GitHub
git push --force origin --all
git push --force origin --tags
```
