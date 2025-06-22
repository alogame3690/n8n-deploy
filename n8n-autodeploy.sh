#!/bin/bash
set -e

echo "[1/6] Cập nhật hệ thống..."
apt update -y && apt upgrade -y

echo "[2/6] Cài đặt gói cần thiết..."
apt install -y docker.io docker-compose curl unzip

echo "[3/6] Tạo thư mục làm việc cho n8n..."
mkdir -p /n8n_data && cd /n8n_data

echo "[4/6] Tải docker-compose.yml mới nhất..."
curl -L https://raw.githubusercontent.com/alogame3690/n8n-deploy/main/docker-compose.yml -o docker-compose.yml

echo "[5/6] Khởi tạo hệ thống n8n..."
docker compose up -d

echo "[6/6] Mở firewall nếu cần..."
ufw allow 5678 || true
ufw reload || true

echo "✅ Cài đặt hoàn tất. Truy cập: http://<YOUR-IP>:5678 để bắt đầu dùng n8n."
