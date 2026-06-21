# XRay安装和配置（vless+reality）

首先你需要买一台位于境外的服务器VPS

部署Ubuntu系统（推荐24.04 或其他 LTS 版本）

接着请使用SSH连到服务器

## 安装XRay

在Ubuntu系统上，直接执行如下命令安装XRay（如果已安装则更新程序）：

```
  bash <(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)
```

该脚本由官方维护，核心为 `Xray-core`。

安装后检查版本

```
  # 检查版本
  xray version
```

## 生成 UUID：
```
  xray uuid
```
保存结果。

## 生成 Reality 密钥对：
```
xray x25519
```
会得到：

Private key: xxxxxx
Public key: yyyyyy

两个都保存。

## 生成 Short ID
```
openssl rand -hex 8
```
例如：
```
6ba85179d7f4c1a2 或者 1234abcd
```
保存。

## 配置文件

Xray安装完成后，配置文件为 `/usr/local/etc/xray/config.json`，内容默认为空。（具体路径以实际为准）
粘贴下面模板内容至配置文件中：

```
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "listen": "::",
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "你的UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": [
            "www.microsoft.com"
          ],
          "privateKey": "你的PrivateKey",
          "shortIds": [
            "你的ShortID"
          ]
        }
      }
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
          "quic"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "block"
    }
  ]
}
```

配置文件中最重要的信息有两项：
1. port（监听端口），建议是1024-65535中的任意一个数字，例如12345，6789等，如果端口被占用，就改用其他端口。
2. clients中的id（用户id），可以运行命令 `xray uuid` 得到（具体命令路径以实际为准），强烈建议复制粘贴输入，不要手动输入，避免出错！
3. PrivateKey 是 `xray x25519` 创建的密钥对中的私钥。客户端中使用的是 PublicKey 公钥，公钥和私钥必须是一对，密钥输入最好直接复制粘贴，不要手动输入，避免出错！
4. ShortID 只能是16进制字符且是小写，可配置8个或16个字符，合法字符含：0123456789abcdef。
5. dest 选择一个大型站点作为dest，如：www.microsoft.com:443，客户端的配置中SNI填写为该站点不含端口的地址，必须与服务端一致。

Reality 推荐dest

常见选择：

- www.microsoft.com
- www.cloudflare.com
- www.apple.com
- www.amazon.com

一般选一个大型站点即可。

这些参数将在配置客户端时用到，而必须与服务端一致！

测试配置语法是否正确：
```
xray run -test -config /usr/local/etc/xray/config.json
```
显示：

Configuration OK

即可。

每次修改配置后可以验证语法，有报错先修复。
每次修改配置后都需要重启xray。

## 防火墙放行 & 设置开机启动

配置好后，接下来防火墙放行监听的端口（有些VPS并没有启动防火墙），设置开机启动并运行xRay：

```
# ufw放行端口（适用于ubuntu）
ufw allow 8443 # 8443改成配置中的端口号

# 设置开机启动
systemctl enable xray

# 运行xray
systemctl start xray

# 检测xray运行状态
systemctl status xray
```

`ss -ntlp | grep xray` 命令可以查看xray的端口是否正在被监听。如果输出为空，大概率是被selinux限制了，解决办法如下：

1. 禁用selinux：`setenforce 0`;

2. 重启xray：`systemctl restart xray`

到此，服务端应该配置好了。如果服务器商层面还有防火墙（阿里云/Google/AWS购买的vps），请登录网页后台，放行xray的端口。

接下来介绍xray客户端的配置和使用。

# 客户端下载和使用

XRay项目不区分客户端和服务端，然而实际使用中客户端经常需要用户界面，因此许多开发者基于XRay内核开发了友好易用的客户端。

- IOS：https://github.com/yanue/V2rayU/releases
- Android：https://github.com/2dust/v2rayNG/releases
  新版本才支持 `xray-core`，切换后如果不生效可以重启一下app或者手机
- Android：https://github.com/hiddify/hiddify-app/releases
  界面友好
