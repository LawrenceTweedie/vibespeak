<template>
  <div class="room">
    <header class="room-header">
      <div class="room-info">
        <h2>{{ roomStore.currentRoom?.name }}</h2>
        <span class="room-code">Code: {{ roomStore.currentRoom?.room_code }}</span>
        <span class="participant-count">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
            <path d="M8 8c1.66 0 3-1.34 3-3S9.66 2 8 2 5 3.34 5 5s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V15h14v-1.5c0-2.33-4.67-3.5-7-3.5z"/>
          </svg>
          {{ participantCountDisplay }}
        </span>
      </div>
      <button @click="showChat = !showChat" class="chat-toggle" :class="{ active: showChat }">
        <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
          <path d="M2 5.5C2 4.67 2.67 4 3.5 4h13c.83 0 1.5.67 1.5 1.5v7c0 .83-.67 1.5-1.5 1.5H11l-4 3v-3H3.5C2.67 14 2 13.33 2 12.5v-7z"/>
        </svg>
        <span v-if="unreadMessages > 0" class="badge">{{ unreadMessages }}</span>
      </button>
    </header>

    <div class="room-content">
      <VideoGrid
        :local-stream="roomStore.localStream"
        :screen-stream="roomStore.screenStream"
        :remote-streams="roomStore.remoteStreams"
        :participants="roomStore.participants"
        :media-state="roomStore.mediaState"
        :class="{ 'with-chat': showChat }"
      />

      <!-- Chat Panel -->
      <div v-if="showChat" class="chat-panel">
        <div class="chat-header">
          <h3>Chat</h3>
          <button @click="showChat = false" class="close-btn">×</button>
        </div>

        <div class="chat-messages" ref="messagesContainer">
          <div
            v-for="msg in messages"
            :key="msg.id"
            class="message"
            :class="{ 'own-message': msg.userId === userStore.user.id }"
          >
            <div class="message-header">
              <span class="username">{{ getUserName(msg.userId) }}</span>
              <span class="timestamp">{{ formatTime(msg.timestamp) }}</span>
            </div>
            <div class="message-content">
              <p v-if="msg.text">{{ msg.text }}</p>
              <img v-if="msg.image" :src="msg.image" alt="Shared image" class="message-image" @click="showImageModal(msg.image)" />
            </div>
          </div>
        </div>

        <div class="chat-input">
          <div v-if="imagePreview" class="image-preview">
            <img :src="imagePreview" alt="Preview" />
            <button @click="clearImage" class="remove-image">×</button>
          </div>
          <div class="input-row">
            <input
              type="file"
              ref="fileInput"
              accept="image/*"
              @change="handleFileSelect"
              style="display: none"
            />
            <button @click="$refs.fileInput.click()" class="attach-btn" title="Attach image">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path d="M10 2C6.69 2 4 4.69 4 8v8c0 1.66 1.34 3 3 3s3-1.34 3-3V8c0-.55-.45-1-1-1s-1 .45-1 1v8c0 .55-.45 1-1 1s-1-.45-1-1V8c0-2.21 1.79-4 4-4s4 1.79 4 4v8c0 2.76-2.24 5-5 5s-5-2.24-5-5V8h-2v8c0 3.87 3.13 7 7 7s7-3.13 7-7V8c0-3.31-2.69-6-6-6z"/>
              </svg>
            </button>
            <textarea
              v-model="messageText"
              @keydown.enter.exact.prevent="sendMessage"
              @paste="handlePaste"
              placeholder="Type a message..."
              rows="1"
              ref="messageInput"
            />
            <button @click="sendMessage" class="send-btn" :disabled="!canSend">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path d="M2 10l18-8-8 18-2-10-10-2z"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <footer class="room-footer">
      <div class="footer-content">
        <!-- Audio Mode Selector -->
        <div class="audio-mode-selector">
          <button @click="showAudioModeMenu = !showAudioModeMenu" class="mode-button" :title="`Current mode: ${getAudioModeLabel(settingsStore.audioInputMode)}`">
            <span v-if="settingsStore.audioInputMode === 'always'">🎤</span>
            <span v-else-if="settingsStore.audioInputMode === 'ptt'">⌨️</span>
            <span v-else-if="settingsStore.audioInputMode === 'vad'">🔊</span>
            <span class="mode-label">{{ getAudioModeLabel(settingsStore.audioInputMode) }}</span>
            <span v-if="isVoiceActive && (settingsStore.audioInputMode === 'ptt' || settingsStore.audioInputMode === 'vad')" class="voice-indicator"></span>
          </button>

          <!-- Mode Menu -->
          <div v-if="showAudioModeMenu" class="mode-menu">
            <button
              v-for="mode in ['always', 'ptt', 'vad']"
              :key="mode"
              @click="changeAudioInputMode(mode)"
              class="mode-option"
              :class="{ active: settingsStore.audioInputMode === mode }"
            >
              <span v-if="mode === 'always'">🎤</span>
              <span v-else-if="mode === 'ptt'">⌨️</span>
              <span v-else>🔊</span>
              <span>{{ getAudioModeLabel(mode) }}</span>
              <span v-if="mode === 'ptt'" class="hint">Space</span>
              <span v-if="mode === 'vad'" class="hint">Auto</span>
            </button>
          </div>
        </div>

        <MediaControls
          :media-state="roomStore.mediaState"
          @toggle-audio="handleToggleAudio"
          @toggle-video="handleToggleVideo"
          @toggle-screen="handleToggleScreen"
          @leave="handleLeave"
        />

        <!-- Hotkeys Help -->
        <div class="hotkeys-hint">
          <span title="Keyboard Shortcuts">⌨️ Hotkeys: Ctrl+D (Mic) | Ctrl+E (Video) | Ctrl+S (Screen) | M (Mode)</span>
        </div>
      </div>
    </footer>

    <!-- Error Modal -->
    <div v-if="error" class="modal-overlay" @click="error = null">
      <div class="modal error-modal" @click.stop>
        <h3>Error</h3>
        <p>{{ error }}</p>
        <button @click="error = null" class="primary">OK</button>
      </div>
    </div>

    <!-- Image Modal -->
    <div v-if="imageModalUrl" class="modal-overlay" @click="imageModalUrl = null">
      <div class="image-modal" @click.stop>
        <button @click="imageModalUrl = null" class="close-modal">×</button>
        <img :src="imageModalUrl" alt="Full size image" />
      </div>
    </div>

    <!-- Source Picker Modal -->
    <SourcePicker
      :show="showSourcePicker"
      :sources="screenSources"
      @select="handleSourceSelect"
      @cancel="showSourcePicker = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useRoomStore } from '@/stores/room'
