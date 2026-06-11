# V2Ray安装和配置（vmess）

首先你需要买一台位于境外的服务器VPS

接着请使用SSH连到服务器

在CentOS、Ubuntu等常用Linux系统上，直接执行如下命令安装V2Ray（如果已安装则更新程序）：

```
  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
```

该脚本由 `v2fly` 官方维护，支持 Debian/Ubuntu/CentOS 等主流系统，自动安装 `v2ray-core` 并配置 systemd 服务。

安装完成后，配置文件为/usr/local/etc/v2ray/config.json，内容默认为空。（具体路径以实际为准）
粘贴下面模板内容至配置文件中：

```
{
  "inbounds": [{
    "port": 监听端口,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "用户id，生成方法见下面说明"
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
```

配置文件中最重要的信息有两项：
1. port（监听端口），建议是1024-65535中的任意一个数字，例如12345，6789等；
2. clients中的id（用户id），可以运行命令 /usr/local/bin/v2ray uuid 得到（具体路径以实际为准）。这两个参数将在配置客户端时用到，而必须与服务端一致！

配置好后，接下来防火墙放行监听的端口（有些VPS并没有启动防火墙），设置开机启动并运行V2Ray：

```
# firewalld放行端口（适用于CentOS7/8）
firewall-cmd --permanent --add-port=123456/tcp # 23581改成你配置文件中的端口号
firewall-cmd --reload

# ufw放行端口（适用于ubuntu）
ufw allow 12345/tcp # 12345改成配置中的端口号

# iptables 放行端口（适用于CentOS 6/7）
iptables -I INPUT -p tcp --dport 12345 -j ACCEPT

# 设置开机启动
systemctl enable v2ray

# 运行v2ray
systemctl start v2ray
```

`ss -ntlp | grep v2ray` 命令可以查看v2ray是否正在运行。如果输出为空，大概率是被selinux限制了，解决办法如下：

1. 禁用selinux：`setenforce 0`;

2. 重启v2ray：`systemctl restart v2ray`

到此，服务端应该配置好了。如果服务器商层面还有防火墙（阿里云/Google/AWS购买的vps），请登录网页后台，放行v2ray的端口。

接下来介绍v2ray客户端的配置和使用。

# 客户端下载和使用

V2Ray项目不区分客户端和服务端，然而实际使用中客户端经常需要用户界面，因此许多开发者基于V2Ray内核开发了友好易用的客户端。

- IOS：https://github.com/Cenmrev/V2RayX/releases
- Android：https://github.com/2dust/v2rayNG/releases
- Windows、Linux、macOS https://github.com/2dust/v2rayN/releases

下载客户端，在配置窗口点击“增加”，然后在“服务器信息”中填入服务器的ip、端口、用户id：

新版V2ray抛弃了额外id(alterId)这个参数，如果客户端仍有这个选项，建议填0。

服务器运行正常，客户端配置无误的话，接下来就可以愉快地科学上网了。
