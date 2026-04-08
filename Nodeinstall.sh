#!/bin/bash

set -e

CONFIG_FILE="/root/next-server-linux-amd64/config.yml"
INSTALL_DIR="/root/next-server-linux-amd64"

# 安装依赖
apt update && apt install -y ca-certificates wget curl unzip tar supervisor git certbot yq

# 克隆 ServerStatus（可选）
git clone https://github.com/mmfdsfsd/ServerStatus.git || true

# 创建目录
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 检测 CPU 厂商
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
echo "检测到 CPU 厂商: $CPU_VENDOR"

# 下载对应压缩包
if [[ "$CPU_VENDOR" == "genuineintel" ]]; then
    ZIP_URL="https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.19/next-server-linux-amd64.zip"
elif [[ "$CPU_VENDOR" == "authenticamd" ]]; then
    ZIP_URL="https://github.com/mmfdsfsd/NeXT-Server/releases/download/0.3.19/next-server-linux-amd64v3.zip"
else
    echo "无法识别 CPU 厂商，请手动选择下载包"
    exit 1
fi

wget -q -N --no-check-certificate "$ZIP_URL"
unzip -o $(basename $ZIP_URL)
rm -f $(basename $ZIP_URL)

# 下载 geosite.dat
rm -f geosite.dat
wget -q -N --no-check-certificate -c https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O geosite.dat

chmod +x next-server

# 交互输入函数：用户回车 → 保留原注释
read_input() {
    local prompt="$1"
    local current_value="$2"
    local input
    read -p "$prompt [$current_value]: " input
    echo "$input"
}

# 读取原值（如果字段不存在返回空字符串）
route=$(yq '.RouteConfigPath // ""' "$CONFIG_FILE")
outbound=$(yq '.OutboundConfigPath // ""' "$CONFIG_FILE")
api_host=$(yq '.Nodes[0].ApiConfig.ApiHost // ""' "$CONFIG_FILE")
api_key=$(yq '.Nodes[0].ApiConfig.ApiKey // ""' "$CONFIG_FILE")
node_id=$(yq '.Nodes[0].ApiConfig.NodeID // 1' "$CONFIG_FILE")
node_type=$(yq '.Nodes[0].ApiConfig.NodeType // "vmess"' "$CONFIG_FILE")
cert_mode=$(yq '.Nodes[0].ControllerConfig.CertConfig.CertMode // "none"' "$CONFIG_FILE")
cert_file=$(yq '.Nodes[0].ControllerConfig.CertConfig.CertFile // ""' "$CONFIG_FILE")
key_file=$(yq '.Nodes[0].ControllerConfig.CertConfig.KeyFile // ""' "$CONFIG_FILE")

# 提示用户输入，用户回车 → 保留原注释/空值
input=$(read_input "RouteConfigPath" "$route")
if [[ -n "$input" ]]; then
    yq -i ".RouteConfigPath = \"$input\"" "$CONFIG_FILE"
fi

input=$(read_input "OutboundConfigPath" "$outbound")
if [[ -n "$input" ]]; then
    yq -i ".OutboundConfigPath = \"$input\"" "$CONFIG_FILE"
fi

input=$(read_input "ApiHost (不要输入 https://)" "$api_host")
if [[ -n "$input" ]]; then
    yq -i ".Nodes[0].ApiConfig.ApiHost = \"https://$input\"" "$CONFIG_FILE"
fi

input=$(read_input "ApiKey" "$api_key")
if [[ -n "$input" ]]; then
    yq -i ".Nodes[0].ApiConfig.ApiKey = \"$input\"" "$CONFIG_FILE"
fi

input=$(read_input "NodeID" "$node_id")
if [[ -n "$input" ]]; then
    yq -i ".Nodes[0].ApiConfig.NodeID = $input" "$CONFIG_FILE"
fi

input=$(read_input "NodeType (vmess/trojan/shadowsocks/shadowsocks2022)" "$node_type")
if [[ -n "$input" ]]; then
    yq -i ".Nodes[0].ApiConfig.NodeType = \"$input\"" "$CONFIG_FILE"
fi

input=$(read_input "CertMode (none/file/http/tls/dns)" "$cert_mode")
if [[ -n "$input" ]]; then
    yq -i ".Nodes[0].ControllerConfig.CertConfig.CertMode = \"$input\"" "$CONFIG_FILE"
fi

if [[ "$input" != "none" ]]; then
    # 申请证书（certbot）
    cert_domain=$(read_input "请输入 CertDomain" "$(yq '.Nodes[0].ControllerConfig.CertConfig.CertDomain // ""' "$CONFIG_FILE")")
    if [[ -n "$cert_domain" ]]; then
        certbot certonly --standalone -d "$cert_domain" --agree-tos -m your_email@example.com --non-interactive
        cert_file="/etc/letsencrypt/live/$cert_domain/fullchain.pem"
        key_file="/etc/letsencrypt/live/$cert_domain/privkey.pem"
        yq -i ".Nodes[0].ControllerConfig.CertConfig.CertFile = \"$cert_file\"" "$CONFIG_FILE"
        yq -i ".Nodes[0].ControllerConfig.CertConfig.KeyFile = \"$key_file\"" "$CONFIG_FILE"

        # 添加 crontab 续期，每 2 个月一次，不重启 next-server
        (crontab -l 2>/dev/null; echo "0 0 1 */2 * certbot renew --quiet") | crontab -
    fi
fi

echo "配置已更新: $CONFIG_FILE"

# 创建 systemd 服务
SERVICE_FILE="/etc/systemd/system/next-server.service"

cat > $SERVICE_FILE <<EOF
[Unit]
Description=Next-Server Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/next-server -c $CONFIG_FILE
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd
systemctl daemon-reload
systemctl enable next-server
systemctl start next-server
systemctl status next-server
echo "Next-Server 服务已启动并设置开机自启"
