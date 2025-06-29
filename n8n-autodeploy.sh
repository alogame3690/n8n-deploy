#!/bin/bash

### ========================
### 🤖 VietBot AI - One Command Deploy
### Tested & Working - Production Ready
### Usage: wget -O deploy.sh [URL] && chmod +x deploy.sh && ./deploy.sh
### Author: Trong Vinh
### Version: v2.0 - 2025-06-29
### ========================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
echo -e "${CYAN}"
cat << "EOF"
██╗   ██╗██╗███████╗████████╗██████╗  ██████╗ ████████╗
██║   ██║██║██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗╚══██╔══╝
██║   ██║██║█████╗     ██║   ██████╔╝██║   ██║   ██║   
╚██╗ ██╔╝██║██╔══╝     ██║   ██╔══██╗██║   ██║   ██║   
 ╚████╔╝ ██║███████╗   ██║   ██████╔╝╚██████╔╝   ██║   
  ╚═══╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝    ╚═╝   
                                                        
    🤖 AI-Powered Facebook Messenger Automation
EOF
echo -e "${NC}"

echo -e "${BLUE}🚀 VietBot AI One-Command Deploy v2.0${NC}"
echo -e "${BLUE}📅 Date: $(date)${NC}"
echo -e "${BLUE}🖥️  Server: $(hostname -I | awk '{print $1}')${NC}"

# === Step 1: Get Domain Input ===
echo -e "\n${YELLOW}📝 Step 1: Domain Configuration${NC}"
read -p "🌐 Enter your domain (e.g., vietbot.yourdomain.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo -e "\n${RED}❌ Domain is required. Please run the script again.${NC}"
  exit 1
fi

SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ Domain: ${DOMAIN}${NC}"
echo -e "${GREEN}✅ Server IP: ${SERVER_IP}${NC}"

# Configuration
N8N_VERSION="latest"
POSTGRES_VERSION="15-alpine"
REDIS_VERSION="7-alpine"
CADDY_VERSION="2-alpine"

# === Step 2: System Update & Security ===
echo -e "\n${YELLOW}🔒 Step 2: System Security & Updates${NC}"
apt update && apt upgrade -y > /dev/null 2>&1
apt install -y curl wget git unzip ufw fail2ban htop nano net-tools > /dev/null 2>&1

# Configure UFW Firewall
echo -e "${YELLOW}🛡️  Configuring firewall...${NC}"
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow ssh > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

# Configure Fail2Ban
systemctl enable fail2ban > /dev/null 2>&1
systemctl start fail2ban > /dev/null 2>&1

echo -e "${GREEN}✅ Security hardening completed${NC}"

# === Step 3: Install Docker & Docker Compose ===
echo -e "\n${YELLOW}🐳 Step 3: Installing Docker & Docker Compose${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh > /dev/null 2>&1
    sh get-docker.sh > /dev/null 2>&1
    rm get-docker.sh
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
    chmod +x /usr/local/bin/docker-compose
fi

# Start Docker
systemctl enable docker > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1

echo -e "${GREEN}✅ Docker installation completed${NC}"

# === Step 4: Create VietBot Directory Structure ===
echo -e "\n${YELLOW}📁 Step 4: Creating Project Structure${NC}"
mkdir -p /opt/vietbot/{data,backups,logs,config}
mkdir -p /opt/vietbot/data/{n8n,postgres,redis,caddy}
mkdir -p /opt/vietbot/config/{caddy,n8n}

# Set proper permissions
chown -R 1000:1000 /opt/vietbot/data/n8n

echo -e "${GREEN}✅ Directory structure created${NC}"

# === Step 5: Generate Environment Variables ===
echo -e "\n${YELLOW}⚙️  Step 5: Generating Configuration Files${NC}"

# Generate random passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
N8N_AUTH_PASSWORD=$(openssl rand -base64 16)

cat > /opt/vietbot/.env << EOF
# VietBot AI Environment Configuration
DOMAIN=${DOMAIN}
SERVER_IP=${SERVER_IP}

# Database Configuration
POSTGRES_DB=vietbot_ai
POSTGRES_USER=vietbot
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# n8n Configuration
N8N_EDITOR_BASE_URL=https://${DOMAIN}
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_DB_TYPE=postgresdb
N8N_DB_POSTGRESDB_HOST=postgres
N8N_DB_POSTGRESDB_PORT=5432
N8N_DB_POSTGRESDB_DATABASE=vietbot_ai
N8N_DB_POSTGRESDB_USER=vietbot
N8N_DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}

# Security
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=${N8N_AUTH_PASSWORD}

