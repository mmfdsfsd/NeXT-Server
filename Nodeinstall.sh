#!/bin/bash

# 安装依赖
apt update && apt install ca-certificates wget curl unzip tar supervisor git certbot jq -y

# 克隆仓库（可选）
git clone https://github.com/mmfdsfsd/ServerStatus.git

# 创建工作目录
mkdir -p /root/next-server-linux-amd64
cd /root/next-server-linux-amd64 || exit 1

# 检测 CPU 类型
CPU_VENDOR=$(awk -F: '/vendor_id/ {gsub(/ /,"",$2); print tolower($2); exit}' /proc/cpuinfo)

echo "检测到 CPU 厂商: $CPU_VENDOR"

if [[ "$CPU_VENDOR" == "intel" ]]; then
    ZIP_URL="https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.19/next-server-linux-amd64.zip"
elif [[ "$CPU_VENDOR" == "amd" ]]; then
    ZIP_URL="https://github.com/mmfdsfsd/NeXT-Server/releases/download/0.3.19/next-server-linux-amd64v3.zip"
else
    echo "无法识别 CPU 厂商，默认使用 Intel 版本"
    ZIP_URL="https://github.com/The-NeXT-Project/NeXT-Server/releases/download/v0.3.19/next-server-linux-amd64.zip"
fi

echo "将下载: $ZIP_URL"

# 下载并解压
wget -q -N --no-check-certificate "$ZIP_URL" -O next-server.zip
unzip -o next-server.zip
rm -f next-server.zip

# 下载 geosite.dat
rm -f geosite.dat
wget -q -N --no-check-certificate -c https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O geosite.dat

chmod +x next-server

CONFIG_FILE="/root/next-server-linux-amd64/config.json"

# 确保 jq 已安装
if ! command -v jq &>/dev/null; then
    echo "请先安装 jq，例如: sudo apt install jq -y"
    exit 1
fi

# 交互输入函数
read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# 读取原值
route=$(jq -r '.RouteConfigPath // ""' "$CONFIG_FILE")
outbound=$(jq -r '.OutboundConfigPath // ""' "$CONFIG_FILE")
api_host=$(jq -r '.Nodes[0].ApiConfig.ApiHost // ""' "$CONFIG_FILE")
api_key=$(jq -r '.Nodes[0].ApiConfig.ApiKey // ""' "$CONFIG_FILE")
node_id=$(jq -r '.Nodes[0].ApiConfig.NodeID // 1' "$CONFIG_FILE")
node_type=$(jq -r '.Nodes[0].ApiConfig.NodeType // "vmess"' "$CONFIG_FILE")
cert_mode=$(jq -r '.Nodes[0].ControllerConfig.CertConfig.CertMode // "none"' "$CONFIG_FILE")
cert_file=$(jq -r '.Nodes[0].ControllerConfig.CertConfig.CertFile // ""' "$CONFIG_FILE")
key_file=$(jq -r '.Nodes[0].ControllerConfig.CertConfig.KeyFile // ""' "$CONFIG_FILE")

# 提示用户输入
route=$(read_input "请输入 RouteConfigPath" "$route")
outbound=$(read_input "请输入 OutboundConfigPath" "$outbound")
api_host=$(read_input "请输入 ApiHost" "$api_host")
api_key=$(read_input "请输入 ApiKey" "$api_key")
node_id=$(read_input "请输入 NodeID" "$node_id")
node_type=$(read_input "请输入 NodeType (vmess/trojan/shadowsocks/shadowsocks2022)" "$node_type")
cert_mode=$(read_input "请输入 CertMode (none/file/http/tls/dns)" "$cert_mode")
cert_file=$(read_input "请输入 CertFile" "$cert_file")
key_file=$(read_input "请输入 KeyFile" "$key_file")

# 更新 JSON
tmpfile=$(mktemp)
jq \
--arg route "$route" \
--arg outbound "$outbound" \
--arg api_host "$api_host" \
--arg api_key "$api_key" \
--argjson node_id "$node_id" \
--arg node_type "$node_type" \
--arg cert_mode "$cert_mode" \
--arg cert_file "$cert_file" \
--arg key_file "$key_file" \
'.RouteConfigPath = $route |
 .OutboundConfigPath = $outbound |
 .Nodes[0].ApiConfig.ApiHost = $api_host |
 .Nodes[0].ApiConfig.ApiKey = $api_key |
 .Nodes[0].ApiConfig.NodeID = $node_id |
 .Nodes[0].ApiConfig.NodeType = $node_type |
 .Nodes[0].ControllerConfig.CertConfig.CertMode = $cert_mode |
 .Nodes[0].ControllerConfig.CertConfig.CertFile = $cert_file |
 .Nodes[0].ControllerConfig.CertConfig.KeyFile = $key_file' \
"$CONFIG_FILE" > "$tmpfile" && mv "$tmpfile" "$CONFIG_FILE"

echo "配置已更新: $CONFIG_FILE"

# 创建 systemd 服务
SERVICE_FILE="/etc/systemd/system/next-server.service"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=NeXT Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/next-server-linux-amd64
ExecStart=/root/next-server-linux-amd64/next-server -c /root/next-server-linux-amd64/config.json
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable next-server
systemctl start next-server

echo "NeXT-Server 服务已创建并启动"
echo "管理服务命令: systemctl status/stop/restart next-server"