import { useSettingsStore } from '@/stores/settings'
import VideoGrid from '@/components/VideoGrid.vue'
import MediaControls from '@/components/MediaControls.vue'
import SourcePicker from '@/components/SourcePicker.vue'
import ws from '@/services/websocket'
import webrtc from '@/services/webrtc'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const roomStore = useRoomStore()

const error = ref(null)
const showChat = ref(false)
const messages = ref([])
const messageText = ref('')
const imagePreview = ref(null)
const imageFile = ref(null)
const unreadMessages = ref(0)
const messagesContainer = ref(null)
const messageInput = ref(null)
const fileInput = ref(null)
const imageModalUrl = ref(null)
const showSourcePicker = ref(false)
const screenSources = ref([])
const showAudioModeMenu = ref(false)
const isVoiceActive = ref(false)
const settingsStore = useSettingsStore()

// Computed
const participantCountDisplay = computed(() => {
  // Total count includes self + remote participants
  const total = roomStore.participants.length + 1
  return total === 1 ? '1 participant' : `${total} participants`
})

const canSend = computed(() => {
  return messageText.value.trim() || imagePreview.value
})

// Watch for chat visibility to reset unread count
watch(showChat, (isVisible) => {
  if (isVisible) {
    unreadMessages.value = 0
    nextTick(() => scrollToBottom())
  }
})

