# VietBot v3.2 - Hướng Dẫn Sử Dụng & Khắc Phục Lỗi

## 📋 MỤC LỤC
1. [Tính Năng v3.2](#tính-năng-v32)
2. [Hướng Dẫn Triển Khai](#hướng-dẫn-triển-khai)
3. [Quản Lý Database & Redis](#quản-lý-database--redis)
4. [Workflow Facebook Messenger](#workflow-facebook-messenger)
5. [Monitoring & Logs](#monitoring--logs)
6. [Các Lệnh Quản Lý](#các-lệnh-quản-lý)
7. [Khắc Phục Lỗi Phổ Biến](#khắc-phục-lỗi-phổ-biến)
8. [Backup & Bảo Trì](#backup--bảo-trì)

---

## 🚀 TÍNH NĂNG V3.2

### Core Features
- **🤖 N8N AI + Evaluations**: Full AI features enabled
- **⚡ Redis Integration**: Message correlation & caching
- **🗄️ PostgreSQL**: Production database với schemas hoàn chỉnh
- **🌐 Caddy HTTPS**: Auto SSL certificates
- **📊 Logging Interface**: Debug logs working trong N8N

### VietBot Business Logic
- **💊 Thuốc Nam Chatbot**: Catalog sản phẩm, tư vấn, đặt hàng
- **📱 Facebook Messenger**: Time-window correlation cho text + image
- **🖼️ Image Upload**: Xử lý ảnh từ user, lưu vào uploads/
- **👥 User Management**: Quản lý khách hàng và admin
- **📋 Order Processing**: Xử lý đơn hàng tự động

### Technical Architecture
```
Internet → Caddy (SSL) → Docker Network
                              ↓
N8N ←→ PostgreSQL ←→ Redis
 ↕         ↕         ↕
Static Files (Images/Uploads)
```

---

## 🛠️ HƯỚNG DẪN TRIỂN KHAI

### Chuẩn Bị VPS
```bash
# Yêu cầu tối thiểu:
- CPU: 2+ cores
- RAM: 4GB+ (khuyến nghị 8GB)
- Storage: 50GB+
- OS: Ubuntu 20.04+
- Domain: Đã point DNS về VPS
```

### Triển Khai One-Command
```bash
# SSH vào VPS
ssh root@your-vps-ip

# Tải script deployment v3.2
wget https://your-domain.com/deploy_vietbot_v3.2.sh
chmod +x deploy_vietbot_v3.2.sh

# Chạy deployment
./deploy_vietbot_v3.2.sh
```

### Interactive Setup
Script chỉ hỏi thông tin cần thiết:

```
📍 Nhập domain: bot.yourdomain.com
```

### Quá Trình Tự Động (10-15 phút)
1. **Cài đặt Docker + dependencies**
2. **Generate secure passwords**
3. **Tạo database schemas thuốc nam**
4. **Setup SSL với Caddy**
5. **Khởi động containers (5 services)**
6. **Health checks & verification**

### Kết Quả Sau Deploy
```
🌐 URL Website:     https://bot.yourdomain.com
👤 Email Admin:     admin@yourdomain.com
🔐 Mật khẩu Admin:  [auto-generated]
📁 Project Dir:     /opt/vietbot
💾 Credentials:     /opt/vietbot/config/credentials.txt
```

---

## 📁 CẤU TRÚC THƯ MỤC

### Directory Layout
```bash
/opt/vietbot/
├── config/           # Database configs & credentials
├── scripts/          # Management scripts
├── images/           # Static product images  
├── uploads/          # User uploads
├── workflows/        # N8N workflow templates
├── logs/             # Application logs
├── backups/          # Automated backups
├── docker-compose.yml
├── Caddyfile
└── .env
```

### Generated Files
```bash
# Auto-generated credentials
config/credentials.txt
config/init-database.sql

# SSL certificates (auto-managed)
caddy_data/certificates/

# Persistent data volumes
/var/lib/docker/volumes/vietbot_*
```

---

## 🗄️ QUẢN LÝ DATABASE & REDIS

### PostgreSQL Administration
```bash
# Connect database
cd /opt/vietbot
docker-compose exec postgres psql -U vietbot -d vietbot_ai

# View schemas
\dn

# View tables
\dt vietbot.*

# Check table data
SELECT COUNT(*) FROM vietbot.products;
SELECT * FROM vietbot.users LIMIT 5;
```

### VietBot Database Schema
```sql
-- Core tables
vietbot.users              -- Facebook users
vietbot.conversations      -- Chat sessions  
vietbot.messages           -- All messages
vietbot.message_correlation -- Time-window correlation
vietbot.products           -- Thuốc nam catalog (5 demo items)
vietbot.orders             -- Customer orders
vietbot.file_uploads       -- Image uploads
vietbot.admins             -- Admin users (24304743935797555)
```

### Redis Operations
```bash
# Connect Redis (no password in v3.2)
docker-compose exec redis redis-cli

# Check memory usage
INFO memory

# View correlation keys
KEYS correlation:*

# Monitor commands
MONITOR

# Check if key exists
EXISTS user_session_123
```

### Database Maintenance
```bash
# Manual backup
docker-compose exec postgres pg_dump -U vietbot vietbot_ai > backup_$(date +%Y%m%d).sql

# Restore backup
docker-compose exec -T postgres psql -U vietbot vietbot_ai < backup_file.sql

# Cleanup old correlations
docker-compose exec postgres psql -U vietbot -d vietbot_ai -c "
DELETE FROM vietbot.message_correlation WHERE expires_at < NOW();
"
```

---

## ⚙️ WORKFLOW FACEBOOK MESSENGER

### N8N Credential Setup
```bash
# Access N8N
https://your-domain.com

# Required credentials:
1. PostgreSQL: 
   - Host: postgres
   - Port: 5432
   - Database: vietbot_ai
   - User: vietbot
   - Password: [from credentials.txt]

2. Redis:
   - Host: vietbot_redis  
   - Port: 6379
   - Password: [EMPTY - no password]
   - Database: 0

3. Facebook Page:
   - Page Token: [from Facebook App]
   - Verify Token: vietbot2025verify
   - App Secret: [from Facebook App]
```

### Import Workflow Template
```bash
# Template có sẵn
workflows/facebook-webhook-handler.json

# Import steps:
1. Login N8N
2. Click "+" → "Import from file"  
3. Select facebook-webhook-handler.json
4. Configure credentials
5. Activate workflow
```

### Facebook Webhook Configuration
```bash
# Webhook URL
https://your-domain.com/webhook/facebook-webhook

# Verify Token
vietbot2025verify

# Events to subscribe:
- messages
- messaging_postbacks
```

### Time-Window Message Correlation
```javascript
// Logic trong workflow
const correlationWindow = 3000; // 3 seconds
const windowStart = Math.floor(timestamp / correlationWindow) * correlationWindow;
const correlationKey = `${sender_id}_${windowStart}`;

// Detect mixed messages (text + image)
if (hasText && hasImage) {
  return { messageType: 'mixed_upload', ... };
}
```

### Claude AI Integration
```javascript
// Environment variables trong N8N
CLAUDE_API_KEY=sk-ant-xxx...

// API call structure
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1000,
  "messages": [{
    "role": "user",
    "content": "Phân tích triệu chứng và tư vấn thuốc nam phù hợp: " + userMessage
  }]
}
```

---

## 📊 MONITORING & LOGS

### N8N Logs Interface
```bash
# Access logs trong N8N UI
1. Login https://your-domain.com
2. Click "Executions" tab
3. View execution history với debug info
4. Filter by status (success/error/running)
```

### System Logs
```bash
cd /opt/vietbot

# View logs theo service
./scripts/logs.sh n8n        # N8N logs
./scripts/logs.sh postgres   # Database logs
./scripts/logs.sh redis      # Redis logs
./scripts/logs.sh caddy      # SSL/proxy logs
./scripts/logs.sh all        # All services
./scripts/logs.sh tail       # Recent activity
```

### Health Monitoring
```bash
# System health check
./scripts/health-check.sh

# Output example:
📦 Docker Services: All containers Up
✅ N8N: Healthy (HTTP 200)
✅ PostgreSQL: Connected  
✅ Redis: Connected
📊 Memory: 2.1G/7.8G
📊 Disk: 15G/98G (16% used)
🔗 N8N: https://domain.com
🔗 Images: https://domain.com/images/
🔗 Uploads: https://domain.com/uploads/
```

### Performance Monitoring
```bash
# Monitor system resources
watch docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Database activity
docker-compose exec postgres psql -U vietbot -d vietbot_ai -c "
SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';
"

# Redis memory usage  
docker-compose exec redis redis-cli info memory | grep used_memory_human
```

---

## 🛠️ CÁC LỆNH QUẢN LÝ

### Container Management
```bash
cd /opt/vietbot

# View all services
docker-compose ps

# Restart specific service
docker-compose restart n8n
docker-compose restart postgres
docker-compose restart caddy

# Restart all services
docker-compose restart

# Stop/start all
docker-compose down
docker-compose up -d

# View resource usage
docker stats
```

### SSL & Domain Management
```bash
# Check SSL status
curl -I https://your-domain.com

# View Caddy logs for SSL issues
docker-compose logs caddy | grep -i certificate

# Force SSL renewal (if needed)
docker-compose restart caddy

# Check certificate expiry
echo | openssl s_client -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -dates
```

### File Management
```bash
# Upload demo images
ls images/
# san-pham-thuoc-nam-1.jpg
# san-pham-thuoc-nam-2.jpg  
# san-pham-thuoc-nam-3.jpg
# san-pham-thuoc-nam-4.jpg
# san-pham-thuoc-nam-5.jpg

# User uploads (from Facebook)
ls uploads/
# user_images/
# processed_files/

# Access via URL
https://domain.com/images/san-pham-thuoc-nam-1.jpg
https://domain.com/uploads/user_image_123.jpg
```

---

## 🔧 KHẮC PHỤC LỖI PHỔ BIẾN

### 1. N8N Không Khởi Động

**Triệu chứng:** Container n8n restart liên tục

**Kiểm tra:**
```bash
docker-compose logs n8n

# Common issues:
# - Database connection failed
# - Redis connection failed  
# - Port 5678 conflicts
# - Memory insufficient
```

**Giải pháp:**
```bash
# Restart database first
docker-compose restart postgres
sleep 10
docker-compose restart n8n

# Check encryption key
cat config/credentials.txt

# Free memory if needed
docker system prune -f
```

### 2. Redis Connection Failed

**Triệu chứng:** N8N credential test fails

**Kiểm tra:**
```bash
# Test Redis từ N8N container
docker exec -it vietbot_n8n ping vietbot_redis
docker exec -it vietbot_n8n telnet vietbot_redis 6379

# Test Redis directly
docker exec -it vietbot_redis redis-cli ping
```

**Giải pháp:**
```bash
# Restart Redis
docker-compose restart redis

# Use IP instead of hostname trong credential:
docker inspect vietbot_redis | grep IPAddress
# Host: 172.18.0.X
# Password: [EMPTY]
```

### 3. Facebook Webhook Issues

**Triệu chứng:** Facebook không verify webhook

**Kiểm tra:**
```bash
# Test webhook URL
curl -X GET "https://domain.com/webhook/facebook-webhook?hub.verify_token=vietbot2025verify&hub.challenge=test&hub.mode=subscribe"

# Should return: test
```

**Giải pháp:**
```bash
# Check SSL certificate
curl -I https://domain.com

# Restart Caddy if SSL issues
docker-compose restart caddy

# Wait for SSL generation (2-5 minutes)
```

### 4. Database Connection Issues

**Triệu chứng:** N8N database credential fails

**Kiểm tra:**
```bash
# Test database connection
docker-compose exec postgres psql -U vietbot -d vietbot_ai -c "SELECT version();"

# Check database credentials
cat config/credentials.txt
```

**Giải pháp:**
```bash
# Reset database connection
docker-compose restart postgres
sleep 30
docker-compose restart n8n

# Check if database exists
docker-compose exec postgres psql -U vietbot -l
```

### 5. SSL Certificate Issues

**Triệu chứng:** HTTPS không hoạt động

**Kiểm tra:**
```bash
# Check Caddy logs
docker-compose logs caddy | grep -i error

# Test domain resolution
nslookup your-domain.com
```

**Giải pháp:**
```bash
# Remove old certificates
docker volume rm vietbot_caddy_data
docker-compose restart caddy

# Wait for certificate generation
watch curl -I https://your-domain.com
```

### 6. Image Upload Issues

**Triệu chứng:** Images không accessible

**Kiểm tra:**
```bash
# Test image URL
curl -I https://domain.com/images/san-pham-thuoc-nam-1.jpg

# Check file permissions
ls -la images/
ls -la uploads/
```

**Giải pháp:**
```bash
# Fix permissions
chmod 755 images/ uploads/
chmod 644 images/*.jpg
chmod 644 uploads/*.jpg

# Restart Caddy
docker-compose restart caddy
```

---

## 💾 BACKUP & BẢO TRÌ

### Automated Backup
```bash
# Script có sẵn
cd /opt/vietbot
./scripts/backup.sh

# Output:
🔄 Starting backup: backup_20250702_173000
📊 Backing up PostgreSQL...
⚡ Backing up Redis... 
⚙️ Backing up N8N...
🖼️ Backing up Images...
📋 Backing up Configuration...
✅ Backup completed!
📁 Files created: backup_20250702_173000_complete.tar.gz
```

### Manual Backup Components
```bash
# Database only
docker-compose exec postgres pg_dump -U vietbot vietbot_ai > db_backup.sql

# N8N workflows & settings
tar -czf n8n_backup.tar.gz -C /var/lib/docker/volumes/vietbot_n8n_data/_data .

# Images & uploads
tar -czf files_backup.tar.gz images/ uploads/

# Configuration
tar -czf config_backup.tar.gz docker-compose.yml .env Caddyfile config/
```

### Restore from Backup
```bash
# Stop services
docker-compose down

# Restore database
gunzip < db_backup.sql.gz | docker-compose exec -T postgres psql -U vietbot vietbot_ai

# Restore N8N
tar -xzf n8n_backup.tar.gz -C /var/lib/docker/volumes/vietbot_n8n_data/_data/

# Restore files
tar -xzf files_backup.tar.gz

# Start services
docker-compose up -d
```

### Scheduled Maintenance
```bash
# Setup cron jobs
crontab -e

# Daily backup at 2 AM
0 2 * * * cd /opt/vietbot && ./scripts/backup.sh >> logs/backup.log 2>&1

# Weekly health check 
0 9 * * 1 cd /opt/vietbot && ./scripts/health-check.sh >> logs/health-weekly.log 2>&1

# Monthly cleanup old backups
0 1 1 * * find /opt/vietbot/backups -name "*.tar.gz" -mtime +30 -delete
```

### Database Optimization
```bash
# Monthly database maintenance
docker-compose exec postgres psql -U vietbot -d vietbot_ai -c "
VACUUM ANALYZE;
REINDEX DATABASE vietbot_ai;
"

# Cleanup old message correlations
docker-compose exec postgres psql -U vietbot -d vietbot_ai -c "
DELETE FROM vietbot.message_correlation WHERE created_at < NOW() - INTERVAL '7 days';
"

# Check database size
docker-compose exec postgres psql -U vietbot -d vietbot_ai -c "
SELECT pg_size_pretty(pg_database_size('vietbot_ai'));
"
```

---

## 🎯 PRODUCTION CHECKLIST

### Sau Deploy Thành Công
- [ ] ✅ Login N8N và complete setup wizard
- [ ] ✅ Import Facebook webhook workflow
- [ ] ✅ Configure Facebook App webhook URL
- [ ] ✅ Add Claude API key vào environment 
- [ ] ✅ Test end-to-end với Facebook message
- [ ] ✅ Verify image uploads working
- [ ] ✅ Check database có data từ demo products
- [ ] ✅ Setup monitoring alerts (optional)

### Security Checklist
- [ ] ✅ Change default N8N admin password
- [ ] ✅ Update Facebook App Secret
- [ ] ✅ Secure Claude API key
- [ ] ✅ Enable firewall (ports 22, 80, 443 only)
- [ ] ✅ Setup SSL auto-renewal
- [ ] ✅ Regular backup verification

### Performance Optimization
- [ ] Monitor CPU/Memory usage với `docker stats`
- [ ] Optimize database queries nếu cần
- [ ] Setup Redis TTL cho cache keys
- [ ] Configure log rotation
- [ ] Monitor disk space usage

---

## 📞 HỖ TRỢ & NEXT STEPS

### Business Customization
1. **Sửa demo products** trong database theo sản phẩm thật
2. **Custom workflow logic** cho business rules cụ thể
3. **Thêm payment integration** (Stripe, VNPay, etc.)
4. **Setup admin dashboard** cho quản lý orders
5. **Mobile app integration** nếu có

### Technical Enhancement
1. **Add more AI providers** (OpenAI, Gemini)
2. **Multi-language support** cho responses
3. **Voice message support** 
4. **Video consultation booking**
5. **Analytics dashboard** với business metrics

### Team Training
1. **N8N workflow development** 
2. **Database query optimization**
3. **Monitoring và troubleshooting**
4. **Backup & disaster recovery**
5. **Security best practices**

---

**📌 Lưu ý:** VietBot v3.2 là stable production framework với tất cả features cần thiết cho chatbot thuốc nam. Framework có thể easily customize cho any business vertical khác!