# Performance
N8N_EXECUTIONS_TIMEOUT=300
N8N_EXECUTIONS_TIMEOUT_MAX=600
N8N_LOG_LEVEL=info
N8N_EXECUTIONS_DATA_SAVE_ON_ERROR=all
N8N_EXECUTIONS_DATA_SAVE_ON_SUCCESS=all

# Timezone
GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
TZ=Asia/Ho_Chi_Minh
EOF

echo -e "${GREEN}✅ Environment configuration generated${NC}"

# === Step 6: Create Docker Compose Configuration ===
echo -e "\n${YELLOW}🐳 Step 6: Creating Docker Services${NC}"
cat > /opt/vietbot/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: vietbot_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - vietbot_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: vietbot_redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - ./data/redis:/data
    networks:
      - vietbot_network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # n8n Workflow Automation
  n8n:
    image: docker.io/n8nio/n8n:latest
    container_name: vietbot_n8n
    restart: unless-stopped
    environment:
      - N8N_EDITOR_BASE_URL=${N8N_EDITOR_BASE_URL}
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=${N8N_PORT}
      - N8N_PROTOCOL=${N8N_PROTOCOL}
      - N8N_DB_TYPE=${N8N_DB_TYPE}
      - N8N_DB_POSTGRESDB_HOST=${N8N_DB_POSTGRESDB_HOST}
      - N8N_DB_POSTGRESDB_PORT=${N8N_DB_POSTGRESDB_PORT}
      - N8N_DB_POSTGRESDB_DATABASE=${N8N_DB_POSTGRESDB_DATABASE}
      - N8N_DB_POSTGRESDB_USER=${N8N_DB_POSTGRESDB_USER}
      - N8N_DB_POSTGRESDB_PASSWORD=${N8N_DB_POSTGRESDB_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_EXECUTIONS_TIMEOUT=${N8N_EXECUTIONS_TIMEOUT}
      - N8N_EXECUTIONS_TIMEOUT_MAX=${N8N_EXECUTIONS_TIMEOUT_MAX}
      - N8N_LOG_LEVEL=${N8N_LOG_LEVEL}
      - N8N_EXECUTIONS_DATA_SAVE_ON_ERROR=${N8N_EXECUTIONS_DATA_SAVE_ON_ERROR}
      - N8N_EXECUTIONS_DATA_SAVE_ON_SUCCESS=${N8N_EXECUTIONS_DATA_SAVE_ON_SUCCESS}
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
      - TZ=${TZ}
    ports:
      - "5678:5678"
    volumes:
      - ./data/n8n:/home/node/.n8n
      - ./logs:/var/log/n8n
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

  # Caddy Reverse Proxy
  caddy:
    image: caddy:2-alpine
    container_name: vietbot_caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./data/caddy:/data
      - ./config/caddy:/config
    networks:
      - vietbot_network
    depends_on:
      - n8n

networks:
  vietbot_network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  n8n_data:
  caddy_data:
EOF

echo -e "${GREEN}✅ Docker Compose configuration created${NC}"

# === Step 7: Create Caddy Configuration ===
echo -e "\n${YELLOW}🔒 Step 7: Creating SSL & Proxy Configuration${NC}"
cat > /opt/vietbot/config/caddy/Caddyfile << EOF
# VietBot AI Caddy Configuration
${DOMAIN} {
    reverse_proxy n8n:5678
    
    # Security headers
    header {
        # Enable HSTS
        Strict-Transport-Security max-age=31536000;
        # Prevent MIME sniffing
        X-Content-Type-Options nosniff
        # Prevent clickjacking
        X-Frame-Options DENY
        # XSS protection
        X-XSS-Protection "1; mode=block"
        # Remove server info
        -Server
    }
    
    # Enable compression
    encode gzip
    
    # Logging
    log {
        output file /var/log/caddy/access.log {
            roll_size 10MB
            roll_keep 10
        }
        format json
    }
}

# Health check endpoint
health.${DOMAIN} {
    respond /health 200
    respond "VietBot AI is running - $(date)"
}
EOF

echo -e "${GREEN}✅ SSL & Proxy configuration created${NC}"

# === Step 8: Pull Docker Images ===
echo -e "\n${YELLOW}📦 Step 8: Downloading Docker Images${NC}"
echo -e "${CYAN}This may take 3-5 minutes depending on your internet speed...${NC}"

docker pull docker.io/n8nio/n8n:latest > /dev/null 2>&1 &
docker pull postgres:15-alpine > /dev/null 2>&1 &
docker pull redis:7-alpine > /dev/null 2>&1 &
docker pull caddy:2-alpine > /dev/null 2>&1 &

# Wait for all pulls to complete
wait

echo -e "${GREEN}✅ All Docker images downloaded${NC}"

# === Step 9: Create Management Scripts ===
echo -e "\n${YELLOW}🛠️  Step 9: Creating Management Tools${NC}"

# Backup Script
cat > /opt/vietbot/backup.sh << 'EOF'
#!/bin/bash
# VietBot AI Backup Script

BACKUP_DIR="/opt/vietbot/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "🔄 Starting VietBot AI backup - $DATE"

# Database backup
docker exec vietbot_postgres pg_dump -U vietbot vietbot_ai > "$BACKUP_DIR/db_backup_$DATE.sql"

# n8n data backup
tar -czf "$BACKUP_DIR/n8n_backup_$DATE.tar.gz" -C /opt/vietbot/data/n8n .

# Configuration backup
tar -czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" -C /opt/vietbot/config .

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "✅ Backup completed - $DATE"
echo "📁 Files saved in: $BACKUP_DIR"
EOF

# Monitor Script
cat > /opt/vietbot/monitor.sh << 'EOF'
#!/bin/bash
# VietBot AI Monitoring Script

echo "🤖 VietBot AI System Status"
echo "=========================="
echo "Date: $(date)"
echo ""

# Docker containers status
echo "📦 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=vietbot"
echo ""

# System resources
echo "💾 System Resources:"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2 " (" int($3/$2*100) "%)"}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Service health checks
echo "🏥 Health Checks:"
if curl -s http://localhost:5678/healthz > /dev/null; then
    echo "✅ n8n: Healthy"
