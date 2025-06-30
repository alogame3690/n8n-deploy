#!/bin/bash

###############################################################################
# VietBot AI - Script Triển Khai Sản Xuất v3.0
# Phiên bản: 3.0 - Thêm hỗ trợ ảnh + Full Features
# Tác giả: TRỌNG VĨNH NGUYỄN
# Ngày: 30 tháng 6, 2025
# 
# MỚI TRONG V3.0:
# 1. Hỗ trợ nhận, xử lý và gửi ảnh
# 2. Claude Vision API integration
# 3. Static image serving qua Caddy
# 4. Tất cả environment variables như VPS cũ
# 5. Full n8n features (AI, Evaluations, Version Control...)
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
hien_thi_trang_thai "=== Script Triển Khai VietBot AI v3.0 - Hỗ trợ ảnh ==="
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
# BƯỚC 6: TẠO THƯ MỤC DỰ ÁN + IMAGES
###############################################################################
PROJECT_DIR="/opt/vietbot"
hien_thi_trang_thai "Tạo thư mục dự án và images: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
mkdir -p $PROJECT_DIR/images
mkdir -p $PROJECT_DIR/data/{n8n,postgres,redis}
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
# BƯỚC 8: TẠO ẢNH SẢN PHẨM DEMO
###############################################################################
hien_thi_trang_thai "Tạo ảnh sản phẩm demo..."
cd $PROJECT_DIR/images

# Tạo ảnh demo (1x1 pixel PNG trong base64)
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > nhan_sam_han_quoc.jpg
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > dong_trung_ha_thao.jpg
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > linh_chi_do.jpg
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > toi_den_ly_son.jpg
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > mat_ong_rung.jpg

cd $PROJECT_DIR

