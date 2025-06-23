#!/bin/bash

### ========================
### ⚙️ Auto Deploy n8n - Bản mới nhất (latest)
### Author: Vinh Trọng Nguyễn
### Version: v1.0 - 2025-06-23
### ========================

## === Bước 1: Nhập DOMAIN ===
echo "\n== Nhập domain của bạn (VD: test.ntvn8n.xyz) =="
read -p "DOMAIN: " DOMAIN

if [ -z "$DOMAIN" ]; then
  echo "\n❌ Thiếu domain. Hãy chạy lại script và nhập tên domain."
  exit 1
fi

## === Bước 2: Cài đặt Docker + Caddy ===
echo "\n== Đang cài đặt Docker, Docker Compose, Caddy =="
apt update && apt install -y docker.io curl unzip ufw
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# Caddy
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian all main" > /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install caddy -y

## === Bước 3: Mở port firewall ===
ufw allow 80
ufw allow 443
ufw --force enable

## === Bước 4: Tạo Caddyfile ===
echo "\n== Tạo file Caddy config... =="
cat <<EOF > /etc/caddy/Caddyfile
$DOMAIN {
  reverse_proxy 127.0.0.1:5678
}
EOF

## === Bước 5: Khởi động n8n ===
echo "\n== Tạo và chạy container n8n với Docker (latest) =="
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e N8N_EDITOR_BASE_URL="https://$DOMAIN" \
  -v ~/.n8n:/home/node/.n8n \
  n8n/n8n:latest

## === Bước 6: Restart Caddy để cấp SSL ===
echo "\n== Khởi động lại Caddy để cấp SSL =="
systemctl restart caddy
sleep 5

## === Bước 7: Kiểm tra truy cập ===
echo "\n✅ Hoàn tất! Hãy mở trình duyệt và truy cập: https://$DOMAIN"
echo "\nNếu bị lỗi ERR_SSL_PROTOCOL_ERROR, có thể do vượt giới hạn cấp SSL của Let's Encrypt trong 168h qua."
echo "\nGiải pháp: đổi subdomain khác hoặc chờ hết thời gian chọn."
