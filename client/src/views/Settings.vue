<template>
  <div class="settings">
    <header class="settings-header">
      <button @click="goBack" class="back-btn">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 12H5M12 19l-7-7 7-7"/>
        </svg>
      </button>
      <h1>Settings</h1>
    </header>

    <div class="settings-content">
      <!-- Audio Input -->
      <section class="settings-section">
        <h2>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path d="M10 2a3 3 0 00-3 3v5a3 3 0 006 0V5a3 3 0 00-3-3zM3 10a1 1 0 011-1h1a1 1 0 110 2H4a1 1 0 01-1-1zm12 0a1 1 0 011-1h1a1 1 0 110 2h-1a1 1 0 01-1-1z"/>
          </svg>
          Microphone
        </h2>
        <select
          v-model="settingsStore.selectedAudioInput"
          @change="handleAudioInputChange"
          class="device-select"
        >
          <option value="">Default</option>
          <option
            v-for="device in settingsStore.audioInputDevices"
            :key="device.deviceId"
            :value="device.deviceId"
          >
            {{ device.label || `Microphone ${device.deviceId.substring(0, 8)}` }}
          </option>
        </select>
        <button @click="testAudio" class="test-btn" :disabled="!settingsStore.selectedAudioInput">
          {{ audioTesting ? 'Testing...' : 'Test Microphone' }}
        </button>
        <div v-if="audioTesting" class="audio-level">
          <div class="audio-level-bar" :style="{ width: audioLevel + '%' }"></div>
        </div>
      </section>

      <!-- Video Input -->
      <section class="settings-section">
        <h2>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path d="M2 6a2 2 0 012-2h6a2 2 0 012 2v8a2 2 0 01-2 2H4a2 2 0 01-2-2V6zm12.553 1.106A1 1 0 0014 8v4a1 1 0 00.553.894l2 1A1 1 0 0018 13V7a1 1 0 00-1.447-.894l-2 1z"/>
          </svg>
          Camera
        </h2>
        <select
          v-model="settingsStore.selectedVideoInput"
          @change="handleVideoInputChange"
          class="device-select"
        >
          <option value="">Default</option>
          <option
            v-for="device in settingsStore.videoInputDevices"
            :key="device.deviceId"
            :value="device.deviceId"
          >
            {{ device.label || `Camera ${device.deviceId.substring(0, 8)}` }}
          </option>
        </select>
        <button @click="testVideo" class="test-btn" :disabled="!settingsStore.selectedVideoInput">
          {{ videoTesting ? 'Stop Preview' : 'Test Camera' }}
        </button>
        <video v-if="videoTesting" ref="videoPreview" autoplay playsinline class="video-preview"></video>
      </section>

      <!-- Audio Output -->
      <section class="settings-section">
        <h2>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path d="M18 3a1 1 0 00-1.196-.98l-10 2A1 1 0 006 5v9.114A4.369 4.369 0 005 14c-1.657 0-3 .895-3 2s1.343 2 3 2 3-.895 3-2V7.82l8-1.6v5.894A4.37 4.37 0 0015 12c-1.657 0-3 .895-3 2s1.343 2 3 2 3-.895 3-2V3z"/>
          </svg>
          Speakers
        </h2>
        <select
          v-model="settingsStore.selectedAudioOutput"
          @change="handleAudioOutputChange"
          class="device-select"
        >
          <option value="">Default</option>
          <option
            v-for="device in settingsStore.audioOutputDevices"
            :key="device.deviceId"
            :value="device.deviceId"
          >
            {{ device.label || `Speaker ${device.deviceId.substring(0, 8)}` }}
          </option>
        </select>
        <button @click="testSound" class="test-btn">
          {{ soundTesting ? 'Playing...' : 'Test Sound' }}
        </button>
      </section>

      <!-- Screen Share Options -->
      <section class="settings-section">
        <h2>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
          </svg>
          Screen Sharing
        </h2>
        <p class="section-description">
          When you click "Share Screen" in a room, you'll be able to choose:
        </p>
        <ul class="feature-list">
          <li>🖥️ Entire Screen - Share your whole desktop</li>
          <li>🪟 Window - Share a specific application window</li>
          <li>📑 Browser Tab - Share a specific tab (browser only)</li>
        </ul>
        <p class="info-note">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
          </svg>
          The selection dialog appears automatically when sharing
        </p>
      </section>

      <!-- Refresh Devices -->
      <section class="settings-section">
        <button @click="refreshDevices" class="refresh-btn" :disabled="refreshing">
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/>
          </svg>
          {{ refreshing ? 'Refreshing...' : 'Refresh Devices' }}
        </button>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { useSettingsStore } from '@/stores/settings'

