# VibeSpeak

A real-time communication platform featuring video, audio, screen sharing, and room-based collaboration.

## Features

- 🎥 Video calling with WebRTC
- 🎤 Audio communication with mute/unmute controls
- 📺 Screen sharing functionality
- 📱 Web and Desktop applications
- 🔒 Room-based communication
- 💬 Real-time messaging via WebSocket
- 🌐 REST API backend with PHP

## Project Structure

```
vibespeak/
├── server/          # PHP backend (API + WebSocket)
├── client/          # Vue3 web application
├── desktop/         # Electron desktop application
└── docs/            # Documentation
```

## Tech Stack

### Backend
- PHP 8.0+
- MySQL 8.0+
- Ratchet WebSocket server
- Composer

### Frontend
- Vue 3
- Vite
- WebRTC APIs
- Socket.io-client

### Desktop
- Electron
- Same Vue3 codebase as web

## Quick Start

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed installation and deployment instructions.

## User Guide

See [docs/USER_GUIDE.md](docs/USER_GUIDE.md) for usage instructions.

## License

MIT
