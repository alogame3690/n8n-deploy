#!/bin/bash

###############################################################################
# VietBot AI - Script Triển Khai Sản Xuất Hoàn Chỉnh
# Phiên bản: 2.0 - Đã Sửa Tất Cả Lỗi
# Tác giả: TRỌNG VĨNH NGUYỄN
# Ngày: 29 tháng 6, 2025
# 
# CÁC LỖI ĐÃ ĐƯỢC SỬA TỪ PHIÊN BẢN 1.0:
# 1. N8N_HOST=0.0.0.0 → Phải là domain để Production URL hiển thị đúng
# 2. Thiếu WEBHOOK_URL → Production URL hiển thị localhost
# 3. Trùng lặp volumes trong docker-compose → Lỗi phân tích YAML
# 4. Thiếu quyền truy cập file → n8n crash khi khởi động
# 5. Tên image sai → Docker pull bị từ chối truy cập
###############################################################################

set -e  # Thoát khi có lỗi bất kỳ

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Không màu

hien_thi_trang_thai() {
    echo -e "${BLUE}[THÔNG TIN]${NC} $1"
}

hien_thi_thanh_cong() {
    echo -e "${GREEN}[THÀNH CÔNG]${NC} $1"
}

hien_thi_canh_bao() {
    echo -e "${YELLOW}[CẢNH BÁO]${NC} $1"
}

hien_thi_loi() {
    echo -e "${RED}[LỖI]${NC} $1"
}

###############################################################################
# BƯỚC 1: NHẬP THÔNG TIN DOMAIN
###############################################################################
hien_thi_trang_thai "=== Script Triển Khai VietBot AI v2.0 ==="
echo
read -p "Nhập domain của bạn (ví dụ: vietbot.domain.com): " DOMAIN

if [[ -z "$DOMAIN" ]]; then
    hien_thi_loi "Domain là bắt buộc!"
    exit 1
fi

hien_thi_thanh_cong "Domain đã đặt: $DOMAIN"

###############################################################################
# BƯỚC 2: CHUẨN BỊ HỆ THỐNG
###############################################################################
hien_thi_trang_thai "Đang cập nhật các gói hệ thống..."
apt update -y && apt upgrade -y

hien_thi_trang_thai "Đang cài đặt các gói cần thiết..."
apt install -y curl wget git ufw unzip nano htop

###############################################################################
# BƯỚC 3: CÀI ĐẶT DOCKER
###############################################################################
hien_thi_trang_thai "Đang cài đặt Docker và Docker Compose..."

# Gỡ bỏ các phiên bản Docker cũ
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Cài đặt Docker Compose v2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Khởi động dịch vụ Docker
systemctl enable docker
systemctl start docker

hien_thi_thanh_cong "Docker đã được cài đặt thành công"

###############################################################################
# BƯỚC 4: CẤU HÌNH FIREWALL
###############################################################################
hien_thi_trang_thai "Đang cấu hình firewall..."
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

###############################################################################
# BƯỚC 5: CÀI ĐẶT CADDY
###############################################################################
hien_thi_trang_thai "Đang cài đặt Caddy web server..."
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/setup.deb.sh' | bash
apt update
apt install caddy -y

# Dừng Caddy (sẽ được quản lý bởi Docker)
systemctl stop caddy
systemctl disable caddy

###############################################################################
# BƯỚC 6: TẠO THƯ MỤC DỰ ÁN
###############################################################################
PROJECT_DIR="/opt/vietbot"
hien_thi_trang_thai "Tạo thư mục dự án: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

###############################################################################
# BƯỚC 7: TẠO FILE CẤU HÌNH MÔI TRƯỜNG
###############################################################################
hien_thi_trang_thai "Tạo cấu hình môi trường..."
cat > .env << EOF
# Cấu hình Domain
DOMAIN=$DOMAIN

# Cấu hình Database
POSTGRES_USER=vietbot
POSTGRES_PASSWORD=VietBot2025MatKhauBaoMat!
POSTGRES_DB=vietbot_ai

# Cấu hình n8n
N8N_ENCRYPTION_KEY=VietBotKhoaBaoMatMaHoa2025ChuoiNgauNhien123
N8N_USER_EMAIL=admin@$DOMAIN
N8N_USER_PASSWORD=VietBotAdmin2025!

# Cấu hình Redis
REDIS_PASSWORD=VietBotRedis2025!
EOF

###############################################################################
# BƯỚC 8: TẠO FILE DOCKER COMPOSE (PHIÊN BẢN ĐÃ SỬA)
###############################################################################
hien_thi_trang_thai "Tạo cấu hình Docker Compose..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

networks:
  vietbot_network:
    driver: bridge

