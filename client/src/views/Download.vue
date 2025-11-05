<template>
  <div class="download-page">
    <div class="container">
      <header class="header">
        <h1>Download VibeSpeak</h1>
        <p class="subtitle">Get the desktop app for the best experience</p>
      </header>

      <!-- HTTP Warning -->
      <div v-if="!isSecure" class="warning-banner">
        <div class="warning-icon">⚠️</div>
        <div class="warning-content">
          <h3>Important Notice</h3>
          <p>
            You're accessing VibeSpeak over HTTP. For video/audio calls to work in the browser,
            you need HTTPS. Download the desktop app for full functionality without HTTPS.
          </p>
        </div>
      </div>

      <!-- Features -->
      <section class="features">
        <h2>Why Desktop App?</h2>
        <div class="features-grid">
          <div class="feature-card">
            <div class="feature-icon">✓</div>
            <h3>Works Everywhere</h3>
            <p>No HTTPS required - works on any network</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🚀</div>
            <h3>Better Performance</h3>
            <p>Native app with optimized video/audio</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🔔</div>
            <h3>Desktop Notifications</h3>
            <p>Never miss a call or message</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">📴</div>
            <h3>Offline Ready</h3>
            <p>Settings saved locally</p>
          </div>
        </div>
      </section>

      <!-- Downloads -->
      <section class="downloads">
        <h2>Choose Your Platform</h2>
        <div class="download-cards">
          <!-- Windows -->
          <div class="download-card">
            <div class="platform-icon">🪟</div>
            <h3>Windows</h3>
            <p>Windows 10/11</p>
            <div class="download-options">
              <a href="/downloads/VibeSpeak-Setup.exe" class="download-btn primary" download>
                <span class="btn-icon">⬇️</span>
                Download .exe
              </a>
              <span class="file-size">~80 MB</span>
            </div>
            <div class="install-steps">
              <p><strong>Installation:</strong></p>
              <ol>
                <li>Download the installer</li>
                <li>Run VibeSpeak-Setup.exe</li>
                <li>Follow the installation wizard</li>
                <li>Launch from Start Menu</li>
              </ol>
            </div>
          </div>

          <!-- macOS -->
          <div class="download-card">
            <div class="platform-icon">🍎</div>
            <h3>macOS</h3>
            <p>macOS 10.13+</p>
            <div class="download-options">
              <a href="/downloads/VibeSpeak.dmg" class="download-btn primary" download>
                <span class="btn-icon">⬇️</span>
                Download .dmg
              </a>
              <span class="file-size">~85 MB</span>
            </div>
            <div class="install-steps">
              <p><strong>Installation:</strong></p>
              <ol>
                <li>Download the DMG file</li>
                <li>Open VibeSpeak.dmg</li>
                <li>Drag VibeSpeak to Applications</li>
                <li>Launch from Applications folder</li>
              </ol>
            </div>
          </div>

          <!-- Linux -->
          <div class="download-card">
            <div class="platform-icon">🐧</div>
            <h3>Linux</h3>
            <p>Ubuntu 18.04+, Fedora 32+</p>
            <div class="download-options">
              <a href="/downloads/VibeSpeak.AppImage" class="download-btn primary" download>
                <span class="btn-icon">⬇️</span>
                Download AppImage
              </a>
              <a href="/downloads/vibespeak.deb" class="download-btn secondary" download>
                Download .deb
              </a>
              <span class="file-size">~75 MB</span>
            </div>
            <div class="install-steps">
              <p><strong>AppImage:</strong></p>
              <ol>
                <li>Download VibeSpeak.AppImage</li>
                <li>Make executable: <code>chmod +x VibeSpeak.AppImage</code></li>
                <li>Run: <code>./VibeSpeak.AppImage</code></li>
              </ol>
              <p><strong>Debian/Ubuntu (.deb):</strong></p>
              <ol>
                <li>Download vibespeak.deb</li>
                <li>Install: <code>sudo dpkg -i vibespeak.deb</code></li>
              </ol>
            </div>
          </div>
        </div>
      </section>

      <!-- System Requirements -->
      <section class="requirements">
        <h2>System Requirements</h2>
        <div class="requirements-grid">
          <div class="req-card">
            <h4>Minimum</h4>
            <ul>
              <li>2 GB RAM</li>
              <li>100 MB disk space</li>
              <li>1280x720 display</li>
              <li>2 Mbps internet</li>
            </ul>
          </div>
          <div class="req-card">
            <h4>Recommended</h4>
            <ul>
              <li>4 GB RAM</li>
              <li>200 MB disk space</li>
              <li>1920x1080 display</li>
              <li>5 Mbps internet</li>
            </ul>
          </div>
        </div>
      </section>

      <!-- Back to Browser -->
      <section class="browser-option">
        <p>Prefer to use the web version?</p>
        <router-link to="/" class="back-btn">
          ← Back to Web App
        </router-link>
        <p class="note">
          Note: Web version requires HTTPS for video/audio. Configure SSL on your server.
        </p>
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const isSecure = computed(() => {
  return window.location.protocol === 'https:' ||
         window.location.hostname === 'localhost' ||
         window.location.hostname === '127.0.0.1'
})
</script>

