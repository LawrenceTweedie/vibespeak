# VibeSpeak Desktop

Electron-based desktop application for VibeSpeak.

## Development

1. First, start the Vue3 client in development mode:
```bash
cd ../client
npm install
npm run dev
```

2. Then, start the Electron app:
```bash
cd ../desktop
npm install
NODE_ENV=development npm start
```

## Building

### Prerequisites
- Node.js 18+
- npm or yarn

### Build for all platforms

```bash
# Build the Vue3 client first
cd ../client
npm run build

# Build desktop app
cd ../desktop

# Windows
npm run build:win

# macOS
npm run build:mac

# Linux
npm run build:linux
```

### Output
Built applications will be in `desktop/dist/` directory.

## Configuration

The desktop app uses the same configuration as the web client. Set environment variables in the client's `.env` file:

```
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8080
```