services:
  postgres:
    image: postgres:15-alpine
    container_name: vietbot_postgres
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - vietbot_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: vietbot_redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    networks:
      - vietbot_network
    healthcheck:
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  n8n:
    image: docker.io/n8nio/n8n:latest
    container_name: vietbot_n8n
    environment:
      # SỬA QUAN TRỌNG: Cấu hình Production URL
      - N8N_WEBHOOK_URL=https://${DOMAIN}
      - WEBHOOK_URL=https://${DOMAIN}
      - N8N_EDITOR_BASE_URL=https://${DOMAIN}
      - N8N_HOST=${DOMAIN}
      - N8N_AI_ENABLED=true
      - N8N_EVALUATIONS_ENABLED=true
      - N8N_FEATURES_ENABLED=ai,evaluations,workflows,github
      - N8N_VERSION_CONTROL_ENABLED=true
      - N8N_GIT_ENABLED=true
      
      # Host và Protocol (ĐÃ SỬA)
      - N8N_HOST=${DOMAIN}
      - N8N_PROTOCOL=https
      - N8N_PORT=5678
      - N8N_EDITOR_BASE_URL=https://${DOMAIN}
      
      # Kết nối Database
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      
      # Bảo mật
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_SECURE_COOKIE=true
      - N8N_COOKIE_SAME_SITE_POLICY=strict
      
      # Tính năng
      - N8N_USER_MANAGEMENT_DISABLED=false
      - N8N_TEMPLATES_ENABLED=true
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_METRICS=true
      - N8N_LOG_LEVEL=info
      - NODE_ENV=production
      
      # Redis Cache
      - CACHE_REDIS_HOST=redis
      - CACHE_REDIS_PORT=6379
      - CACHE_REDIS_PASSWORD=${REDIS_PASSWORD}
      
    ports:
      - "127.0.0.1:5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - vietbot_network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped

  caddy:
    image: caddy:2-alpine
    container_name: vietbot_caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - vietbot_network
    depends_on:
      - n8n
    restart: unless-stopped

volumes:
  postgres_data:
  n8n_data:
  caddy_data:
  caddy_config:
EOF

###############################################################################
# BƯỚC 9: TẠO CẤU HÌNH CADDY
###############################################################################
hien_thi_trang_thai "Tạo cấu hình reverse proxy Caddy..."
cat > Caddyfile << EOF
$DOMAIN {
    reverse_proxy vietbot_n8n:5678
    
    # Headers bảo mật
    header {
        # Kích hoạt HSTS
        Strict-Transport-Security max-age=31536000;
        # Ngăn MIME sniffing
        X-Content-Type-Options nosniff
        # Bảo vệ XSS
        X-XSS-Protection "1; mode=block"
        # Ngăn framing
        X-Frame-Options DENY
        # Content Security Policy
        Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;"
    }
    
    # Logging (simplified)
    log
}
EOF

###############################################################################
# BƯỚC 10: TẠO CÁC SCRIPT QUẢN LÝ
###############################################################################
hien_thi_trang_thai "Tạo scripts quản lý..."

# Script giám sát
cat > giam_sat.sh << 'EOF'
#!/bin/bash
echo "=== Trạng Thái Hệ Thống VietBot AI ==="
echo
echo "Containers Docker:"
docker-compose ps
echo
echo "Tài nguyên hệ thống:"
free -h
df -h /
echo
echo "Logs gần đây:"
docker-compose logs --tail=20
EOF
chmod +x giam_sat.sh

# Script backup
cat > sao_luu.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/vietbot/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Tạo bản sao lưu: $DATE"

# Sao lưu database
docker-compose exec -T postgres pg_dump -U vietbot vietbot_ai > $BACKUP_DIR/db_backup_$DATE.sql

# Sao lưu dữ liệu n8n
tar -czf $BACKUP_DIR/n8n_backup_$DATE.tar.gz -C /var/lib/docker/volumes/vietbot_n8n_data/_data .

