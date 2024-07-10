# NeXT-Server (XrayR Edition)

NeXT-Server (XrayR Edition) is a fork of XrayR with full WebAPI support & bugfixes.

## Thanks

* [XrayR](https://github.com/XrayR-project/XrayR)

## Licence

[Mozilla Public License Version 2.0](https://github.com/sspanel-uim/XrayR/blob/sspanel/LICENSE)



使用方法<br>

1.查看CPU类型 <br>
<code> cat /proc/cpuinfo  </code> <br>
2.安装依赖文件 <br>
<code>apt install ca-certificates wget curl unzip tar supervisor -y</code><br>
3.下载安装  <br>
Intel CPU<br>
<code>mkdir /root/next-server-linux-amd64 && cd $_ &&
wget -q -N --no-check-certificate  https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.2/next-server-linux-amd64.zip &&
unzip next-server-linux-amd64.zip &&
rm next-server-linux-amd64.zip &&
chmod +x next-server </code><br>
AMD64 CPU <br>
<code>mkdir /root/next-server-linux-amd64 && cd $_ && 
wget -N --no-check-certificate -c https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.2/next-server-linux-amd64v3.zip -O next-server-linux-amd64.zip &&
unzip next-server-linux-amd64.zip &&
rm next-server-linux-amd64.zip  &&
chmod +x next-server</code><br>

4.添加到supervisor监控<br>
<code>[program:next-server]
command = /root/next-server-linux-amd64/next-server -c /root/next-server-linux-amd64/config.yml
user = root
autostart = true
autorestart = true</code><br>

5.重启supervisor<br>
<code>systemctl restart supervisor</code>

