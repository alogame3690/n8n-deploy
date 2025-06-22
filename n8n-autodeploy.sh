#!/bin/bash

# Cập nhật và cài Docker + Docker Compose + tiện ích cần thiết
apt update && apt install -y docker.io docker-compose unzip curl

# Tải file zip từ GitHub
curl -L https://github.com/alogame3690/n8n-deploy/raw/main/n8n-deploy-package-github.zip -o n8n.zip

# Giải nén
unzip n8n.zip

# Chạy script chính
bash deploy.sh
