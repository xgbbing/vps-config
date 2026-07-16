# VPN速度优化
基于当前的 VPS 系统是 Ubuntu 24.04 版本
先测试当前速度
推荐测速网站 https://fast.com

## 优化方向 BBR
这是一种TCP拥赛控制算法，对高延迟线路优化非常明显

在 VPS 上执行
```
sysctl net.ipv4.tcp_congestion_control
```
如果输出不是bbr，则执行下面命令改成bbr

```
sysctl "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
```

验证是否生效
```
sysctl net.ipv4.tcp_congestion_control
```
如果输出时 `net.ipv4.tcp_congestion_control=bbr` 说明bbr已生效

开启后重新测速，能发现速度明显提升。
如果还想继续提升速度，可以尝试以下方法

## 优化方向 调整内核参数
把TCP的收发缓冲区调大，让网络传输时能一次性处理更多数据，提升网络传输效率。

查询当前参数
```
sysctl net.core.rmem_max net.core.wmem_max net.ipv4.tcp_rmem net.ipv4.tcp_wmem
```

修改参数
```
# 接收缓冲区最大值调到128MB
echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf

# 发送缓冲区最大值调到128MB
echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf

# TCP接收缓冲区 最小/默认/最大
echo "net.ipv4.tcp_rmem=4096 87380 134217728" >> /etc/sysctl.conf

# TCP发送缓冲区 最小/默认/最大
echo "net.ipv4.tcp_wmem=4096 65536 134217728" >> /etc/sysctl.conf
```

现在再测试一下网速，能发现速度又提高了一些。

## 优化方向 Linux 开启 TCP Fast Open
```
# 编辑配置文件
vim /etc/sysctl.conf

# 添加以下内容
net.ipv4.tcp_fastopen=3

# 重新加载配置
sysctl -p
```
## 优化方向 Mac 修改网络参数 MTU
```
# 获取Wi-Fi的MTU值
networksetup -getMTU Wi-Fi

# 设置Wi-Fi的MTU值
sudo networksetup -setMTU Wi-Fi 1450
```

## 优化方向 优化DNS
```
# 查看域名解析
nslookup github.com

# Mac 系统设置-网络-wifi-详情-DNS 配置增加
1.1.1.1
8.8.8.8
223.5.5.5

# 清空 macOS 的 DNS 查询缓存
sudo dscacheutil -flushcache 

# 重启 macOS 的 DNS 服务（mDNSResponder）
sudo killall -HUP mDNSResponder
```