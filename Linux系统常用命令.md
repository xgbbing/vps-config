# Linux 系统常用命令

- 文件操作

| 命令 | 说明 |
cat 查看文件内容
rm 删除文件
mv 重命名或移动文件或目录
cp 复制文件
chmod 修改文件权限
chown 修改文件所有者

- 文件目录操作
| 命令 | 说明 |
mkdir 创建目录
rmdir 删除空目录

- 查看命令
｜ 命令 | 说明 |
ls 查看当前目录下的文件和文件夹
ls -l 显示文件和文件夹的详细信息
free 查看内存使用情况
df 查看磁盘使用情况
top 显示正在运行的进程
ps 显示正在运行的进程
uname -a 显示系统信息
lsb_release -a 查看系统版本
hostnamectl 查看当前主机名及完整系统状态
cat /proc/cpuinfo 显示CPU信息
cat /proc/meminfo 显示内存信息
cat /proc/version 显示内核版本
apt update 更新软件包列表
apt upgrade -y 升级软件包
apt install -y <软件包名> 安装软件包

- 查找命令

ps aux | grep xray 搜索xray进程（含目录）