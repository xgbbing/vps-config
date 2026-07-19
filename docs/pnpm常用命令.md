# 删除旧的依赖目录和 pnpm 锁文件

```
rm -rf node_modules pnpm-lock.yaml
```

# 清理 pnpm 缓存

```
pnpm store prune
```

# 重新安装依赖

```
pnpm install
```

# 添加依赖

```
pnpm add <package>
pnpm add <package>@<version>

pnpm add <package> --save-dev
pnpm add <package>@<version> --save-dev
```