onMounted(async () => {
  try {
    // If not already connected, join the room
    if (!roomStore.isConnected) {
      const roomId = parseInt(route.params.id)
      await roomStore.joinRoom(roomId, userStore.user.id)
    }

    // Setup chat message handler
    ws.on('chat', handleChatMessage)

    // Setup keyboard shortcuts
    window.addEventListener('keydown', handleKeyDown)
    window.addEventListener('keyup', handleKeyUp)

    // Setup VAD callback
    webrtc.onVoiceActivityChange = (isActive) => {
      isVoiceActive.value = isActive
    }

    // Apply saved audio input mode
    webrtc.setAudioInputMode(settingsStore.audioInputMode)
    webrtc.setVADThreshold(settingsStore.vadThreshold)
  } catch (err) {
    console.error('Failed to setup room:', err)
    const errorMessage = err?.message || err?.toString() || 'Failed to join room'
    error.value = `Failed to join room: ${errorMessage}`
    setTimeout(() => {
      router.push('/home')
    }, 3000)
  }
})

onBeforeUnmount(async () => {
  // Remove keyboard event listeners
  window.removeEventListener('keydown', handleKeyDown)
  window.removeEventListener('keyup', handleKeyUp)

  if (roomStore.isConnected) {
    await roomStore.leaveRoom(userStore.user.id)
  }
})

async function handleToggleAudio() {
  try {
    await roomStore.toggleAudio()
  } catch (err) {
    error.value = 'Failed to toggle audio: ' + err.message
  }
}

async function handleToggleVideo() {
  try {
    await roomStore.toggleVideo()
  } catch (err) {
    error.value = 'Failed to toggle video: ' + err.message
  }
}

async function handleToggleScreen() {
  try {
    // If turning off, just toggle off
    if (roomStore.mediaState.screen) {
      await roomStore.toggleScreenShare()
      return
    }

    // If turning on, show source picker in Electron
    if (window.electronAPI && window.electronAPI.isElectron) {
      screenSources.value = await webrtc.getDesktopSources()
      if (screenSources.value.length === 0) {
        error.value = 'No screen sources available'
        return
      }
      showSourcePicker.value = true
    } else {
      // Browser: use native picker
      await roomStore.toggleScreenShare()
    }
  } catch (err) {
    error.value = 'Failed to toggle screen share: ' + err.message
  }
}

async function handleSourceSelect(source) {
  showSourcePicker.value = false
  try {
    await roomStore.toggleScreenShare(source.id)
  } catch (err) {
    error.value = 'Failed to start screen share: ' + err.message
  }
}

async function handleLeave() {
  try {
    await roomStore.leaveRoom(userStore.user.id)
    router.push('/home')
  } catch (err) {
    console.error('Error leaving room:', err)
    router.push('/home')
  }
}

// Chat functions
function handleChatMessage(data) {
  const message = {
    id: Date.now() + Math.random(),
    userId: data.userId,
    peerId: data.peerId,
    text: data.message,
    image: data.image,
    timestamp: data.timestamp || Date.now()
  }

  messages.value.push(message)

  if (!showChat.value) {
    unreadMessages.value++
  } else {
    nextTick(() => scrollToBottom())
  }
}

async function sendMessage() {
  if (!canSend.value) return

  let imageData = null

  // Convert image to base64 if present
  if (imageFile.value) {
    imageData = await fileToBase64(imageFile.value)
  }

  // Send via WebSocket
  ws.sendChat({
    message: messageText.value.trim(),
    image: imageData
  })

  // Add to local messages immediately
  const message = {
    id: Date.now(),
    userId: userStore.user.id,
    peerId: roomStore.peerId,
    text: messageText.value.trim(),
    image: imageData,
    timestamp: Date.now()
  }

  messages.value.push(message)

  // Clear input
  messageText.value = ''
  clearImage()

  nextTick(() => {
    scrollToBottom()
    if (messageInput.value) {
      messageInput.value.focus()
    }
  })
}

