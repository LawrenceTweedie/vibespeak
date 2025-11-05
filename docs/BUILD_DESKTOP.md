# Building Desktop Applications

This guide explains how to build VibeSpeak desktop applications for Windows, macOS, and Linux.

## Prerequisites

- Node.js 18+
- npm or yarn
- For macOS builds: macOS system
- For Windows builds: Windows system or wine
- For Linux builds: Any system

## Quick Build

### Build All Platforms

```bash
# From project root
./build-desktop.sh
```

This will:
1. Build the Vue3 client
2. Install desktop dependencies
3. Build apps for Windows, macOS, and Linux

### Build Specific Platform

```bash
# Build client first
cd client
npm run build

# Build desktop for specific platform
cd ../desktop

# Windows
npm run build:win

# macOS
npm run build:mac

# Linux
npm run build:linux
```

## Manual Build Process

### 1. Build Client Application

```bash
cd client

# Install dependencies (first time only)
npm install

# Create production build
npm run build

# Output: client/dist/
```

### 2. Setup Desktop Environment

```bash
cd ../desktop

# Install dependencies (first time only)
npm install
```

### 3. Build for Target Platform

#### Windows (.exe)

```bash
npm run build:win
```

**Output:**
- `dist/VibeSpeak Setup.exe` - Installer (~80 MB)

**Notes:**
- Can be built on any platform with wine
- NSIS installer included
- Auto-updates supported
- Creates Start Menu shortcuts

#### macOS (.dmg)

```bash
npm run build:mac
```

**Output:**
- `dist/VibeSpeak.dmg` - Disk image (~85 MB)

**Notes:**
- Must be built on macOS for code signing
- Creates drag-to-Applications installer
- Notarization recommended for distribution

#### Linux (AppImage & .deb)

```bash
npm run build:linux
```

**Output:**
- `dist/VibeSpeak.AppImage` - Universal Linux app (~75 MB)
- `dist/vibespeak.deb` - Debian/Ubuntu package (~75 MB)

**Notes:**
- AppImage works on most distributions
- .deb for Debian/Ubuntu-based systems
- No installation required for AppImage

## Configuration

### Electron Builder Config

The build configuration is in `desktop/package.json`:

```json
{
  "build": {
    "appId": "com.vibespeak.app",
    "productName": "VibeSpeak",
    "directories": {
      "output": "dist"
    },
    "files": [
      "main.js",
      "preload.js",
      "../client/dist/**/*"
    ],
    "win": {
      "target": "nsis",
      "icon": "icon.ico"
    },
    "mac": {
      "target": "dmg",
      "icon": "icon.icns",
      "category": "public.app-category.social-networking"
    },
    "linux": {
      "target": ["AppImage", "deb"],
      "icon": "icon.png",
      "category": "Network"
    }
  }
}
```

### Custom Icons

Place your icons in `desktop/` directory:
- **Windows**: `icon.ico` (256x256)
- **macOS**: `icon.icns` (512x512)
- **Linux**: `icon.png` (512x512)

## Signing and Notarization

### Windows Code Signing

1. Obtain a code signing certificate
2. Set environment variables:
```bash
export CSC_LINK=/path/to/certificate.pfx
export CSC_KEY_PASSWORD=your_password
```

3. Build:
```bash
npm run build:win
```

### macOS Code Signing

1. Install Apple Developer certificate in Keychain
2. Set environment variables:
```bash
export APPLE_ID=your@email.com
export APPLE_ID_PASSWORD=app-specific-password
export APPLE_TEAM_ID=your_team_id
```

3. Build:
```bash
npm run build:mac
```

### Notarization (macOS)

Automatic notarization is configured in electron-builder.
Ensure you have:
- Valid Apple Developer account
- App-specific password
- Correct Team ID

## Troubleshooting

### Build Fails - Missing Dependencies

```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Build Fails - Out of Memory

```bash
# Increase Node.js memory
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build:all
```

### Windows Build on Linux/macOS

Install wine:
```bash
# Ubuntu/Debian
sudo apt-get install wine64

# macOS
brew install wine-stable
```

### macOS Build Permission Issues

```bash
# Grant permissions to electron-builder
xattr -cr node_modules/electron
```

### AppImage Not Executable

```bash
chmod +x dist/VibeSpeak.AppImage
```

## Distribution

### Hosting Installers

1. Upload built files to your web server:
```bash
scp desktop/dist/* user@server:/var/www/vibespeak/downloads/
```

2. Update download page links to match your server

### Auto-Updates

Configure update server in `desktop/main.js`:

```javascript
const { autoUpdater } = require('electron-updater')

autoUpdater.setFeedURL({
  provider: 'generic',
  url: 'https://your-server.com/updates'
})

autoUpdater.checkForUpdates()
```

### Release Process

1. Update version in `desktop/package.json`
2. Build all platforms
3. Test each installer
4. Upload to server
5. Update download page
6. Announce release

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/build-desktop.yml`:

```yaml
name: Build Desktop Apps

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]

    steps:
      - uses: actions/checkout@v2

      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'

      - name: Build
        run: ./build-desktop.sh

      - name: Upload artifacts
        uses: actions/upload-artifact@v2
        with:
          name: ${{ matrix.os }}-build
          path: desktop/dist/
```

## File Sizes

Typical build sizes:
- **Windows**: 80-90 MB (installer)
- **macOS**: 85-95 MB (DMG)
- **Linux AppImage**: 75-85 MB
- **Linux .deb**: 75-85 MB

## Performance Tips

1. **Parallel Builds**: Build different platforms simultaneously
2. **Cache node_modules**: Speed up subsequent builds
3. **Use SSD**: Significantly faster build times
4. **Adequate RAM**: Minimum 4GB, recommended 8GB+

## Support

For build issues:
- Check electron-builder docs: https://www.electron.build/
- Electron documentation: https://www.electronjs.org/
- Open an issue in the repository