- Windows、Linux、macOS：https://github.com/2dust/v2rayN/releases

下载客户端，在配置窗口点击“增加”，然后在“服务器信息”中填入以下信息：

## 新增 VLESS 节点

地址：你的 VPS IP
端口：你的端口 8443
UUID：你的 UUID
Flow：xtls-rprx-vision
传输协议：TCP
TLS：Reality

Reality 参数：

Public Key：你的 PublicKey
Short ID：你的 ShortID
SNI：www.microsoft.com
Fingerprint：chrome

服务器运行正常，客户端配置无误的话，接下来就可以愉快地科学上网了。

# 排错流程
1. 确认IP是否被封
  访问 https://ping.pe/你的IP
2. 确认端口是否监听
```
ss -tlnp | grep xray
```
或者 
```
ss -tlnp | grep 你的端口
```
3. 确认端口是否被防火墙拦截
  ```
  ufw status
  ```
  确认端口是否可以从外部访问
  ```
  telnet 你的IP 你的端口
  ```
4. 确认xray是否正常运行
```
systemctl status xray
```
5. 查看错误日志
 ```
 tail -50 /var/log/xray/error.log
 ```
6. 对比客户端和服务端配置
  重点检查公钥是否正确
  重点检查私钥是否正确
  验证私钥对应什么公钥可以运行
  ```
  xray x25519 -i 你的私钥
  ```
  输出公钥与你客户端中的公钥对比是否一致
  （下划线、连字符横杆、大小写都需一致）
  
  重点检查id是否正确
  重点检查端口是否正确
  重点检查shortId是否正确
7. 确认客户端内核是否为 `xray-core`
8. 开启调试模式排查日志
9. 确认是否能正常访问目标站点
```
curl -I https://www.microsoft.com
```
10. 用 curl 模拟 Reality 握手
```
curl -v https://你的服务器IP:你的端口 --resolve www.microsoft.com:你的端口:你的服务器IP --tls-max 1.3
```
11. 检查客户端版本
Reality 需要 xray 1.8.0 或更高版本
12. 完全重启 xray 后再在客户端尝试连接
```
systemctl stop xray
sleep 2s
systemctl start xray
sleep 2s
systemctl status xray
```
13. 是否使用官方脚本安装的xray
14. 检查手机是否授权客户端 VPN 权限
    检查客户端是否不受电池优化限制
    检查客户端是否允许后台流量
15. 重启手机 或者 重启客户端
16. 客户端中的预定义规则或者路由设置改成全局模式（Global），不绕过局域网和大陆，后尝试访问 谷歌 或者 https://youtube.com。先用全局模式调通后再按需配置规则。
17. 浏览器访问https://ip.sb 看显示的 IP 是手机 IP 还是VPS IP
18. 如果要配置域名策略，推荐选择 IPIfNonMatch 模式，即域名匹配不到规则时才解析IP再匹配，准确且速度合理。
其他参数：
Asls： 直接用域名匹配路由规则，速度快但匹配不准确
IPOnDemand：遇到IP规则立即解析域名，最准确但最慢



# 如何开启调试模式
排查问题时可以开启debug日志
修改配置文件，将"logLevel"设置为"debug"
```
{
 "log": {
    "loglevel": "debug",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  }
}
```

实时查看错误日志
```
tail -f /var/log/xray/access.log /var/log/xray/error.log
```

debug会产生大量日志，等问题解决后请改回"warning"，否则容易占满磁盘空间！

清空日志
```
echo "" > /var/log/xray/access.log
echo "" > /var/log/xray/error.log
```
确认已清空
```
cat /var/log/xray/access.log
cat /var/log/xray/error.log
```

# VPN 测速 & 优化
推荐测速网站：https://fast.com

如果速度低还可以做一些优化，优化方法可以参考我的另一篇文章[VPN速度优化](https://github.com/xgbbing/VPS-config/blob/main/VPN%E9%80%9F%E5%BA%A6%E4%BC%98%E5%8C%96.md)