function handleFileSelect(event) {
  const file = event.target.files[0]
  if (file && file.type.startsWith('image/')) {
    processImageFile(file)
  }
}

async function handlePaste(event) {
  const items = event.clipboardData?.items
  if (!items) return

  for (const item of items) {
    if (item.type.startsWith('image/')) {
      event.preventDefault()
      const file = item.getAsFile()
      if (file) {
        processImageFile(file)
      }
      break
    }
  }
}

function processImageFile(file) {
  // Check file size (max 5MB)
  if (file.size > 5 * 1024 * 1024) {
    error.value = 'Image size must be less than 5MB'
    return
  }

  imageFile.value = file
  const reader = new FileReader()
  reader.onload = (e) => {
    imagePreview.value = e.target.result
  }
  reader.readAsDataURL(file)
}

function clearImage() {
  imagePreview.value = null
  imageFile.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

function scrollToBottom() {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

function getUserName(userId) {
  if (userId === userStore.user.id) {
    return 'You'
  }
  const participant = roomStore.participants.find(p => p.userId === userId)
  return participant?.username || `User ${userId}`
}

function formatTime(timestamp) {
  const date = new Date(timestamp)
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function showImageModal(imageUrl) {
  imageModalUrl.value = imageUrl
}

// Keyboard shortcuts handler
function handleKeyDown(event) {
  // Don't trigger hotkeys when typing in chat
  if (event.target.tagName === 'TEXTAREA' || event.target.tagName === 'INPUT') {
    return
  }

  // Ctrl+D or Cmd+D: Toggle microphone
  if ((event.ctrlKey || event.metaKey) && event.key === 'd') {
    event.preventDefault()
    handleToggleAudio()
    return
  }

  // Ctrl+E or Cmd+E: Toggle video
  if ((event.ctrlKey || event.metaKey) && event.key === 'e') {
    event.preventDefault()
    handleToggleVideo()
    return
  }

  // Ctrl+S or Cmd+S: Toggle screen share
  if ((event.ctrlKey || event.metaKey) && event.key === 's') {
    event.preventDefault()
    handleToggleScreen()
    return
  }

  // Space bar: Push-to-talk (only in PTT mode)
  if (event.code === 'Space' && settingsStore.audioInputMode === 'ptt') {
    event.preventDefault()
    if (webrtc.startPushToTalk()) {
      isVoiceActive.value = true
    }
    return
  }

  // M: Toggle audio mode menu
  if (event.key === 'm' || event.key === 'M') {
    event.preventDefault()
    showAudioModeMenu.value = !showAudioModeMenu.value
    return
  }
}

function handleKeyUp(event) {
  // Space bar: Release push-to-talk
  if (event.code === 'Space' && settingsStore.audioInputMode === 'ptt') {
    event.preventDefault()
    if (webrtc.stopPushToTalk()) {
      isVoiceActive.value = false
    }
  }
}

// Audio input mode management
function changeAudioInputMode(mode) {
  settingsStore.setAudioInputMode(mode)
  webrtc.setAudioInputMode(mode)
  showAudioModeMenu.value = false

  // Update media state based on mode
  if (mode === 'always') {
    roomStore.mediaState.audio = true
  } else if (mode === 'ptt') {
    roomStore.mediaState.audio = false
  } else if (mode === 'vad') {
    roomStore.mediaState.audio = false
  }
}

function getAudioModeLabel(mode) {
  const labels = {
    'always': 'Always On',
    'ptt': 'Push to Talk',
    'vad': 'Voice Activation'
  }
  return labels[mode] || mode
}
</script>

<style scoped>
.room {
  display: flex;
  flex-direction: column;
  width: 100vw;
  height: 100vh;
  background: #1a1a1a;
}

.room-header {
  padding: 1rem 1.5rem;
  background: #2c2c2c;
  border-bottom: 1px solid #444;
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
  z-index: 10;
}

.room-info {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.room-info h2 {
  font-size: 1.25rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.room-code {
  padding: 0.35rem 0.75rem;
  background: rgba(102, 126, 234, 0.2);
  color: #667eea;
  border-radius: 0.5rem;
  font-size: 0.85rem;
  font-weight: 600;
  font-family: monospace;
}

.participant-count {
  color: #999;
  font-size: 0.9rem;
}

.room-content {
  flex: 1;
  overflow: hidden;
  display: flex;
  position: relative;
}

.room-footer {
  padding: 1.5rem;
  background: #2c2c2c;
  border-top: 1px solid #444;
  display: flex;
  justify-content: center;
}

.footer-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  max-width: 1200px;
  gap: 2rem;
}

.audio-mode-selector {
  position: relative;
  flex: 1;
  display: flex;
  justify-content: flex-start;
}

.mode-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: rgba(102, 126, 234, 0.1);
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 0.5rem;
  color: #667eea;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.9rem;
  position: relative;
}

.mode-button:hover {
  background: rgba(102, 126, 234, 0.2);
  transform: translateY(-2px);
}

.mode-label {
  font-weight: 500;
}

.voice-indicator {
  width: 10px;
  height: 10px;
  background: #4caf50;
  border-radius: 50%;
  animation: pulse 1s infinite;
  margin-left: 0.25rem;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.2);
  }
}

.mode-menu {
  position: absolute;
  bottom: 100%;
  left: 0;
  margin-bottom: 0.5rem;
  background: #2c2c2c;
  border: 1px solid #444;
  border-radius: 0.5rem;
  padding: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 200px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  z-index: 100;
}

.mode-option {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: transparent;
  border: none;
  border-radius: 0.375rem;
  color: #ccc;
  cursor: pointer;
  transition: all 0.2s;
  text-align: left;
  font-size: 0.9rem;
}

.mode-option:hover {
  background: rgba(102, 126, 234, 0.1);
  color: #fff;
}

.mode-option.active {
  background: rgba(102, 126, 234, 0.2);
  color: #667eea;
  border: 1px solid rgba(102, 126, 234, 0.3);
}

.mode-option .hint {
  margin-left: auto;
  font-size: 0.75rem;
  color: #888;
  background: rgba(255, 255, 255, 0.1);
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}

.hotkeys-hint {
  flex: 1;
  display: flex;
  justify-content: flex-end;
  color: #888;
  font-size: 0.8rem;
}

.hotkeys-hint span {
  cursor: help;
}

@media (max-width: 768px) {
  .footer-content {
    flex-direction: column;
    gap: 1rem;
  }

  .audio-mode-selector,
  .hotkeys-hint {
    justify-content: center;
  }

  .hotkeys-hint {
    font-size: 0.7rem;
  }
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #2c2c2c;
  padding: 2rem;
  border-radius: 1rem;
  width: 100%;
  max-width: 400px;
  text-align: center;
}

.error-modal {
  border: 2px solid rgba(255, 59, 48, 0.5);
}

.modal h3 {
  margin-bottom: 1rem;
  color: #ff3b30;
}

.modal p {
  margin-bottom: 1.5rem;
  color: #ccc;
}

.modal button {
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: 600;
}

.modal button.primary {
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: #fff;
}

/* Chat Styles */
.participant-count {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #999;
  font-size: 0.9rem;
}

.participant-count svg {
  opacity: 0.7;
}

.chat-toggle {
  position: relative;
  padding: 0.75rem;
  background: rgba(102, 126, 234, 0.1);
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
  color: #667eea;
}

.chat-toggle:hover {
  background: rgba(102, 126, 234, 0.2);
  transform: scale(1.05);
}

.chat-toggle.active {
  background: rgba(102, 126, 234, 0.3);
  border-color: #667eea;
}

.chat-toggle .badge {
  position: absolute;
  top: -4px;
  right: -4px;
  background: #ff3b30;
  color: white;
  border-radius: 10px;
  padding: 2px 6px;
  font-size: 0.7rem;
  font-weight: bold;
  min-width: 18px;
  text-align: center;
}

.chat-panel {
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  width: 350px;
  background: #2c2c2c;
  border-left: 1px solid #444;
  display: flex;
  flex-direction: column;
  z-index: 5;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}

.chat-header {
  padding: 1rem;
  border-bottom: 1px solid #444;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chat-header h3 {
  margin: 0;
  font-size: 1.1rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.close-btn {
  background: transparent;
  border: none;
  color: #999;
  font-size: 2rem;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.25rem;
  transition: all 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.chat-messages::-webkit-scrollbar {
  width: 6px;
}

.chat-messages::-webkit-scrollbar-track {
  background: #1a1a1a;
}

.chat-messages::-webkit-scrollbar-thumb {
  background: #667eea;
  border-radius: 3px;
}

.message {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  color: #999;
}

.username {
  font-weight: 600;
  color: #667eea;
}

.own-message .username {
  color: #764ba2;
}

.timestamp {
  font-size: 0.7rem;
}

.message-content {
  background: #3a3a3a;
  padding: 0.75rem;
  border-radius: 0.5rem;
  word-wrap: break-word;
}

.own-message .message-content {
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.2), rgba(118, 75, 162, 0.2));
  border: 1px solid rgba(102, 126, 234, 0.3);
}

.message-content p {
  margin: 0;
  color: #fff;
  font-size: 0.9rem;
  line-height: 1.4;
}

.message-image {
  max-width: 100%;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: transform 0.2s;
  display: block;
  margin-top: 0.5rem;
}

.message-image:hover {
  transform: scale(1.02);
}

.chat-input {
  border-top: 1px solid #444;
  padding: 1rem;
  background: #2c2c2c;
}

.image-preview {
  position: relative;
  margin-bottom: 0.5rem;
  border-radius: 0.5rem;
  overflow: hidden;
  max-height: 150px;
}

.image-preview img {
  max-width: 100%;
  max-height: 150px;
  display: block;
  border-radius: 0.5rem;
}

.remove-image {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  background: rgba(0, 0, 0, 0.7);
  border: none;
  color: white;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.remove-image:hover {
  background: #ff3b30;
  transform: scale(1.1);
}

.input-row {
  display: flex;
  gap: 0.5rem;
  align-items: flex-end;
}

.attach-btn {
  padding: 0.75rem;
  background: rgba(102, 126, 234, 0.1);
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 0.5rem;
  cursor: pointer;
  color: #667eea;
  transition: all 0.2s;
  flex-shrink: 0;
}

.attach-btn:hover {
  background: rgba(102, 126, 234, 0.2);
  transform: scale(1.05);
}

.input-row textarea {
  flex: 1;
  background: #3a3a3a;
  border: 1px solid #555;
  border-radius: 0.5rem;
  padding: 0.75rem;
  color: #fff;
  font-family: inherit;
  font-size: 0.9rem;
  resize: none;
  min-height: 42px;
  max-height: 120px;
  transition: border-color 0.2s;
}

.input-row textarea:focus {
  outline: none;
  border-color: #667eea;
}

.input-row textarea::placeholder {
  color: #888;
}

.send-btn {
  padding: 0.75rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  color: white;
  transition: all 0.2s;
  flex-shrink: 0;
}

.send-btn:hover:not(:disabled) {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.image-modal {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
  background: #2c2c2c;
  border-radius: 1rem;
  padding: 1rem;
}

.image-modal img {
  max-width: 100%;
  max-height: 85vh;
  display: block;
  border-radius: 0.5rem;
}

.close-modal {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: rgba(0, 0, 0, 0.7);
  border: none;
  color: white;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  z-index: 10;
}

.close-modal:hover {
  background: #ff3b30;
  transform: scale(1.1);
}

.with-chat {
  margin-right: 350px;
}

@media (max-width: 768px) {
  .chat-panel {
    width: 100%;
  }

  .with-chat {
    margin-right: 0;
  }
}
</style>