<style scoped>
.download-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.header {
  text-align: center;
  margin-bottom: 3rem;
}

.header h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  color: #fff;
}

.subtitle {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.9);
}

.warning-banner {
  background: rgba(255, 152, 0, 0.2);
  border: 2px solid #ff9800;
  border-radius: 1rem;
  padding: 1.5rem;
  margin-bottom: 3rem;
  display: flex;
  gap: 1rem;
  backdrop-filter: blur(10px);
}

.warning-icon {
  font-size: 2rem;
}

.warning-content h3 {
  margin-bottom: 0.5rem;
  color: #fff;
}

.warning-content p {
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.6;
}

section {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 1rem;
  padding: 2rem;
  margin-bottom: 2rem;
}

section h2 {
  text-align: center;
  margin-bottom: 2rem;
  color: #fff;
  font-size: 2rem;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.feature-card {
  background: rgba(255, 255, 255, 0.1);
  padding: 1.5rem;
  border-radius: 0.75rem;
  text-align: center;
}

.feature-icon {
  font-size: 2rem;
  margin-bottom: 1rem;
}

.feature-card h3 {
  margin-bottom: 0.5rem;
  color: #fff;
}

.feature-card p {
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.9rem;
}

.download-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.download-card {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 1rem;
  padding: 2rem;
  text-align: center;
}

.platform-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.download-card h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #fff;
}

.download-card p {
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 1.5rem;
}

.download-options {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.download-btn {
  padding: 0.875rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: 600;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.download-btn.primary {
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: #fff;
}

.download-btn.secondary {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.download-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.file-size {
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.85rem;
}

.install-steps {
  text-align: left;
  background: rgba(0, 0, 0, 0.2);
  padding: 1rem;
  border-radius: 0.5rem;
  margin-top: 1rem;
}

.install-steps p {
  color: #fff;
  margin-bottom: 0.5rem;
}

.install-steps ol {
  margin-left: 1.5rem;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.8;
}

.install-steps code {
  background: rgba(0, 0, 0, 0.3);
  padding: 0.2rem 0.5rem;
  border-radius: 0.25rem;
  font-family: 'Courier New', monospace;
  font-size: 0.85rem;
}

.requirements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
}

.req-card {
  background: rgba(255, 255, 255, 0.1);
  padding: 1.5rem;
  border-radius: 0.75rem;
}

.req-card h4 {
  margin-bottom: 1rem;
  color: #fff;
  font-size: 1.25rem;
}

.req-card ul {
  list-style: none;
  padding: 0;
}

.req-card li {
  padding: 0.5rem 0;
  color: rgba(255, 255, 255, 0.9);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.req-card li:last-child {
  border-bottom: none;
}

.browser-option {
  text-align: center;
}

.browser-option p {
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 1rem;
}

.back-btn {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
  text-decoration: none;
  border-radius: 0.5rem;
  font-weight: 600;
  margin-bottom: 1rem;
  transition: all 0.2s;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.note {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.7);
  font-style: italic;
}
</style>
