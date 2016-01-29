# LowerShell

带加密的 ICMP shell。**期末作业，纯属实验。**

## 原理

### 隐写 C&C 命令

将二进制数据转为 base64 编码后映射成为 64（2<sup>6</sup>）个元字符，即需要 6 个二进制位存储。利用 RGB 模式的图像作为载体，使用其三个通道的最低二进制位作为存储空间，两个像素对应一个元字符。即可实现将任意二进制文件嵌入一个足够大的位图中。

图像的 EXIF 信息中也可以嵌入额外数据，但相比最低有效位更容易被发现。本程序使用 EXIF 的 Software 字段记录隐写 payload 的长度，使用一种原创的编码将任意整数 n 伪装成肉眼看上去很合理的“版本号”。算法为先将 n 开平方后向下取证得 e，将 n 转换为 e 进制数，以小数点为分隔符，最后将整个字符串倒转。如 n=1992 可编码成为 `1.1.21.44`。

通过将图片发布于社交网络的方式，来避免自行提供 C&C 域名，起到逃避追踪的效果。

### 通信

ICMP 的 echo 请求的 data 字段可以携带额外信息，可实现隧道通信。在 icmpsh 的基础上增加了一层加密，使流量更难以分析。

但加密只有混淆流量的意义。因为加密使用的 AES 密钥直接放置在图片中，通过对服务端程序逆向工程很容易恢复出密钥，从而进一步对历史流量进行取证。而且由于 echo 消息要求 request 与 response 的相同，针对此隧道可以很容易实现入侵检测。

## 组件

程序由三部分组成：隐写工具、服务端、客户端。

### util

隐写制作工具，将文件嵌入到图像中。需要安装 PIL。

使用方法：`steg.py {数据文件} {载体图像} {输出图像}`

合成输出图像之后，发布至支持原图的社交网站上提供给 server 端进行检索和下载。本例中使用 Lofter，支持原图存储和 hashtag。

### server

服务端，即受控端。使用 PowerShell 实现。

运行服务端后自动静默从 Lofter 下的 #ThisIsAnUniqueSecretTag# 标签查找并下载原图，尝试提取隐藏的 C&C 配置文件，最后通过 ping 请求反弹连接客户端。使用 sha256 进行身份验证，以防 server 连接到错误的 client 上。

### client

客户端，即控制端，基于 [icmpsh](https://github.com/inquisb/icmpsh) 代码实现。通过身份验证后，通过 ping 和 echo 与控制端进行通信，采用 AES 对流量进行加密。

## 使用

准备依赖项

```
pip install -r requirements.pip
```

修改 example.config.json 中的主机和通信密码，嵌入配置文件到图片水印：

```
cd util
python steg.py example.config.json image.jpg output.png
```

将生成的 output.png 上传至 Lofter，添加标签。

根据需要修改 client/config.py 的配置，启动客户端监听：

```
python client/icmpsh.py
```

根据需要修改服务端 config.ps1 中的配置，启动服务端：

```
powershell -executionPolicy server.ps1
```

如果一切正常，即可观察到服务端上线并进行控制。

## 授权

GPL v3