const router = useRouter()
const settingsStore = useSettingsStore()

const audioTesting = ref(false)
const videoTesting = ref(false)
const soundTesting = ref(false)
const refreshing = ref(false)
const audioLevel = ref(0)
const videoPreview = ref(null)

let audioContext = null
let analyser = null
let audioStream = null
let videoStream = null
let animationFrame = null

onMounted(async () => {
  settingsStore.loadSettings()
  await settingsStore.requestPermissions()
})

onBeforeUnmount(() => {
  stopAudioTest()
  stopVideoTest()
})

function goBack() {
  router.push('/home')
}

function handleAudioInputChange() {
  settingsStore.saveSettings()
}

function handleVideoInputChange() {
  settingsStore.saveSettings()
}

function handleAudioOutputChange() {
  settingsStore.saveSettings()
}

async function testAudio() {
  if (audioTesting.value) {
    stopAudioTest()
    return
  }

  try {
    audioTesting.value = true
    const constraints = {
      audio: settingsStore.selectedAudioInput
        ? { deviceId: { exact: settingsStore.selectedAudioInput } }
        : true
    }

    audioStream = await navigator.mediaDevices.getUserMedia(constraints)

    // Setup audio analysis
    audioContext = new (window.AudioContext || window.webkitAudioContext)()
    analyser = audioContext.createAnalyser()
    const source = audioContext.createMediaStreamSource(audioStream)
    source.connect(analyser)
    analyser.fftSize = 256

    const dataArray = new Uint8Array(analyser.frequencyBinCount)

    function updateLevel() {
      analyser.getByteFrequencyData(dataArray)
      const average = dataArray.reduce((a, b) => a + b) / dataArray.length
      audioLevel.value = Math.min(100, (average / 255) * 200)
      animationFrame = requestAnimationFrame(updateLevel)
    }

    updateLevel()

    // Auto stop after 5 seconds
    setTimeout(() => {
      if (audioTesting.value) {
        stopAudioTest()
      }
    }, 5000)
  } catch (error) {
    console.error('Failed to test audio:', error)
    audioTesting.value = false
    alert('Failed to access microphone: ' + error.message)
  }
}

function stopAudioTest() {
  audioTesting.value = false
  audioLevel.value = 0

  if (animationFrame) {
    cancelAnimationFrame(animationFrame)
    animationFrame = null
  }

  if (audioStream) {
    audioStream.getTracks().forEach(track => track.stop())
    audioStream = null
  }

  if (audioContext) {
    audioContext.close()
    audioContext = null
  }

  analyser = null
}

async function testVideo() {
  if (videoTesting.value) {
    stopVideoTest()
    return
  }

  try {
    videoTesting.value = true
    const constraints = {
      video: settingsStore.selectedVideoInput
        ? { deviceId: { exact: settingsStore.selectedVideoInput } }
        : true
    }

    videoStream = await navigator.mediaDevices.getUserMedia(constraints)

    // Wait for next tick to ensure ref is available
    await new Promise(resolve => setTimeout(resolve, 100))

    if (videoPreview.value) {
      videoPreview.value.srcObject = videoStream
    }
  } catch (error) {
    console.error('Failed to test video:', error)
    videoTesting.value = false
    alert('Failed to access camera: ' + error.message)
  }
}

