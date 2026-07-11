## macOS 默认文件系统大小写不敏感
```
# 推荐用 git mv 重命名文件
git mv src/pages/Home src/pages/temp
git mv src/pages/temp src/pages/home

git commit -m "fix: rename Home to home"
git push
```