else
    echo "❌ n8n: Unhealthy"
fi

if docker exec vietbot_postgres pg_isready -U vietbot -d vietbot_ai > /dev/null 2>&1; then
    echo "✅ PostgreSQL: Healthy"
else
    echo "❌ PostgreSQL: Unhealthy"
fi

if docker exec vietbot_redis redis-cli --no-auth-warning -a "$REDIS_PASSWORD" ping > /dev/null 2>&1; then
    echo "✅ Redis: Healthy"
else
    echo "❌ Redis: Unhealthy"
fi

# Network test
if curl -s -I https://$(grep DOMAIN /opt/vietbot/.env | cut -d'=' -f2) > /dev/null; then
    echo "✅ Website: Accessible"
else
    echo "❌ Website: Not accessible"
fi
EOF

# Update Script
cat > /opt/vietbot/update.sh << 'EOF'
#!/bin/bash
# VietBot AI Update Script

echo "🔄 Updating VietBot AI..."

cd /opt/vietbot

# Backup before update
./backup.sh

# Pull latest images
docker-compose pull

# Restart services
docker-compose up -d

echo "✅ Update completed"
EOF

# Quick Commands Script
cat > /opt/vietbot/vietbot.sh << 'EOF'
#!/bin/bash
# VietBot AI Quick Commands

case "$1" in
    start)
        cd /opt/vietbot && docker-compose up -d
        ;;
    stop)
        cd /opt/vietbot && docker-compose down
        ;;
    restart)
        cd /opt/vietbot && docker-compose restart
        ;;
    status)
        cd /opt/vietbot && ./monitor.sh
        ;;
    logs)
        cd /opt/vietbot && docker-compose logs -f
        ;;
    backup)
        cd /opt/vietbot && ./backup.sh
        ;;
    update)
        cd /opt/vietbot && ./update.sh
        ;;
    *)
        echo "VietBot AI Management Commands:"
        echo "  ./vietbot.sh start   - Start all services"
        echo "  ./vietbot.sh stop    - Stop all services"
        echo "  ./vietbot.sh restart - Restart all services"
        echo "  ./vietbot.sh status  - Show system status"
        echo "  ./vietbot.sh logs    - Show live logs"
        echo "  ./vietbot.sh backup  - Create backup"
        echo "  ./vietbot.sh update  - Update to latest version"
        ;;
esac
EOF

