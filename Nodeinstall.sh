#!/bin/bash

set -e

# =========================
# 安装依赖
# =========================
apt update && apt install -y ca-certificates wget curl unzip tar git certbot

# 安装 yq
if ! command -v yq &>/dev/null; then
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    chmod +x /usr/local/bin/yq
fi

# =========================
# 下载程序
# =========================
mkdir -p /root/next-server-linux-amd64
cd /root/next-server-linux-amd64 || exit 1

# CPU 检测（/proc/cpuinfo）
CPU_VENDOR=$(awk -F: '/vendor_id/ {gsub(/ /,"",$2); print tolower($2); exit}' /proc/cpuinfo)
echo "检测到 CPU 厂商: $CPU_VENDOR"

if [[ "$CPU_VENDOR" == *"intel"* ]]; then
    ZIP_URL="https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.19/next-server-linux-amd64.zip"
elif [[ "$CPU_VENDOR" == *"amd"* ]]; then
    ZIP_URL="https://github.com/mmfdsfsd/NeXT-Server/releases/download/0.3.19/next-server-linux-amd64v3.zip"
else
    echo "无法识别 CPU，默认 Intel 版本"
    ZIP_URL="https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.19/next-server-linux-amd64.zip"
fi

wget -q -O next-server.zip "$ZIP_URL"
unzip -o next-server.zip
rm -f next-server.zip

# 下载 geosite.dat
wget -q -O geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

chmod +x next-server

CONFIG_FILE="/root/next-server-linux-amd64/config.yml"

# =========================
# 交互输入
# =========================
read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

route=$(yq '.RouteConfigPath // ""' "$CONFIG_FILE")
outbound=$(yq '.OutboundConfigPath // ""' "$CONFIG_FILE")
api_host=$(yq '.Nodes[0].ApiConfig.ApiHost // ""' "$CONFIG_FILE")
api_key=$(yq '.Nodes[0].ApiConfig.ApiKey // ""' "$CONFIG_FILE")
node_id=$(yq '.Nodes[0].ApiConfig.NodeID // 1' "$CONFIG_FILE")
node_type=$(yq '.Nodes[0].ApiConfig.NodeType // "vmess"' "$CONFIG_FILE")
cert_mode=$(yq '.Nodes[0].ControllerConfig.CertConfig.CertMode // "none"' "$CONFIG_FILE")
cert_file=$(yq '.Nodes[0].ControllerConfig.CertConfig.CertFile // ""' "$CONFIG_FILE")
key_file=$(yq '.Nodes[0].ControllerConfig.CertConfig.KeyFile // ""' "$CONFIG_FILE")

route=$(read_input "RouteConfigPath" "$route")
outbound=$(read_input "OutboundConfigPath" "$outbound")
api_host=$(read_input "ApiHost(不要输入 https://)" "$api_host")
# 自动补全 https://
if [[ ! "$api_host" =~ ^https?:// ]]; then
    api_host="https://$api_host"
fi
api_key=$(read_input "ApiKey" "$api_key")
node_id=$(read_input "NodeID" "$node_id")
node_type=$(read_input "NodeType(vmess/trojan/shadowsocks)" "$node_type")

# =========================
# TLS 自动申请
# =========================
read -p "是否自动申请 TLS 证书? (y/n) [n]: " enable_tls
enable_tls=${enable_tls:-n}

if [[ "$enable_tls" == "y" || "$enable_tls" == "Y" ]]; then
    read -p "请输入域名: " cert_domain
    read -p "请输入邮箱: " cert_email

    systemctl stop nginx 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true

    certbot certonly --standalone \
        -d "$cert_domain" \
        --non-interactive \
        --agree-tos \
        -m "$cert_email"

    CERT_PATH="/etc/letsencrypt/live/$cert_domain/fullchain.pem"
    KEY_PATH="/etc/letsencrypt/live/$cert_domain/privkey.pem"

    if [[ -f "$CERT_PATH" && -f "$KEY_PATH" ]]; then
        echo "证书申请成功"
        cert_mode="file"
        cert_file="$CERT_PATH"
        key_file="$KEY_PATH"
    else
        echo "证书申请失败，跳过 TLS 配置"
    fi
fi

# =========================
# 写入 config.yml
# =========================
yq -i "
.RouteConfigPath = \"$route\" |
.OutboundConfigPath = \"$outbound\" |
.Nodes[0].ApiConfig.ApiHost = \"$api_host\" |
.Nodes[0].ApiConfig.ApiKey = \"$api_key\" |
.Nodes[0].ApiConfig.NodeID = $node_id |
.Nodes[0].ApiConfig.NodeType = \"$node_type\" |
.Nodes[0].ControllerConfig.CertConfig.CertMode = \"$cert_mode\" |
.Nodes[0].ControllerConfig.CertConfig.CertFile = \"$cert_file\" |
.Nodes[0].ControllerConfig.CertConfig.KeyFile = \"$key_file\"
" "$CONFIG_FILE"

echo "config.yml 已更新"

# =========================
# systemd 服务
# =========================
cat <<EOF > /etc/systemd/system/next-server.service
[Unit]
Description=NeXT Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/next-server-linux-amd64
ExecStart=/root/next-server-linux-amd64/next-server -c /root/next-server-linux-amd64/config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable next-server
systemctl restart next-server

# =========================
# crontab 自动续期（每2个月，不重启服务）
# =========================
cat <<'EOF' > /usr/local/bin/cert_renew.sh
#!/bin/bash

systemctl stop nginx 2>/dev/null
systemctl stop apache2 2>/dev/null

certbot renew --quiet

EOF

chmod +x /usr/local/bin/cert_renew.sh

(crontab -l 2>/dev/null | grep -v cert_renew.sh; echo "0 3 1 */2 * /usr/local/bin/cert_renew.sh") | crontab -

echo "已设置每2个月自动续期证书（不重启 next-server）"

# =========================
# 完成
# =========================
echo "======================================"
echo "部署完成！"
echo "查看状态: systemctl status next-server"
echo "重启服务: systemctl restart next-server"
echo "======================================"