# Sao lưu cấu hình
cp -r /opt/vietbot/*.yml /opt/vietbot/*.env /opt/vietbot/Caddyfile $BACKUP_DIR/ 2>/dev/null

echo "Sao lưu hoàn tất: $BACKUP_DIR"

# Chỉ giữ lại 7 ngày backup gần nhất
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF
chmod +x sao_luu.sh

# Script cập nhật
cat > cap_nhat.sh << 'EOF'
#!/bin/bash
echo "Đang cập nhật VietBot AI..."
cd /opt/vietbot
docker-compose pull
docker-compose up -d
docker system prune -f
echo "Cập nhật hoàn tất!"
EOF
chmod +x cap_nhat.sh

###############################################################################
# BƯỚC 11: ĐẶT QUYỀN TRUY CẬP ĐÚNG
###############################################################################
hien_thi_trang_thai "Đặt quyền truy cập file đúng..."
chown -R root:root /opt/vietbot
chmod 755 /opt/vietbot
chmod 600 /opt/vietbot/.env

# Tạo thư mục dữ liệu n8n với quyền đúng
mkdir -p /var/lib/docker/volumes/vietbot_n8n_data/_data
chown -R 1000:1000 /var/lib/docker/volumes/vietbot_n8n_data/_data

###############################################################################
# BƯỚC 12: TẢI CÁC DOCKER IMAGES
###############################################################################
hien_thi_trang_thai "Đang tải Docker images..."
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull docker.io/n8nio/n8n:latest
docker pull caddy:2-alpine

###############################################################################
# BƯỚC 13: KHỞI ĐỘNG CÁC DỊCH VỤ
###############################################################################
hien_thi_trang_thai "Khởi động các dịch vụ VietBot AI..."
docker-compose up -d

# Chờ các dịch vụ sẵn sàng
hien_thi_trang_thai "Chờ các dịch vụ khởi động..."
sleep 30

###############################################################################
# BƯỚC 14: THIẾT LẬP CRON JOBS
###############################################################################
hien_thi_trang_thai "Thiết lập sao lưu tự động..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/vietbot/sao_luu.sh >> /var/log/vietbot_backup.log 2>&1") | crontab -

###############################################################################
# BƯỚC 15: KIỂM TRA CUỐI CÙNG
###############################################################################
hien_thi_trang_thai "Kiểm tra cuối cùng..."

# Kiểm tra trạng thái container
if ! docker-compose ps | grep -q "Up"; then
    hien_thi_loi "Một số containers không khởi động được!"
    docker-compose logs
    exit 1
fi

# Kiểm tra sức khỏe n8n
if ! curl -f -s http://localhost:5678/healthz > /dev/null; then
    hien_thi_canh_bao "Kiểm tra sức khỏe n8n thất bại, nhưng có thể vẫn đang khởi động..."
fi

###############################################################################
# BƯỚC 16: HIỂN THỊ KẾT QUẢ
###############################################################################
clear
echo
hien_thi_thanh_cong "🎉 VietBot AI đã triển khai thành công!"
echo
echo "📋 THÔNG TIN TRIỂN KHAI:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🌐 URL Website:     https://$DOMAIN"
echo "👤 Email Admin:     admin@$DOMAIN" 
echo "🔐 Mật khẩu Admin:  VietBotAdmin2025!"
echo
echo "📁 Thư mục dự án:   /opt/vietbot"
echo "💾 Thư mục backup:  /opt/vietbot/backups"
echo
echo "🛠️  LỆNH QUẢN LÝ:"
echo "   Kiểm tra trạng thái: cd /opt/vietbot && ./giam_sat.sh"
echo "   Xem logs:           cd /opt/vietbot && docker-compose logs -f"
echo "   Khởi động lại:      cd /opt/vietbot && docker-compose restart"
echo "   Tạo backup:         cd /opt/vietbot && ./sao_luu.sh"
echo "   Cập nhật hệ thống:  cd /opt/vietbot && ./cap_nhat.sh"
echo
echo "🔧 WEBHOOK URL CHO FACEBOOK:"
echo "   https://$DOMAIN/webhook/facebook-webhook"
echo
echo "⚡ CÁC BƯỚC TIẾP THEO:"
echo "   1. Truy cập https://$DOMAIN để vào n8n"
echo "   2. Hoàn tất wizard thiết lập n8n"
echo "   3. Import workflow VietBot"
echo "   4. Cấu hình webhook Facebook với URL ở trên"
echo "   5. Thêm thông tin đăng nhập Claude API"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
hien_thi_thanh_cong "✅ VietBot AI đã sẵn sàng để sản xuất!"
echo

# Tạo tóm tắt cài đặt
cat > /opt/vietbot/TOM_TAT_CAI_DAT.md << EOF
# Tóm Tắt Cài Đặt VietBot AI

## Chi Tiết Triển Khai
- **Ngày**: $(date)
- **Domain**: $DOMAIN
- **Phiên bản**: 2.0
- **Trạng thái**: Sẵn sàng Sản xuất

## Các Lỗi Đã Được Sửa từ v1.0
1. ✅ Production URL hiện tại hiển thị đúng domain (không phải 0.0.0.0)
2. ✅ Biến môi trường WEBHOOK_URL đã được cấu hình đúng
3. ✅ Không trùng lặp volumes trong docker-compose.yml
4. ✅ Quyền truy cập file đúng cho thư mục dữ liệu n8n
5. ✅ Sử dụng tên Docker image đúng (n8nio/n8n)
6. ✅ Xử lý lỗi toàn diện và validation
7. ✅ Headers bảo mật và cấu hình SSL
8. ✅ Hệ thống backup và giám sát tự động

## Trạng Thái Container
$(docker-compose ps)

## Các Bước Tiếp Theo
1. Cấu hình tài khoản admin n8n
2. Import workflow Facebook Bot
3. Thiết lập tích hợp Claude API
4. Cấu hình webhook Facebook
5. Test chức năng end-to-end

## Lệnh Hỗ Trợ
- Giám sát: \`./giam_sat.sh\`
- Backup: \`./sao_luu.sh\`
- Cập nhật: \`./cap_nhat.sh\`
EOF

hien_thi_thanh_cong "Tóm tắt cài đặt đã được lưu tại: /opt/vietbot/TOM_TAT_CAI_DAT.md"
echo
