# NeXT-Server

Next generation proxy server.

<code>cat /proc/cpuinfo  
<br>
Intel CPU
<code>apt install ca-certificates wget curl unzip tar supervisor git -y &&</code>
<code>mkdir /root/next-server-linux-amd64 && cd $_ &&</code>
<code>wget -q -N --no-check-certificate  https://github.com/mmfdsfsd/NeXT-Server/releases/download/0.3.9/next-server-linux-amd64.zip &&</code>
<code>unzip next-server-linux-amd64.zip &&</code>
<code>rm next-server-linux-amd64.zip &&</code>
<code>chmod +x next-server</code>
<br>
AMD CPU
<code>apt install ca-certificates wget curl unzip tar supervisor git -y &&</code>
<code>mkdir /root/next-server-linux-amd64 && cd $_ && </code>
<code>wget -q -N --no-check-certificate -c https://github.com/mmfdsfsd/NeXT-Server/releases/download/0.3.9/next-server-linux-amd64v3.zip -O next-server-linux-amd64.zip &&</code>
<code>unzip next-server-linux-amd64.zip &&</code>
<code>rm next-server-linux-amd64.zip  &&</code>
<code>chmod +x next-server</code>

[program:next-server]
command = /root/next-server-linux-amd64/next-server -c /root/next-server-linux-amd64/config.yml
startsecs = 0
user = root
autostart = true
autorestart = true

## License

[GPL-3.0](./LICENSE)
