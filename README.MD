这个脚本能自动生成vpn的配置文件（客户端和服务端），采用静态秘钥认证，只能点对点连接，详情可以参考下文

[OPENVPN使用静态秘钥认证](https://185.es/2015/09/openvpn%E4%BD%BF%E7%94%A8%E9%9D%99%E6%80%81%E7%A7%98%E9%92%A5%E8%AE%A4%E8%AF%81.html)

大概工作流程，在本地ping对端VPN地址5次，若收到返回包为0，则重复一次，2次过后更换端口

首先请在文件内定义VPN服务器的外网ip

openvpn采用的是经过重新编译的版本，可以对流量进行混淆，采用的patch

如果是普通的OPENVPN请删掉开头的salt=x3KV8lBxynZZ5C2cUmZZ...和文中的2处obfs-salt $salt

https://github.com/dc3l1ne/repo/blob/master/openvpn-obfs/openvpn-2.3.6-obfs.patch

配置文件上传到服务端是使用的scp，所以请在本地配置和远端配置好 私钥/公钥 以实现免密码登录

还有需求就请自己修改一下shell吧，这份shell代码都是简单易懂的最low的那种。

由于使用了killall命令，如果服务器或客户端运行了多个vpn实例请勿使用该脚本！

后面如果带上999参数，代表本次立即生成一个新端口

./port 999
