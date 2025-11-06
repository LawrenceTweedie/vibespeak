import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useSettingsStore = defineStore('settings', () => {
  // Device IDs
  const selectedAudioInput = ref(null)
  const selectedVideoInput = ref(null)
  const selectedAudioOutput = ref(null)

  // Audio input mode: 'always', 'ptt' (push-to-talk), 'vad' (voice activation)
  const audioInputMode = ref('always')
  const vadThreshold = ref(30) // Voice activation threshold (0-100)

  // Available devices
  const audioInputDevices = ref([])
  const videoInputDevices = ref([])
  const audioOutputDevices = ref([])

  // Load settings from localStorage
  function loadSettings() {
    const saved = localStorage.getItem('vibespeak_settings')
    if (saved) {
      try {
        const settings = JSON.parse(saved)
        selectedAudioInput.value = settings.audioInput || null
        selectedVideoInput.value = settings.videoInput || null
        selectedAudioOutput.value = settings.audioOutput || null
        audioInputMode.value = settings.audioInputMode || 'always'
        vadThreshold.value = settings.vadThreshold || 30
      } catch (error) {
        console.error('Failed to load settings:', error)
      }
    }
  }

  // Save settings to localStorage
  function saveSettings() {
    const settings = {
      audioInput: selectedAudioInput.value,
      videoInput: selectedVideoInput.value,
      audioOutput: selectedAudioOutput.value,
      audioInputMode: audioInputMode.value,
      vadThreshold: vadThreshold.value
    }
    localStorage.setItem('vibespeak_settings', JSON.stringify(settings))
  }

  // Enumerate devices
  async function enumerateDevices() {
    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
        console.warn('Device enumeration not supported')
        return
      }

      const devices = await navigator.mediaDevices.enumerateDevices()

      audioInputDevices.value = devices.filter(d => d.kind === 'audioinput')
      videoInputDevices.value = devices.filter(d => d.kind === 'videoinput')
      audioOutputDevices.value = devices.filter(d => d.kind === 'audiooutput')

      // Set default devices if none selected
      if (!selectedAudioInput.value && audioInputDevices.value.length > 0) {
        selectedAudioInput.value = audioInputDevices.value[0].deviceId
      }
      if (!selectedVideoInput.value && videoInputDevices.value.length > 0) {
        selectedVideoInput.value = videoInputDevices.value[0].deviceId
      }
      if (!selectedAudioOutput.value && audioOutputDevices.value.length > 0) {
        selectedAudioOutput.value = audioOutputDevices.value[0].deviceId
      }
    } catch (error) {
      console.error('Failed to enumerate devices:', error)
    }
  }

  // Set audio input device
  function setAudioInput(deviceId) {
    selectedAudioInput.value = deviceId
    saveSettings()
  }

  // Set video input device
  function setVideoInput(deviceId) {
    selectedVideoInput.value = deviceId
    saveSettings()
  }

  // Set audio output device
  function setAudioOutput(deviceId) {
    selectedAudioOutput.value = deviceId
    saveSettings()
  }

  // Set audio input mode
  function setAudioInputMode(mode) {
    audioInputMode.value = mode
    saveSettings()
  }

  // Set VAD threshold
  function setVADThreshold(threshold) {
    vadThreshold.value = threshold
    saveSettings()
  }

  // Request permissions to get device labels
  async function requestPermissions() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: true
      })
      // Stop all tracks immediately
      stream.getTracks().forEach(track => track.stop())
      // Now enumerate devices with labels
      await enumerateDevices()
    } catch (error) {
      console.warn('Failed to request permissions:', error)
      // Try to enumerate without permissions (will have generic labels)
      await enumerateDevices()
    }
  }

  return {
    selectedAudioInput,
    selectedVideoInput,
    selectedAudioOutput,
    audioInputMode,
    vadThreshold,
    audioInputDevices,
    videoInputDevices,
    audioOutputDevices,
    loadSettings,
    saveSettings,
    enumerateDevices,
    setAudioInput,
    setVideoInput,
    setAudioOutput,
    setAudioInputMode,
    setVADThreshold,
    requestPermissions
  }
})
