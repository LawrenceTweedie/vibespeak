const { app, BrowserWindow, ipcMain, desktopCapturer, session, Menu } = require('electron')
const path = require('path')
const url = require('url')

let mainWindow

function createWindow() {
  const isDev = process.env.NODE_ENV === 'development'

  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: isDev // Disable webSecurity in production to allow file:// protocol
    },
    backgroundColor: '#1a1a1a',
    title: 'VibeSpeak',
    show: false
  })

  // Remove default menu bar
  Menu.setApplicationMenu(null)

  // Load the app
  if (process.env.NODE_ENV === 'development') {
    // In development, load from Vite dev server
    mainWindow.loadURL('http://localhost:3000')
    // Don't auto-open DevTools in development (can still use Ctrl+Shift+I)
  } else {
    // In production, load built files from extraResources
    // Files are in resources/app/client/dist/
    const indexPath = path.join(process.resourcesPath, 'app', 'client', 'dist', 'index.html')

    // Use loadURL with file:// protocol instead of loadFile
    mainWindow.loadURL(url.format({
      pathname: indexPath,
      protocol: 'file:',
      slashes: true
    }))
    // Don't auto-open DevTools in production (can still use Ctrl+Shift+I)
  }

  // Show window when ready
  mainWindow.once('ready-to-show', () => {
    mainWindow.show()
  })

  // Handle window close
  mainWindow.on('closed', () => {
    mainWindow = null
  })

  // Enable screen sharing
  mainWindow.webContents.session.setPermissionRequestHandler((webContents, permission, callback) => {
    if (permission === 'media') {
      // Approve media permissions
      callback(true)
    } else {
      callback(false)
    }
  })
}

// App lifecycle
app.whenReady().then(() => {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

// IPC handlers
ipcMain.handle('get-app-version', () => {
  return app.getVersion()
})

ipcMain.handle('minimize-window', () => {
  if (mainWindow) {
    mainWindow.minimize()
  }
})

ipcMain.handle('maximize-window', () => {
  if (mainWindow) {
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize()
    } else {
      mainWindow.maximize()
    }
  }
})

ipcMain.handle('close-window', () => {
  if (mainWindow) {
    mainWindow.close()
  }
})

ipcMain.handle('get-desktop-sources', async () => {
  try {
    const sources = await desktopCapturer.getSources({
      types: ['window', 'screen'],
      thumbnailSize: { width: 300, height: 200 }
    })

    // Convert thumbnails to data URLs for display in renderer
    return sources.map(source => ({
      id: source.id,
      name: source.name,
      thumbnail: source.thumbnail.toDataURL()
    }))
  } catch (error) {
    console.error('Error getting desktop sources:', error)
    return []
  }
})