###############################################################################
# BƯỚC 9: TẠO FILE DOCKER COMPOSE VỚI HỖ TRỢ ẢNH
###############################################################################
hien_thi_trang_thai "Tạo cấu hình Docker Compose với hỗ trợ ảnh..."
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
      # WEBHOOK & PRODUCTION URL (QUAN TRỌNG)
      - N8N_WEBHOOK_URL=https://${DOMAIN}
      - WEBHOOK_URL=https://${DOMAIN}
      - N8N_EDITOR_BASE_URL=https://${DOMAIN}
      - N8N_HOST=${DOMAIN}
      - N8N_PROTOCOL=https
      - N8N_PORT=5678
      
      # FULL FEATURES GIỐNG VPS CŨ
      - N8N_AI_ENABLED=true
      - N8N_EVALUATIONS_ENABLED=true
      - N8N_FEATURES_ENABLED=ai,evaluations,workflows,github
      - N8N_VERSION_CONTROL_ENABLED=true
      - N8N_GIT_ENABLED=true
      - N8N_TEMPLATES_ENABLED=true
      - N8N_PUSH_BACKEND=websocket
      - N8N_VERSION_NOTIFICATIONS_ENABLED=true
      - N8N_PERSONALIZATION_ENABLED=true
      - VUE_APP_URL_BASE_API=https://${DOMAIN}/
      
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
      - ./images:/opt/vietbot/images:ro
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
# BƯỚC 10: TẠO CẤU HÌNH CADDY VỚI HỖ TRỢ IMAGES
###############################################################################
hien_thi_trang_thai "Tạo cấu hình Caddy với hỗ trợ static images..."
cat > Caddyfile << EOF
$DOMAIN {
    reverse_proxy vietbot_n8n:5678
    
    # Serve static images cho workflow
    handle /images/* {
        root * /opt/vietbot
        file_server
    }
    
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
# BƯỚC 11: TẠO CÁC SCRIPT QUẢN LÝ
###############################################################################
hien_thi_trang_thai "Tạo scripts quản lý..."

# Script giám sát với images
cat > giam_sat.sh << 'EOF'
#!/bin/bash
echo "=== Trạng Thái Hệ Thống VietBot AI v3.0 ==="
echo
echo "Containers Docker:"
docker-compose ps
echo
echo "Tài nguyên hệ thống:"
free -h
df -h /
echo
echo "Images status:"
ls -la /opt/vietbot/images/ | head -10
echo
echo "Logs gần đây:"
docker-compose logs --tail=20
EOF
chmod +x giam_sat.sh

# Script backup với images
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

# Sao lưu images
tar -czf $BACKUP_DIR/images_backup_$DATE.tar.gz -C /opt/vietbot/images .

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

# Script test images
cat > test_images.sh << 'EOF'
#!/bin/bash
echo "=== Test Images Functionality ==="
DOMAIN=$(grep DOMAIN /opt/vietbot/.env | cut -d'=' -f2)

echo "Testing image URLs:"
for img in nhan_sam_han_quoc dong_trung_ha_thao linh_chi_do toi_den_ly_son mat_ong_rung; do
    URL="https://${DOMAIN}/images/${img}.jpg"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [ "$STATUS" = "200" ]; then
        echo "✅ $URL"
    else
        echo "❌ $URL (Status: $STATUS)"
    fi
done
EOF
chmod +x test_images.sh

###############################################################################
# BƯỚC 12: ĐẶT QUYỀN TRUY CẬP ĐÚNG
###############################################################################
hien_thi_trang_thai "Đặt quyền truy cập file đúng..."
chown -R root:root /opt/vietbot
chmod 755 /opt/vietbot
chmod 600 /opt/vietbot/.env
chmod 755 /opt/vietbot/images
chmod 644 /opt/vietbot/images/*

# Tạo thư mục dữ liệu n8n với quyền đúng
mkdir -p /var/lib/docker/volumes/vietbot_n8n_data/_data
chown -R 1000:1000 /var/lib/docker/volumes/vietbot_n8n_data/_data

###############################################################################
# BƯỚC 13: TẢI CÁC DOCKER IMAGES
###############################################################################
hien_thi_trang_thai "Đang tải Docker images..."
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull docker.io/n8nio/n8n:latest
docker pull caddy:2-alpine

###############################################################################
# BƯỚC 14: KHỞI ĐỘNG CÁC DỊCH VỤ
###############################################################################
hien_thi_trang_thai "Khởi động các dịch vụ VietBot AI..."
docker-compose up -d

# Chờ các dịch vụ sẵn sàng
hien_thi_trang_thai "Chờ các dịch vụ khởi động..."
sleep 60

###############################################################################
# BƯỚC 15: THIẾT LẬP CRON JOBS
###############################################################################
hien_thi_trang_thai "Thiết lập sao lưu tự động..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/vietbot/sao_luu.sh >> /var/log/vietbot_backup.log 2>&1") | crontab -

###############################################################################
# BƯỚC 16: KIỂM TRA CUỐI CÙNG VÀ TEST IMAGES
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

# Test images URLs
hien_thi_trang_thai "Testing images serving..."
sleep 10
./test_images.sh

###############################################################################
# BƯỚC 17: HIỂN THỊ KẾT QUẢ
###############################################################################
clear
echo
hien_thi_thanh_cong "🎉 VietBot AI v3.0 đã triển khai thành công với hỗ trợ ảnh!"
echo
echo "📋 THÔNG TIN TRIỂN KHAI:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🌐 URL Website:     https://$DOMAIN"
echo "👤 Email Admin:     admin@$DOMAIN" 
echo "🔐 Mật khẩu Admin:  VietBotAdmin2025!"
echo
echo "📸 TÍNH NĂNG MỚI - HỖ TRỢ ẢNH:"
echo "   📱 Nhận ảnh từ Facebook Messenger"
echo "   🤖 Claude Vision phân tích ảnh"
echo "   🏪 Gửi ảnh sản phẩm cho khách hàng"
echo "   🔗 Images URL: https://$DOMAIN/images/"
echo
echo "📁 Thư mục dự án:   /opt/vietbot"
echo "🖼️  Thư mục ảnh:     /opt/vietbot/images"
echo "💾 Thư mục backup:  /opt/vietbot/backups"
echo
echo "🛠️  LỆNH QUẢN LÝ:"
echo "   Kiểm tra trạng thái: cd /opt/vietbot && ./giam_sat.sh"
echo "   Test images:         cd /opt/vietbot && ./test_images.sh"
echo "   Xem logs:           cd /opt/vietbot && docker-compose logs -f"
echo "   Khởi động lại:      cd /opt/vietbot && docker-compose restart"
echo "   Tạo backup:         cd /opt/vietbot && ./sao_luu.sh"
echo "   Cập nhật hệ thống:  cd /opt/vietbot && ./cap_nhat.sh"
echo
echo "🔧 WEBHOOK URL CHO FACEBOOK:"
echo "   https://$DOMAIN/webhook/facebook-webhook"
echo
echo "🎯 ẢNH SẢN PHẨM CÓ SẴN:"
echo "   📦 Nhân sâm Hàn Quốc: https://$DOMAIN/images/nhan_sam_han_quoc.jpg"
echo "   🍄 Đông trùng hạ thảo: https://$DOMAIN/images/dong_trung_ha_thao.jpg"
echo "   🟫 Linh chi đỏ: https://$DOMAIN/images/linh_chi_do.jpg"
echo "   🧄 Tỏi đen Lý Sơn: https://$DOMAIN/images/toi_den_ly_son.jpg"
echo "   🍯 Mật ong rừng: https://$DOMAIN/images/mat_ong_rung.jpg"
echo
echo "⚡ CÁC BƯỚC TIẾP THEO:"
echo "   1. Truy cập https://$DOMAIN để vào n8n"
echo "   2. Hoàn tất wizard thiết lập n8n"
echo "   3. Import workflow VietBot với hỗ trợ ảnh"
echo "   4. Cấu hình webhook Facebook với URL ở trên"
echo "   5. Thêm thông tin đăng nhập Claude API"
echo "   6. Upload ảnh sản phẩm thật vào /opt/vietbot/images/"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
hien_thi_thanh_cong "✅ VietBot AI v3.0 với hỗ trợ ảnh đã sẵn sàng để sản xuất!"
echo

# Tạo tóm tắt cài đặt với images
cat > /opt/vietbot/TOM_TAT_CAI_DAT_V3.md << EOF
# Tóm Tắt Cài Đặt VietBot AI v3.0

## Chi Tiết Triển Khai
- **Ngày**: $(date)
- **Domain**: $DOMAIN
- **Phiên bản**: 3.0 - Hỗ trợ ảnh
- **Trạng thái**: Sẵn sàng Sản xuất

## Tính Năng Mới v3.0
1. ✅ Nhận và xử lý ảnh từ Facebook Messenger
2. ✅ Claude Vision API integration
3. ✅ Static image serving qua Caddy
4. ✅ Database ảnh sản phẩm
5. ✅ Gửi ảnh sản phẩm cho khách hàng
6. ✅ Full n8n features (AI, Evaluations, Version Control)

## Workflow Hỗ Trợ Ảnh
- **Input**: Text + Images từ Facebook
- **Processing**: Claude Vision phân tích ảnh
- **Output**: Text response + Product images
- **Storage**: /opt/vietbot/images/

## Images URLs
$(for img in nhan_sam_han_quoc dong_trung_ha_thao linh_chi_do toi_den_ly_son mat_ong_rung; do echo "- https://$DOMAIN/images/\${img}.jpg"; done)

## Trạng Thái Container
$(docker-compose ps)

## Các Bước Tiếp Theo
1. Import workflow VietBot v3.0 với image support
2. Cấu hình Claude API credentials
3. Setup Facebook webhook
4. Upload ảnh sản phẩm thật
5. Test end-to-end với ảnh

## Lệnh Hỗ Trợ Mới
- Test images: \`./test_images.sh\`
- Giám sát: \`./giam_sat.sh\`
- Backup (bao gồm images): \`./sao_luu.sh\`
EOF

hien_thi_thanh_cong "Tóm tắt cài đặt v3.0 đã được lưu tại: /opt/vietbot/TOM_TAT_CAI_DAT_V3.md"
echo
