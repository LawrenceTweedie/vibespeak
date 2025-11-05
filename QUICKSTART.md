# VibeSpeak - Quick Start Guide

Get VibeSpeak up and running in minutes!

## Prerequisites

- PHP 8.0+
- MySQL 8.0+
- Composer
- Node.js 18+
- npm

## 1. Setup Database

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE vibespeak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Import schema
mysql -u root -p vibespeak < server/database/schema.sql
```

## 2. Setup Server

```bash
cd server

# Install dependencies
composer install

# Configure environment
cp .env.example .env
# Edit .env with your database credentials

# Start API server (Terminal 1)
php -S 0.0.0.0:8000 -t api/

# Start WebSocket server (Terminal 2)
php websocket/server.php
```

## 3. Setup Client

```bash
cd client

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Default values should work for local development

# Start development server
npm run dev
```

## 4. Access Application

Open your browser and navigate to:
```
http://localhost:3000
```

## 5. Test with Demo Account

Login with:
- **Username**: demo
- **Password**: password

## Next Steps

- Create a room and test video/audio
- Enable screen sharing
- Create your own account
- Build desktop app (see [Desktop App](#desktop-app-optional))

## Desktop App (Optional)

```bash
# Build client first
cd client
npm run build

# Build desktop app
cd ../desktop
npm install

# Run desktop app
npm start
```

## Production Deployment

For production deployment instructions, see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

## Troubleshooting

### Can't connect to API
- Verify PHP server is running on port 8000
- Check database connection in server/.env

### WebSocket connection failed
- Verify WebSocket server is running on port 8080
- Check firewall settings

### Camera/Microphone not working
- Grant browser permissions when prompted
- Check browser console for errors
- Ensure HTTPS for production (WebRTC requirement)

## Documentation

- [Full Deployment Guide](docs/DEPLOYMENT.md)
- [User Guide](docs/USER_GUIDE.md)
- [Desktop App Guide](desktop/README.md)

## Support

For issues and questions, check the documentation or contact your administrator.
