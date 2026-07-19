# SSH 密钥登录

- 在本地电脑生成密钥对
  如果你已经有密钥对（检查 ~/.ssh/id_rsa 和 ~/.ssh/id_rsa.pub 是否存在），可以跳过这一步。

在本地终端执行：

```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

-t rsa：指定加密算法

-b 4096：密钥长度（更安全）

-C：注释，方便识别

执行后会提示：

密钥保存路径：直接回车，使用默认 ~/.ssh/id_rsa

密码短语（passphrase）：建议设置，这样即使私钥泄露，对方没有密码短语也无法使用（可选但强烈推荐）

生成完成后，你会得到两个文件：

~/.ssh/id_rsa → 私钥（绝不能泄露）

~/.ssh/id_rsa.pub → 公钥（可以放上服务器）

- 将公钥上传到服务器

方法一：使用 ssh-copy-id（最简便，推荐）

```
ssh-copy-id -p 2222 你的用户名@你的服务器ip
```

系统会提示输入密码，输入后公钥会自动追加到服务器的 ~/.ssh/authorized_keys 文件中。

方法二：手动复制
在本地查看公钥内容：

```
cat ~/.ssh/id_rsa.pub
```

复制输出的全部内容（以 ssh-rsa 开头）

登录服务器（用密码），执行：

```
mkdir -p ~/.ssh

echo "粘贴你的公钥内容" >> ~/.ssh/authorized_keys

chmod 700 ~/.ssh

chmod 600 ~/.ssh/authorized_keys

```

- 测试密钥登录是否生效
  在禁用密码登录之前，务必先测试密钥登录能否正常使用！

```
ssh -p 2222 username@你的服务器ip
```

如果设置了私钥密码短语，会提示输入

如果直接登录成功了，说明密钥配置正确 ✅

如果没有成功，检查：

公钥是否完整粘贴到 authorized_keys 中（没有换行、没有多余空格）

~/.ssh/ 目录权限是否为 700

authorized_keys 文件权限是否为 600

- 禁用密码登录（关键步骤）
  确认密钥登录成功后，再修改服务器配置。

登录服务器，编辑 SSH 配置文件：

```
vi /etc/ssh/sshd_config
```

找到并修改以下配置项：

```
# 禁用密码登录
PasswordAuthentication no

# 禁用空密码登录
PermitEmptyPasswords no

# 禁用挑战-响应认证（可选但建议）
ChallengeResponseAuthentication no

# 启用公钥认证（确保是 yes）
PubkeyAuthentication yes
```

- 重启 SSH 服务

```
sudo systemctl restart sshd
```

⚠️ 重要提示：重启后，不要立刻关闭当前 SSH 会话！保持一个已连接的窗口开着，新开一个窗口测试密钥登录。如果新窗口登录失败，你还可以用旧窗口把配置改回来，避免把自己锁在门外。

- 最终验证
  新开一个终端窗口，测试连接：

```
ssh -p 2222 username@你的服务器ip
```

如果能正常登录，说明配置成功。此时再尝试密码登录应该会被拒绝：

```
ssh -p 2222 -o PreferredAuthentications=password root@你的服务器ip
```

会收到 Permission denied (publickey) 的提示 ✅

- 补充：配置本地 SSH 快捷登录（可选）
  在本地 ~/.ssh/config 文件中添加：

```
Host myserver
    HostName 你的服务器ip
    Port 2222
    User username
    IdentityFile ~/.ssh/id_rsa
```

之后只需要执行 ssh myserver 即可登录，更加方便。

## 安全提醒

| 事项         | 说明                                                      |
| ------------ | --------------------------------------------------------- |
| 私钥保管     | 私钥 id_rsa 绝不能上传到任何地方，也不要截图分享          |
| 备份私钥     | 建议将私钥备份到安全的加密存储（如 1Password、Bitwarden） |
| 服务器备份   | 建议备份 /etc/ssh/sshd_config 文件，方便回滚              |
| 保留应急通道 | 配置完成后，建议保留一个 VNC/控制台登录方式，以防万一     |

## 缓存密钥指纹（仅当前会话缓存）

```
# 启动 ssh-agent
eval $(ssh-agent)

# 添加密钥指纹
ssh-add ~/.ssh/id_rsa

# 设置过期时间（可选，默认永久）
# 例如，设置超时时间为 1 小时（3600 秒）
ssh-add -t 3600 ~/.ssh/id_rsa

# 查看所有密钥指纹
ssh-add -l

# 删除所有密钥指纹
ssh-add -D
```

## 终端会话共享 ssh-agent

```
# 安装 keychain
brew install keychain

# ~/.bash_profile 或 ~/.zshrc 中添加以下内容
# 启动 keychain，并指定要加载的私钥文件（例如 id_rsa 和 id_ed25519）
eval $(keychain --eval --agents ssh id_rsa id_ed25519)
```