function stopVideoTest() {
  videoTesting.value = false

  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop())
    videoStream = null
  }

  if (videoPreview.value) {
    videoPreview.value.srcObject = null
  }
}

async function testSound() {
  if (soundTesting.value) return

  soundTesting.value = true

  try {
    // Create a simple beep sound
    const context = new (window.AudioContext || window.webkitAudioContext)()
    const oscillator = context.createOscillator()
    const gainNode = context.createGain()

    oscillator.connect(gainNode)

    // Try to set output device if supported
    if (settingsStore.selectedAudioOutput && context.setSinkId) {
      await context.setSinkId(settingsStore.selectedAudioOutput)
    }

    gainNode.connect(context.destination)

    oscillator.frequency.value = 440 // A4 note
    oscillator.type = 'sine'

    gainNode.gain.setValueAtTime(0.3, context.currentTime)
    gainNode.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 1)

    oscillator.start(context.currentTime)
    oscillator.stop(context.currentTime + 1)

    setTimeout(() => {
      soundTesting.value = false
      context.close()
    }, 1000)
  } catch (error) {
    console.error('Failed to test sound:', error)
    soundTesting.value = false
    alert('Failed to play test sound: ' + error.message)
  }
}

async function refreshDevices() {
  refreshing.value = true
  try {
    await settingsStore.requestPermissions()
  } finally {
    refreshing.value = false
  }
}
</script>

<style scoped>
.settings {
  display: flex;
  flex-direction: column;
  width: 100vw;
  height: 100vh;
  background: #1a1a1a;
  color: #fff;
}

.settings-header {
  padding: 1rem 1.5rem;
  background: #2c2c2c;
  border-bottom: 1px solid #444;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.back-btn {
  background: transparent;
  border: none;
  color: #667eea;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 0.5rem;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.back-btn:hover {
  background: rgba(102, 126, 234, 0.1);
}

.settings-header h1 {
  margin: 0;
  font-size: 1.5rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.settings-content {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
  width: 100%;
}

.settings-section {
  background: #2c2c2c;
  border-radius: 1rem;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  border: 1px solid #444;
}

.settings-section h2 {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0 0 1rem 0;
  color: #667eea;
  font-size: 1.1rem;
}

.device-select {
  width: 100%;
  padding: 0.75rem;
  background: #3a3a3a;
  border: 1px solid #555;
  border-radius: 0.5rem;
  color: #fff;
  font-size: 0.95rem;
  margin-bottom: 1rem;
  cursor: pointer;
}

.device-select:focus {
  outline: none;
  border-color: #667eea;
}

.device-select option {
  background: #3a3a3a;
  color: #fff;
}

.test-btn, .refresh-btn {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  border: none;
  border-radius: 0.5rem;
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.test-btn:hover:not(:disabled), .refresh-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.test-btn:disabled, .refresh-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.audio-level {
  width: 100%;
  height: 8px;
  background: #3a3a3a;
  border-radius: 4px;
  overflow: hidden;
  margin-top: 1rem;
}

.audio-level-bar {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  transition: width 0.1s ease-out;
}

.video-preview {
  width: 100%;
  max-width: 400px;
  border-radius: 0.5rem;
  margin-top: 1rem;
  background: #000;
}

.section-description {
  color: #ccc;
  margin-bottom: 1rem;
  font-size: 0.95rem;
}

.feature-list {
  list-style: none;
  padding: 0;
  margin: 1rem 0;
}

.feature-list li {
  padding: 0.75rem;
  background: #3a3a3a;
  border-radius: 0.5rem;
  margin-bottom: 0.5rem;
  font-size: 0.95rem;
}

.info-note {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
  background: rgba(102, 126, 234, 0.1);
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 0.5rem;
  color: #667eea;
  font-size: 0.9rem;
  margin-top: 1rem;
}

@media (max-width: 768px) {
  .settings-content {
    padding: 1rem;
  }

  .settings-section {
    padding: 1rem;
  }
}
</style>
