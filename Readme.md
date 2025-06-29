# VietBot AI - Hướng Dẫn Sử Dụng & Khắc Phục Lỗi

## 📋 MỤC LỤC
1. [Hướng Dẫn Sử Dụng Cơ Bản](#hướng-dẫn-sử-dụng-cơ-bản)
2. [Các Lệnh Quản Lý Hệ Thống](#các-lệnh-quản-lý-hệ-thống)
3. [Khắc Phục Lỗi Phổ Biến](#khắc-phục-lỗi-phổ-biến)
4. [Giám Sát & Bảo Trì](#giám-sát--bảo-trì)
5. [Backup & Phục Hồi](#backup--phục-hồi)
6. [Tối Ưu Hóa Hiệu Suất](#tối-ưu-hóa-hiệu-suất)

---

## 🚀 HƯỚNG DẪN SỬ DỤNG CỠ BẢN

### Truy Cập Hệ Thống
```bash
# SSH vào server
ssh root@IP_SERVER

# Di chuyển đến thư mục dự án
cd /opt/vietbot
```

### Kiểm Tra Trạng Thái
```bash
# Xem trạng thái tất cả containers
docker-compose ps

# Xem logs realtime
docker-compose logs -f

# Kiểm tra tài nguyên hệ thống
./giam_sat.sh
```

### Quản Lý Dịch Vụ
```bash
# Khởi động tất cả dịch vụ
docker-compose up -d

# Dừng tất cả dịch vụ
docker-compose down

# Khởi động lại dịch vụ cụ thể
docker-compose restart n8n
docker-compose restart postgres
docker-compose restart caddy
```

---

## 🛠️ CÁC LỆNH QUẢN LÝ HỆ THỐNG

### Scripts Quản Lý Có Sẵn
```bash
# Kiểm tra trạng thái hệ thống
./giam_sat.sh

# Tạo backup
./sao_luu.sh

# Cập nhật hệ thống
./cap_nhat.sh
```

### Quản Lý Docker
```bash
# Xem logs của container cụ thể
docker-compose logs -f n8n
docker-compose logs -f postgres
docker-compose logs -f caddy

# Exec vào container
docker-compose exec n8n /bin/sh
docker-compose exec postgres psql -U vietbot vietbot_ai

# Xóa containers và tạo lại
docker-compose down
docker-compose up -d --force-recreate
```

### Quản Lý Database
```bash
# Kết nối database
docker-compose exec postgres psql -U vietbot vietbot_ai

# Backup database manual
docker-compose exec postgres pg_dump -U vietbot vietbot_ai > backup_$(date +%Y%m%d).sql

# Restore database
docker-compose exec -T postgres psql -U vietbot vietbot_ai < backup_file.sql
```

---

## 🔧 KHẮC PHỤC LỖI PHỔ BIẾN

### 1. Lỗi Production URL Hiển Thị Sai

**Triệu chứng:** Production URL hiển thị `https://0.0.0.0:5678/webhook/...`

**Nguyên nhân:** Thiếu cấu hình WEBHOOK_URL

**Giải pháp:**
```bash
# Kiểm tra file .env
cat .env | grep DOMAIN

# Kiểm tra docker-compose.yml có đúng cấu hình không
grep WEBHOOK_URL docker-compose.yml

# Restart n8n để apply config mới
docker-compose restart n8n
```

### 2. Lỗi Container Không Khởi Động

**Triệu chứng:** `docker-compose ps` hiển thị Exit hoặc Unhealthy

**Giải pháp:**
```bash
# Xem logs chi tiết
docker-compose logs CONTAINER_NAME

# Kiểm tra port conflicts
netstat -tulpn | grep :5678
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Fix permissions
chown -R 1000:1000 /var/lib/docker/volumes/vietbot_n8n_data/_data

# Restart container
docker-compose restart CONTAINER_NAME
```

### 3. Lỗi SSL Certificate

**Triệu chứng:** Website hiển thị "Not Secure" hoặc SSL error

**Giải pháp:**
```bash
# Kiểm tra Caddy logs
docker-compose logs caddy

# Restart Caddy để renew SSL
docker-compose restart caddy

# Kiểm tra DNS pointing
nslookup YOUR_DOMAIN

# Test SSL manually
curl -I https://YOUR_DOMAIN
```

### 4. Lỗi Database Connection

**Triệu chứng:** n8n không kết nối được database

**Giải pháp:**
```bash
# Kiểm tra postgres health
docker-compose ps postgres

# Test database connection
docker-compose exec postgres pg_isready -U vietbot

# Kiểm tra environment variables
docker-compose exec n8n env | grep DB_

# Restart database
docker-compose restart postgres n8n
```

### 5. Lỗi Out of Memory

**Triệu chứng:** Containers bị kill, OOMKilled

**Giải pháp:**
```bash
# Kiểm tra memory usage
free -h
docker stats

# Restart containers để clear memory
docker-compose restart

# Thêm swap nếu cần
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### 6. Lỗi Disk Full

**Triệu chứng:** "No space left on device"

**Giải pháp:**
```bash
# Kiểm tra disk usage
df -h

# Dọn dẹp Docker
docker system prune -f
docker volume prune -f

# Dọn dẹp logs
docker-compose logs > /dev/null
truncate -s 0 /var/log/syslog

# Xóa backups cũ
find /opt/vietbot/backups -mtime +7 -delete
```

---

## 📊 GIÁM SÁT & BẢO TRÌ

### Giám Sát Hàng Ngày
```bash
# Script kiểm tra tự động
#!/bin/bash
cd /opt/vietbot

echo "=== VietBot Health Check $(date) ==="

# Check containers
if ! docker-compose ps | grep -q "Up.*healthy"; then
    echo "❌ Container unhealthy"
    docker-compose ps
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "⚠️ Disk usage high: ${DISK_USAGE}%"
fi

# Check memory
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
if [ $MEM_USAGE -gt 85 ]; then
    echo "⚠️ Memory usage high: ${MEM_USAGE}%"
fi

# Check n8n health
if ! curl -f -s http://localhost:5678/healthz > /dev/null; then
    echo "❌ n8n health check failed"
fi

echo "✅ Health check completed"
```

### Cron Jobs Tự Động
```bash
# Thêm vào crontab
crontab -e

# Health check mỗi 15 phút
*/15 * * * * /opt/vietbot/health_check.sh >> /var/log/vietbot_health.log 2>&1

# Backup hàng ngày lúc 2h sáng
0 2 * * * /opt/vietbot/sao_luu.sh >> /var/log/vietbot_backup.log 2>&1

# Clean up logs hàng tuần
0 3 * * 0 find /var/log -name "*.log" -mtime +7 -delete

# Update system hàng tháng
0 4 1 * * /opt/vietbot/cap_nhat.sh >> /var/log/vietbot_update.log 2>&1
```

---

## 💾 BACKUP & PHỤC HỒI

### Backup Hoàn Chỉnh
```bash
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="/opt/vietbot/backups/full_backup_$BACKUP_DATE"

mkdir -p $BACKUP_ROOT

# Backup database
docker-compose exec -T postgres pg_dump -U vietbot vietbot_ai > $BACKUP_ROOT/database.sql

# Backup n8n data
docker run --rm -v vietbot_n8n_data:/data -v $BACKUP_ROOT:/backup alpine tar czf /backup/n8n_data.tar.gz -C /data .

# Backup configurations
cp -r /opt/vietbot/*.yml /opt/vietbot/*.env /opt/vietbot/Caddyfile $BACKUP_ROOT/

# Backup Docker volumes
docker run --rm -v vietbot_caddy_data:/data -v $BACKUP_ROOT:/backup alpine tar czf /backup/caddy_data.tar.gz -C /data .

echo "Full backup completed: $BACKUP_ROOT"
```

### Phục Hồi Từ Backup
```bash
#!/bin/bash
BACKUP_DIR="/opt/vietbot/backups/full_backup_YYYYMMDD_HHMMSS"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Stop services
docker-compose down

# Restore database
docker-compose up -d postgres
sleep 10
docker-compose exec -T postgres psql -U vietbot vietbot_ai < $BACKUP_DIR/database.sql

# Restore n8n data
docker run --rm -v vietbot_n8n_data:/data -v $BACKUP_DIR:/backup alpine sh -c "cd /data && tar xzf /backup/n8n_data.tar.gz"

# Restore configurations
cp $BACKUP_DIR/*.yml $BACKUP_DIR/*.env $BACKUP_DIR/Caddyfile /opt/vietbot/

# Start all services
docker-compose up -d

echo "Restore completed from: $BACKUP_DIR"
```

---

## ⚡ TỐI ỦU HÓA HIỆU SUẤT

### Cấu Hình n8n
```bash
# Thêm vào docker-compose.yml environment section
- N8N_EXECUTIONS_TIMEOUT=300
- N8N_EXECUTIONS_TIMEOUT_MAX=600
- N8N_EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
- N8N_EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=false
- N8N_LOG_LEVEL=warn
```

### Tối Ưu Database
```sql
-- Kết nối database
docker-compose exec postgres psql -U vietbot vietbot_ai

-- Analyze tables
ANALYZE;

-- Reindex
REINDEX DATABASE vietbot_ai;

-- Clean old executions
DELETE FROM execution_entity WHERE "startedAt" < NOW() - INTERVAL '30 days';
```

### Tối Ưu Hệ Thống
```bash
# Tăng file descriptors
echo "fs.file-max = 65536" >> /etc/sysctl.conf

# Tối ưu TCP
echo "net.core.somaxconn = 65536" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65536" >> /etc/sysctl.conf

# Apply changes
sysctl -p

# Tối ưu Docker
echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' > /etc/docker/daemon.json
systemctl restart docker
```

---

## 📞 HỖ TRỢ & LIÊN HỆ

### Logs Quan Trọng
```bash
# n8n logs
docker-compose logs n8n | tail -100

# Database logs
docker-compose logs postgres | tail -100

# Caddy/SSL logs
docker-compose logs caddy | tail -100

# System logs
tail -100 /var/log/syslog
```

### Thông Tin Debug
```bash
# Thu thập thông tin debug
#!/bin/bash
echo "=== VietBot Debug Info ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo

echo "=== Container Status ==="
docker-compose ps
echo

echo "=== Resource Usage ==="
free -h
df -h
echo

echo "=== Network ==="
netstat -tulpn | grep -E "(5678|80|443)"
echo

echo "=== Recent Logs ==="
docker-compose logs --tail=50
```

### Liên Hệ Hỗ Trợ
- **Issues**: Tạo issue với thông tin debug
- **Emergency**: Sử dụng script health_check.sh
- **Performance**: Chạy script debug info

---

## 🔄 CẬP NHẬT HỆ THỐNG

### Cập Nhật Thường Xuyên
```bash
# Update Docker images
docker-compose pull

# Recreate containers with new images
docker-compose up -d --force-recreate

# Clean old images
docker image prune -f
```

### Backup Trước Khi Cập Nhật
```bash
# Luôn backup trước khi update
./sao_luu.sh

# Kiểm tra backup thành công
ls -la /opt/vietbot/backups/

# Sau đó mới update
./cap_nhat.sh
```

---

**📌 Lưu ý:** Luôn test các thay đổi trên môi trường development trước khi apply lên production!
