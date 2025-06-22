#!/bin/bash
set -e

# Gỡ chặn firewall nếu cần
ufw allow 5678 || true
ufw reload || true

# Cập nhật và cài Docker nếu chưa có
apt update -y
apt install -y docker.io docker-compose unzip curl

# Tạo thư mục nếu chưa có
mkdir -p /n8n_data

# Tải gói triển khai từ GitHub hoặc URL cố định nếu cần
curl -L -o n8n.zip http://103.172.179.11/files/n8n-deploy-package.zip
unzip -o n8n.zip

# Cấp quyền cho script khởi động
chmod +x deploy.sh

# Khởi động hệ thống
./deploy.sh
