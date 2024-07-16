# NeXT-Server

Next generation proxy server.

## Thanks

* [XrayR](https://github.com/XrayR-project/XrayR)

## Licence

[Mozilla Public License Version 2.0](./LICENSE)
<br>
Debian9源<br>
<code>deb http://archive.debian.org/debian stretch main</code><br>
<code>deb-src http://archive.debian.org/debian stretch main</code><br>
<code>deb http://archive.debian.org/debian-security stretch/updates main</code><br>
<code>deb-src http://archive.debian.org/debian-security stretch/updates main</code><br>

查看CPU类型<br>
<code>cat /proc/cpuinfo </code><br>
<br>
Intel CPU<br>
<code>apt install ca-certificates wget curl unzip tar supervisor -y &&</code><br>
<code>mkdir /root/next-server-linux-amd64 && cd $_ &&</code><br>
<code>wget -q -N --no-check-certificate  https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.2/next-server-linux-amd64.zip &&</code><br>
<code>unzip next-server-linux-amd64.zip &&</code><br>
<code>rm next-server-linux-amd64.zip &&</code><br>
<code>chmod +x next-server</code><br>
<br>
AMD CPU <br>
<code>apt install ca-certificates wget curl unzip tar supervisor -y &&</code><br>
<code>mkdir /root/next-server-linux-amd64 && cd $_ && </code><br>
<code>wget -q -N --no-check-certificate -c https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.2/next-server-linux-amd64v3.zip -O next-server-linux-amd64.zip &&</code><br>
<code>unzip next-server-linux-amd64.zip &&</code><br>
<code>rm next-server-linux-amd64.zip  &&</code><br>
<code>chmod +x next-server</code><br>
<br>
supervisor守护进程<br>
<code>[program:next-server]<br>
<code>command = /root/next-server-linux-amd64/next-server -c /root/next-server-linux-amd64/config.yml</code><br>
<code>user = root</code><br>
<code>autostart = true</code><br>
<code>autorestart = true</code><br>

<code>systemctl restart supervisor</code>
