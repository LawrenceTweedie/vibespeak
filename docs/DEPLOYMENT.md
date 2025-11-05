# VibeSpeak - Deployment Guide

This guide covers installation, configuration, and deployment of VibeSpeak.

## Table of Contents

- [System Requirements](#system-requirements)
- [Server Setup](#server-setup)
- [Client Setup](#client-setup)
- [Desktop App Build](#desktop-app-build)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## System Requirements

### Server
- PHP 8.0 or higher
- MySQL 8.0 or higher
- Composer
- Web server (Apache/Nginx)
- SSL certificate (recommended for production)

### Client
- Node.js 18 or higher
- npm or yarn

### Desktop
- Node.js 18 or higher
- Electron build tools

## Server Setup

### 1. Install Dependencies

```bash
cd server
composer install
```

### 2. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=vibespeak
DB_USER=your_db_user
DB_PASS=your_db_password

# WebSocket Configuration
WS_HOST=0.0.0.0
WS_PORT=8080

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
```

### 3. Setup Database

Create the database and import the schema:

```bash
# Connect to MySQL
mysql -u root -p

# Create database
CREATE DATABASE vibespeak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Import schema
mysql -u root -p vibespeak < database/schema.sql
```

Or use the MySQL command directly:

```bash
mysql -u root -p < database/schema.sql
```

### 4. Start API Server

For development:

```bash
php -S 0.0.0.0:8000 -t api/
```

For production, configure your web server (Apache/Nginx) to serve the `api` directory.

#### Apache Configuration

Create a virtual host configuration:

```apache
<VirtualHost *:80>
    ServerName api.vibespeak.com
    DocumentRoot /path/to/vibespeak/server/api

    <Directory /path/to/vibespeak/server/api>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted

        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^ index.php [L]
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/vibespeak-api-error.log
    CustomLog ${APACHE_LOG_DIR}/vibespeak-api-access.log combined
</VirtualHost>
```

#### Nginx Configuration

```nginx
server {
    listen 80;
    server_name api.vibespeak.com;
    root /path/to/vibespeak/server/api;

    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

### 5. Start WebSocket Server

The WebSocket server must run as a separate process:

```bash
cd server
php websocket/server.php
```

For production, use a process manager like **systemd** or **supervisor**.

#### Systemd Service

Create `/etc/systemd/system/vibespeak-websocket.service`:

```ini
[Unit]
Description=VibeSpeak WebSocket Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/vibespeak/server
ExecStart=/usr/bin/php /path/to/vibespeak/server/websocket/server.php
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl enable vibespeak-websocket
sudo systemctl start vibespeak-websocket
sudo systemctl status vibespeak-websocket
```

#### Supervisor Configuration

Create `/etc/supervisor/conf.d/vibespeak-websocket.conf`:

```ini
[program:vibespeak-websocket]
command=php /path/to/vibespeak/server/websocket/server.php
directory=/path/to/vibespeak/server
autostart=true
autorestart=true
user=www-data
stdout_logfile=/var/log/vibespeak-websocket.log
stderr_logfile=/var/log/vibespeak-websocket-error.log
```

Reload supervisor:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start vibespeak-websocket
```

## Client Setup

### 1. Install Dependencies

```bash
cd client
npm install
```

### 2. Configure Environment

Create `.env` file:

```env
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8080
```

For production:

```env
VITE_API_URL=https://api.vibespeak.com
VITE_WS_URL=wss://ws.vibespeak.com
```

### 3. Development

```bash
npm run dev
```

The client will be available at `http://localhost:3000`

### 4. Production Build

```bash
npm run build
```

The built files will be in `client/dist/` directory.

### 5. Deploy Static Files

Deploy the `dist` directory to your web server or CDN.

#### Nginx Configuration for Client

```nginx
server {
    listen 80;
    server_name vibespeak.com;
    root /path/to/vibespeak/client/dist;

    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

## Desktop App Build

### 1. Build Client First

```bash
cd client
npm install
npm run build
```

### 2. Build Desktop App

```bash
cd desktop
npm install
```

Build for your platform:

```bash
# Windows
npm run build:win

# macOS
npm run build:mac

# Linux
npm run build:linux
```

Built applications will be in `desktop/dist/` directory.

### 3. Distribute

Distribute the built executables to your users:
- **Windows**: `VibeSpeak Setup.exe`
- **macOS**: `VibeSpeak.dmg`
- **Linux**: `VibeSpeak.AppImage` or `.deb` package

## Production Deployment

### SSL/TLS Configuration

For production, always use HTTPS and WSS (WebSocket Secure).

#### Let's Encrypt with Certbot

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d vibespeak.com -d api.vibespeak.com -d ws.vibespeak.com

# Auto-renewal
sudo certbot renew --dry-run
```

### WebSocket SSL Proxy

Use Nginx to proxy WSS connections:

```nginx
server {
    listen 443 ssl http2;
    server_name ws.vibespeak.com;

    ssl_certificate /etc/letsencrypt/live/ws.vibespeak.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ws.vibespeak.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Firewall Configuration

Open required ports:

```bash
# API
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# WebSocket (if not proxied)
sudo ufw allow 8080/tcp

# Enable firewall
sudo ufw enable
```

### Performance Optimization

#### PHP Configuration

Edit `php.ini`:

```ini
memory_limit = 256M
max_execution_time = 300
upload_max_filesize = 10M
post_max_size = 10M
```

#### MySQL Optimization

```sql
-- Optimize tables
OPTIMIZE TABLE users, rooms, room_participants, webrtc_sessions, messages;

-- Add indexes if needed
CREATE INDEX idx_room_participants_room ON room_participants(room_id);
CREATE INDEX idx_messages_room ON messages(room_id, created_at);
```

## Troubleshooting

### WebSocket Connection Issues

1. Check if WebSocket server is running:
```bash
sudo systemctl status vibespeak-websocket
# or
sudo supervisorctl status vibespeak-websocket
```

2. Test WebSocket connection:
```bash
# Install wscat
npm install -g wscat

# Test connection
wscat -c ws://localhost:8080
```

3. Check firewall rules:
```bash
sudo ufw status
```

### Database Connection Issues

1. Verify MySQL is running:
```bash
sudo systemctl status mysql
```

2. Test connection:
```bash
mysql -h localhost -u your_user -p vibespeak
```

3. Check credentials in `.env` file

### API Issues

1. Check API server logs:
```bash
tail -f /var/log/apache2/vibespeak-api-error.log
# or
tail -f /var/log/nginx/error.log
```

2. Verify PHP-FPM is running:
```bash
sudo systemctl status php8.0-fpm
```

3. Test API endpoint:
```bash
curl http://localhost:8000/health
```

### Client Build Issues

1. Clear node_modules and reinstall:
```bash
rm -rf node_modules package-lock.json
npm install
```

2. Clear Vite cache:
```bash
rm -rf node_modules/.vite
npm run build
```

### Desktop App Issues

1. Rebuild Electron:
```bash
cd desktop
npm rebuild electron
```

2. Clear Electron cache:
```bash
rm -rf ~/.cache/electron
```

## Monitoring

### System Monitoring

Install monitoring tools:

```bash
# Install htop
sudo apt-get install htop

# Install netstat
sudo apt-get install net-tools

# Monitor processes
htop

# Check ports
sudo netstat -tulpn | grep -E '8000|8080'
```

### Application Logs

Monitor application logs:

```bash
# WebSocket logs
sudo journalctl -u vibespeak-websocket -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# PHP logs
tail -f /var/log/php8.0-fpm.log
```

## Backup

### Database Backup

```bash
# Backup database
mysqldump -u root -p vibespeak > vibespeak_backup_$(date +%Y%m%d).sql

# Restore database
mysql -u root -p vibespeak < vibespeak_backup_20240101.sql
```

### Automated Backups

Create a cron job for daily backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * mysqldump -u root -pYOUR_PASSWORD vibespeak > /backups/vibespeak_$(date +\%Y\%m\%d).sql
```

## Support

For issues and questions:
- GitHub Issues: [github.com/yourrepo/vibespeak/issues](https://github.com/yourrepo/vibespeak/issues)
- Documentation: [docs.vibespeak.com](https://docs.vibespeak.com)
