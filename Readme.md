# VietBot AI v3.0 - Hướng Dẫn Sử Dụng & Khắc Phục Lỗi

## 📋 MỤC LỤC
1. [Tính Năng Mới v3.0](#tính-năng-mới-v30)
2. [Hướng Dẫn Triển Khai](#hướng-dẫn-triển-khai)
3. [Quản Lý Ảnh Sản Phẩm](#quản-lý-ảnh-sản-phẩm)
4. [Workflow với Hỗ Trợ Ảnh](#workflow-với-hỗ-trợ-ảnh)
5. [Các Lệnh Quản Lý Hệ Thống](#các-lệnh-quản-lý-hệ-thống)
6. [Khắc Phục Lỗi Phổ Biến](#khắc-phục-lỗi-phổ-biến)
7. [Giám Sát & Bảo Trì](#giám-sát--bảo-trì)
8. [Backup & Phục Hồi](#backup--phục-hồi)

---

## 🚀 TÍNH NĂNG MỚI V3.0

### Hỗ Trợ Ảnh Toàn Diện
- **📸 Nhận ảnh**: Từ Facebook Messenger
- **🤖 Phân tích ảnh**: Claude Vision API
- **🏪 Gửi ảnh sản phẩm**: Tự động cho khách hàng
- **💾 Lưu trữ**: Database ảnh có sẵn

### Full n8n Features
- **⭐ Evaluations tab**: Giống VPS cũ
- **🤖 AI features**: Đầy đủ
- **📊 Version Control**: Git integration
- **🔧 Templates**: Community templates
- **📈 Metrics**: Performance tracking

### Kiến Trúc Mới
```
Facebook Messenger → n8n Webhook → Claude Vision → Product Images → Response
                                      ↓
                              Static Files (Caddy)
```

---

## 🛠️ HƯỚNG DẪN TRIỂN KHAI

### Triển Khai VPS Mới
```bash
# SSH vào VPS mới
ssh root@IP_VPS_MỚI

# Tạo và chạy script
nano deploy_vietbot_v3.sh
# Copy nội dung từ artifact đầu tiên
chmod +x deploy_vietbot_v3.sh
./deploy_vietbot_v3.sh
```

### Nhập Thông Tin
```
Domain: vietbot.ntvn8n.xyz
```

### Quá Trình Tự Động
1. **Cài đặt Docker & dependencies**
2. **Tạo thư mục dự án + images**
3. **Cấu hình environment variables đầy đủ**
4. **Tạo ảnh demo sản phẩm**
5. **Setup Caddy với static files**
6. **Khởi động containers**
7. **Test images serving**

---

## 📸 QUẢN LÝ ẢNH SẢN PHẨM

### Thư Mục Images
```bash
cd /opt/vietbot/images
ls -la
# nhan_sam_han_quoc.jpg
# dong_trung_ha_thao.jpg
# linh_chi_do.jpg
# toi_den_ly_son.jpg
# mat_ong_rung.jpg
```

### Upload Ảnh Mới
```bash
# Upload qua SCP
scp product_image.jpg root@IP:/opt/vietbot/images/

# Hoặc wget từ URL
cd /opt/vietbot/images
wget -O new_product.jpg "https://example.com/image.jpg"

# Set permissions
chmod 644 *.jpg
```

### Định Dạng Ảnh Chuẩn
- **Format**: JPG/PNG
- **Size**: < 2MB recommend
- **Naming**: snake_case.jpg
- **URL**: https://domain.com/images/filename.jpg

### Test Images URLs
```bash
cd /opt/vietbot
./test_images.sh

# Manual test
curl -I https://domain.com/images/nhan_sam_han_quoc.jpg
```

---

## 🔧 WORKFLOW VỚI HỖ TRỢ ẢNH

### Luồng Xử Lý Mới
1. **Webhook** nhận tin nhắn (text + attachments)
2. **Message Router** phân loại text/image
3. **Image Downloader** tải ảnh từ Facebook
4. **Claude Vision** phân tích ảnh + tư vấn
5. **Product Decision** quyết định gửi ảnh sản phẩm
6. **Send Response** + product image

### Workflow JSON Structure
```json
{
  "nodes": [
    "Webhook",
    "Message Parser", 
    "Message Type Router",
    "Image Downloader",
    "Claude Vision Analyzer", 
    "Product Image Decision",
    "Send Product Image",
    "Send Text Response"
  ]
}
```

### Environment Variables Quan Trọng
```bash
# Trong docker-compose.yml
- N8N_AI_ENABLED=true
- N8N_EVALUATIONS_ENABLED=true
- N8N_FEATURES_ENABLED=ai,evaluations,workflows,github
- VUE_APP_URL_BASE_API=https://domain/
```

### Claude Vision Setup
```javascript
// Trong workflow node
model: "claude-3-5-sonnet-20241022"
systemMessage: "Bạn là chuyên gia phân tích ảnh thuốc nam..."
```

---

## 🛠️ CÁC LỆNH QUẢN LÝ HỆ THỐNG

### Scripts Có Sẵn v3.0
```bash
cd /opt/vietbot

# Giám sát hệ thống + images
./giam_sat.sh

# Test images serving
./test_images.sh

# Backup đầy đủ (bao gồm images)
./sao_luu.sh

# Cập nhật hệ thống
./cap_nhat.sh
```

### Quản Lý Containers
```bash
# Xem trạng thái
docker-compose ps

# Logs realtime
docker-compose logs -f

# Restart specific service
docker-compose restart n8n
docker-compose restart caddy

# Rebuild containers
docker-compose down
docker-compose up -d --force-recreate
```

### Quản Lý Images
```bash
# List all images
ls -la /opt/vietbot/images/

# Check image sizes
du -h /opt/vietbot/images/*

# Test image access
for img in $(ls /opt/vietbot/images/); do
  curl -I https://domain.com/images/$img
done
```

---

## 🔧 KHẮC PHỤC LỖI PHỔ BIẾN

### 1. Lỗi Images Không Load

**Triệu chứng:** 404 khi truy cập https://domain/images/file.jpg

**Giải pháp:**
```bash
# Kiểm tra file tồn tại
ls -la /opt/vietbot/images/

# Kiểm tra Caddy config
cat /opt/vietbot/Caddyfile

# Kiểm tra Caddy mount
docker-compose exec caddy ls -la /opt/vietbot/images/

# Restart Caddy
docker-compose restart caddy
```

### 2. Claude Vision Không Hoạt Động

**Triệu chứng:** Workflow không phân tích ảnh

**Giải pháp:**
```bash
# Kiểm tra Claude credentials
docker-compose exec n8n env | grep ANTHROPIC

# Kiểm tra workflow connections
# Đảm bảo Redis Memory connect to Image AI Analyzer

# Test Claude API
curl -H "x-api-key: YOUR_KEY" https://api.anthropic.com/v1/models
```

### 3. Evaluations Tab Không Xuất Hiện

**Triệu chứng:** Không có ⭐ Evaluations tab

**Giải pháp:**
```bash
# Kiểm tra environment variables
docker-compose exec n8n env | grep EVALUATIONS
docker-compose exec n8n env | grep VUE_APP

# Restart n8n
docker-compose restart n8n

# Clear browser cache
# Ctrl+Shift+R để hard refresh
```

### 4. Facebook Webhook Không Nhận Ảnh

**Triệu chứng:** Chỉ nhận text, không nhận attachments

**Giải pháp:**
```bash
# Kiểm tra webhook logs
docker-compose logs n8n | grep facebook

# Kiểm tra Message Parser code
# Đảm bảo có xử lý entry.message.attachments

# Test webhook manually
curl -X POST https://domain/webhook/facebook-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### 5. Lỗi SSL Certificate cho Images

**Triệu chứng:** HTTPS cert error khi load images

**Giải pháp:**
```bash
# Kiểm tra Caddy SSL
docker-compose logs caddy | grep certificate

# Restart Caddy để renew
docker-compose restart caddy

# Test SSL cho images path
curl -I https://domain/images/test.jpg
```

---

## 📊 GIÁM SÁT & BẢO TRÌ

### Health Check Script v3.0
```bash
#!/bin/bash
cd /opt/vietbot

echo "=== VietBot v3.0 Health Check $(date) ==="

# Check containers
echo "🐳 Containers:"
docker-compose ps

# Check images serving
echo "📸 Images serving:"
./test_images.sh

# Check disk space (images folder)
echo "💾 Disk usage:"
du -h /opt/vietbot/images/
df -h /opt/vietbot

# Check n8n features
echo "🤖 n8n features:"
curl -s http://localhost:5678/healthz

# Check recent executions
echo "📊 Recent activity:"
docker-compose logs --tail=10 n8n | grep -E "(execution|workflow)"
```

### Monitoring Images
```bash
# Monitor image access logs
docker-compose logs caddy | grep "/images/"

# Track image storage usage
watch du -h /opt/vietbot/images/

# Monitor bandwidth usage
nethogs  # Install: apt install nethogs
```

---

## 💾 BACKUP & PHỤC HỒI

### Backup v3.0 (Bao Gồm Images)
```bash
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="/opt/vietbot/backups/full_backup_$BACKUP_DATE"

mkdir -p $BACKUP_ROOT

# Backup database
docker-compose exec -T postgres pg_dump -U vietbot vietbot_ai > $BACKUP_ROOT/database.sql

# Backup n8n data
docker run --rm -v vietbot_n8n_data:/data -v $BACKUP_ROOT:/backup alpine tar czf /backup/n8n_data.tar.gz -C /data .

# Backup images (MỚI)
tar -czf $BACKUP_ROOT/images.tar.gz -C /opt/vietbot/images .

# Backup configurations
cp -r /opt/vietbot/*.yml /opt/vietbot/*.env /opt/vietbot/Caddyfile $BACKUP_ROOT/

echo "✅ Backup v3.0 completed: $BACKUP_ROOT"
```

### Restore Images
```bash
#!/bin/bash
BACKUP_DIR="/path/to/backup"

# Restore images
cd /opt/vietbot
tar -xzf $BACKUP_DIR/images.tar.gz -C ./images/

# Set permissions
chmod 644 /opt/vietbot/images/*

# Test images
./test_images.sh

echo "✅ Images restored"
```

### Scheduled Backup với Images
```bash
# Crontab entry
0 2 * * * /opt/vietbot/sao_luu.sh >> /var/log/vietbot_backup.log 2>&1

# Weekly image cleanup (remove unused)
0 3 * * 0 find /opt/vietbot/images -name "*.jpg" -atime +30 -delete
```

---

## 🔄 WORKFLOW IMPORT & SETUP

### Import Workflow v3.0
1. **Vào n8n**: https://domain.com
2. **Tạo workflow mới**
3. **Import JSON** từ artifact
4. **Connect Redis Memory** to Image AI Analyzer
5. **Setup Claude credentials**
6. **Test với ảnh**

### Test Workflow Steps
```bash
# 1. Test text message
curl -X POST https://domain/webhook/facebook-webhook

# 2. Test image processing
# Gửi ảnh qua Facebook Messenger

# 3. Check execution logs
docker-compose logs n8n | grep execution

# 4. Verify image response
# Kiểm tra bot có gửi ảnh sản phẩm không
```

### Workflow Troubleshooting
```bash
# Check workflow status
curl http://localhost:5678/rest/workflows

# Check executions
curl http://localhost:5678/rest/executions

# Debug specific node
docker-compose logs n8n | grep "Image.*Analyzer"
```

---

## 📞 HỖ TRỢ & DEBUG

### Debug Images Issues
```bash
# Test image serving
curl -v https://domain/images/test.jpg

# Check Caddy config
docker-compose exec caddy cat /etc/caddy/Caddyfile

# Check file permissions
ls -la /opt/vietbot/images/

# Check container mounts
docker inspect vietbot_caddy | grep -A 10 "Mounts"
```

### Debug Workflow Issues  
```bash
# Check Claude Vision
docker-compose logs n8n | grep -i "vision\|claude\|image"

# Check webhook data
docker-compose logs n8n | grep -i "attachment\|facebook"

# Monitor executions
watch docker-compose logs --tail=5 n8n
```

### Performance Optimization
```bash
# Optimize images
cd /opt/vietbot/images
for img in *.jpg; do
  jpegoptim --size=500k "$img"
done

# Monitor memory usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Clean old executions
docker-compose exec postgres psql -U vietbot vietbot_ai -c \
  "DELETE FROM execution_entity WHERE startedAt < NOW() - INTERVAL '7 days';"
```

---

## 🎯 NEXT STEPS

### Sau Khi Deploy Thành Công
1. **✅ Test basic workflow** với text
2. **✅ Upload ảnh sản phẩm thật**  
3. **✅ Test image workflow** với Facebook
4. **✅ Monitor performance**
5. **✅ Setup regular backups**

### Production Checklist
- [ ] SSL certificates working
- [ ] Images serving correctly  
- [ ] Webhook receiving attachments
- [ ] Claude Vision analyzing images
- [ ] Product images sending to customers
- [ ] Backup system running
- [ ] Monitoring in place

---

**📌 Lưu ý:** VietBot v3.0 là bản nâng cấp quan trọng với đầy đủ tính năng xử lý ảnh và tất cả features như VPS cũ!