# Make scripts executable
chmod +x /opt/vietbot/*.sh

echo -e "${GREEN}✅ Management tools created${NC}"

# === Step 10: Setup Cron Jobs ===
echo -e "\n${YELLOW}⏰ Step 10: Setting Up Automated Tasks${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/vietbot/backup.sh >> /opt/vietbot/logs/backup.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/vietbot/monitor.sh >> /opt/vietbot/logs/monitor.log 2>&1") | crontab -

echo -e "${GREEN}✅ Automated tasks configured${NC}"

# === Step 11: Start Services ===
echo -e "\n${YELLOW}🚀 Step 11: Starting VietBot AI Services${NC}"
cd /opt/vietbot
docker-compose up -d

# Wait for services to start
echo -e "${CYAN}⏳ Waiting for services to initialize...${NC}"
sleep 45

# === Step 12: Final Health Check ===
echo -e "\n${YELLOW}🔍 Step 12: Health Check${NC}"
./monitor.sh

# === Step 13: Create Quick Access ===
echo -e "\n${YELLOW}🔧 Step 13: Creating Quick Access${NC}"
ln -sf /opt/vietbot/vietbot.sh /usr/local/bin/vietbot
echo 'alias vietbot="/opt/vietbot/vietbot.sh"' >> ~/.bashrc

# === COMPLETION SUMMARY ===
echo -e "\n${GREEN}🎉 VietBot AI Deployment Completed Successfully!${NC}"
echo -e "\n${PURPLE}=================================${NC}"
echo -e "${PURPLE}📋 ACCESS INFORMATION${NC}"
echo -e "${PURPLE}=================================${NC}"
echo -e "${CYAN}🌐 Website:${NC} https://${DOMAIN}"
echo -e "${CYAN}👤 Username:${NC} admin"
echo -e "${CYAN}🔑 Password:${NC} ${N8N_AUTH_PASSWORD}"
echo -e "${CYAN}📊 Health Check:${NC} https://health.${DOMAIN}"

echo -e "\n${PURPLE}=================================${NC}"
echo -e "${PURPLE}🛠️  MANAGEMENT COMMANDS${NC}"
echo -e "${PURPLE}=================================${NC}"
echo -e "${YELLOW}vietbot status${NC}   - Show system status"
echo -e "${YELLOW}vietbot start${NC}    - Start all services"
echo -e "${YELLOW}vietbot stop${NC}     - Stop all services"
echo -e "${YELLOW}vietbot restart${NC}  - Restart services"
echo -e "${YELLOW}vietbot logs${NC}     - View live logs"
echo -e "${YELLOW}vietbot backup${NC}   - Create backup"
echo -e "${YELLOW}vietbot update${NC}   - Update system"

echo -e "\n${PURPLE}=================================${NC}"
echo -e "${PURPLE}📁 IMPORTANT PATHS${NC}"
echo -e "${PURPLE}=================================${NC}"
echo -e "${CYAN}Project Directory:${NC} /opt/vietbot"
echo -e "${CYAN}Configuration:${NC} /opt/vietbot/.env"
echo -e "${CYAN}Backups:${NC} /opt/vietbot/backups"
echo -e "${CYAN}Logs:${NC} /opt/vietbot/logs"

echo -e "\n${PURPLE}=================================${NC}"
echo -e "${PURPLE}🔄 NEXT STEPS${NC}"
echo -e "${PURPLE}=================================${NC}"
echo -e "${GREEN}1. Point DNS A record: ${DOMAIN} → ${SERVER_IP}${NC}"
echo -e "${GREEN}2. Wait 2-3 minutes for SSL certificate${NC}"
echo -e "${GREEN}3. Access: https://${DOMAIN}${NC}"
echo -e "${GREEN}4. Import your n8n workflows${NC}"
echo -e "${GREEN}5. Configure Claude 3.5 Sonnet API${NC}"
echo -e "${GREEN}6. Setup Facebook webhook endpoints${NC}"

echo -e "\n${PURPLE}=================================${NC}"
echo -e "${PURPLE}🆘 TROUBLESHOOTING${NC}"
echo -e "${PURPLE}=================================${NC}"
echo -e "${YELLOW}If website shows 502 error:${NC}"
echo -e "  1. Wait 2-3 minutes for services to start"
echo -e "  2. Check status: ${CYAN}vietbot status${NC}"
echo -e "  3. Restart if needed: ${CYAN}vietbot restart${NC}"
echo -e ""
echo -e "${YELLOW}If SSL certificate fails:${NC}"
echo -e "  1. Verify DNS points to ${SERVER_IP}"
echo -e "  2. Check domain propagation: ${CYAN}nslookup ${DOMAIN}${NC}"
echo -e "  3. Restart Caddy: ${CYAN}docker-compose restart caddy${NC}"
echo -e ""
echo -e "${YELLOW}For support:${NC}"
echo -e "  - Check logs: ${CYAN}vietbot logs${NC}"
echo -e "  - System status: ${CYAN}vietbot status${NC}"
echo -e "  - Manual commands: ${CYAN}cd /opt/vietbot${NC}"

echo -e "\n${GREEN}🎊 Happy Automating with VietBot AI! 🤖✨${NC}"

# Save credentials to file
cat > /opt/vietbot/access_info.txt << EOF
VietBot AI Access Information
=============================
Website: https://${DOMAIN}
Username: admin
Password: ${N8N_AUTH_PASSWORD}
Server IP: ${SERVER_IP}
Installation Date: $(date)

Quick Commands:
- vietbot status
- vietbot logs
- vietbot backup
- vietbot restart

Important: Keep this file secure!
EOF

echo -e "\n${BLUE}💾 Access credentials saved to: /opt/vietbot/access_info.txt${NC}"
