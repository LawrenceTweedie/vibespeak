class WebRTCService {
  constructor() {
    this.localStream = null
    this.screenStream = null
    this.peers = new Map()
    this.configuration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
      ]
    }

    // Audio input modes: 'always', 'ptt' (push-to-talk), 'vad' (voice activation)
    this.audioInputMode = 'always'
    this.isPushToTalkActive = false
    this.isVoiceDetected = false

    // VAD (Voice Activity Detection) settings
    this.audioContext = null
    this.analyser = null
    this.vadThreshold = 30 // Voice activity threshold (0-100)
    this.vadCheckInterval = null
    this.smoothingFactor = 0.8
    this.minNoiseLevel = 0
    this.maxNoiseLevel = 0
    this.calibrationSamples = 0
  }

  async getMediaStream(audio = true, video = true, audioDeviceId = null, videoDeviceId = null) {
    try {
      // Check if mediaDevices is available
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('WebRTC is not supported. Please use HTTPS or download the desktop app.')
      }

      const constraints = {
        audio: audio ? {
          deviceId: audioDeviceId ? { exact: audioDeviceId } : undefined,
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        } : false,
        video: video ? {
          deviceId: videoDeviceId ? { exact: videoDeviceId } : undefined,
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 30 }
        } : false
      }

      this.localStream = await navigator.mediaDevices.getUserMedia(constraints)
      return this.localStream
    } catch (error) {
      console.error('Failed to get media stream:', error)
      throw error
    }
  }

  async getDesktopSources() {
    if (window.electronAPI && window.electronAPI.isElectron) {
      const sources = await window.electronAPI.getDesktopSources()
      return sources || []
    }
    return []
  }

  async getScreenStream(sourceId = null) {
    try {
      // Check if running in Electron
      if (window.electronAPI && window.electronAPI.isElectron) {
        if (!sourceId) {
          throw new Error('Source ID is required for Electron')
        }

        // Use Electron's desktopCapturer with selected source
        this.screenStream = await navigator.mediaDevices.getUserMedia({
          audio: false,
          video: {
            mandatory: {
              chromeMediaSource: 'desktop',
              chromeMediaSourceId: sourceId,
              minWidth: 1280,
              maxWidth: 1920,
              minHeight: 720,
              maxHeight: 1080
            }
          }
        })
      } else {
        // Use standard browser API
        if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
          throw new Error('Screen sharing is not supported. Please use HTTPS or download the desktop app.')
        }

        this.screenStream = await navigator.mediaDevices.getDisplayMedia({
          video: {
            cursor: 'always',
            displaySurface: 'monitor'
          },
          audio: false
        })
      }

      // Handle when user stops sharing via browser UI
      if (this.screenStream && this.screenStream.getVideoTracks()[0]) {
        this.screenStream.getVideoTracks()[0].onended = () => {
          this.stopScreenShare()
        }
      }

      return this.screenStream
    } catch (error) {
      console.error('Failed to get screen stream:', error)
      throw error
    }
  }

  async createPeerConnection(peerId, polite = false) {
    const pc = new RTCPeerConnection(this.configuration)

    const peer = {
      connection: pc,
      polite,
      makingOffer: false,
      ignoreOffer: false,
      isSettingRemoteAnswerPending: false
    }

    this.peers.set(peerId, peer)

    // Add local tracks
    if (this.localStream) {
      this.localStream.getTracks().forEach(track => {
        pc.addTrack(track, this.localStream)
      })
    }

    if (this.screenStream) {
      this.screenStream.getTracks().forEach(track => {
        pc.addTrack(track, this.screenStream)
      })
    }

    // Setup event handlers
    this.setupPeerConnectionHandlers(peerId, pc)

    return pc
  }

  setupPeerConnectionHandlers(peerId, pc) {
    // ICE candidate handler
    pc.onicecandidate = (event) => {
      if (event.candidate) {
        this.onIceCandidate(peerId, event.candidate)
      }
    }

    // Track handler (receive remote stream)
    pc.ontrack = (event) => {
      this.onTrack(peerId, event.streams[0])
    }

    // Connection state handler
    pc.onconnectionstatechange = () => {
      console.log(`Peer ${peerId} connection state: ${pc.connectionState}`)

      if (pc.connectionState === 'failed' ||
          pc.connectionState === 'disconnected' ||
          pc.connectionState === 'closed') {
        this.removePeer(peerId)
      }
    }

    // ICE connection state handler
    pc.oniceconnectionstatechange = () => {
      console.log(`Peer ${peerId} ICE state: ${pc.iceConnectionState}`)
    }

    // Negotiation needed handler
    pc.onnegotiationneeded = async () => {
      try {
        const peer = this.peers.get(peerId)
        if (!peer) return

        peer.makingOffer = true
        await pc.setLocalDescription()
        this.onNegotiationNeeded(peerId, pc.localDescription)
      } catch (error) {
        console.error('Negotiation error:', error)
      } finally {
        const peer = this.peers.get(peerId)
        if (peer) peer.makingOffer = false
      }
    }
  }

  async handleOffer(peerId, offer) {
    const peer = this.peers.get(peerId)
    if (!peer) {
      await this.createPeerConnection(peerId, true)
      return this.handleOffer(peerId, offer)
    }

    const pc = peer.connection
    const offerCollision = peer.makingOffer || pc.signalingState !== 'stable'

    peer.ignoreOffer = !peer.polite && offerCollision
    if (peer.ignoreOffer) {
      return
    }

    try {
      await pc.setRemoteDescription(offer)
      const answer = await pc.createAnswer()
      await pc.setLocalDescription(answer)
      return answer
    } catch (error) {
      console.error('Error handling offer:', error)
      throw error
    }
  }

  async handleAnswer(peerId, answer) {
    const peer = this.peers.get(peerId)
    if (!peer) return

    try {
      // Only set remote description if we're expecting an answer
      if (peer.connection.signalingState === 'have-local-offer') {
        await peer.connection.setRemoteDescription(answer)
      } else {
        console.warn(`Peer ${peerId} not in correct state for answer: ${peer.connection.signalingState}`)
      }
    } catch (error) {
      console.error('Error handling answer:', error)
    }
  }

  async handleIceCandidate(peerId, candidate) {
    const peer = this.peers.get(peerId)
    if (!peer) return

    try {
      await peer.connection.addIceCandidate(candidate)
    } catch (error) {
      console.error('Error adding ICE candidate:', error)
    }
  }

  toggleAudio(enabled) {
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach(track => {
        track.enabled = enabled
      })
    }
  }

  toggleVideo(enabled) {
    if (this.localStream) {
      this.localStream.getVideoTracks().forEach(track => {
        track.enabled = enabled
      })
    }
  }

  async startScreenShare(sourceId = null) {
    try {
      this.screenStream = await this.getScreenStream(sourceId)

      // Replace video track in all peer connections
      const screenTrack = this.screenStream.getVideoTracks()[0]
      this.peers.forEach((peer) => {
        const sender = peer.connection.getSenders().find(s => s.track?.kind === 'video')
        if (sender) {
          sender.replaceTrack(screenTrack)
        }
      })

      return this.screenStream
    } catch (error) {
      console.error('Failed to start screen share:', error)
      throw error
    }
  }

  stopScreenShare() {
    if (this.screenStream) {
      this.screenStream.getTracks().forEach(track => track.stop())
      this.screenStream = null

      // Switch back to camera
      if (this.localStream) {
        const videoTrack = this.localStream.getVideoTracks()[0]
        if (videoTrack) {
          this.peers.forEach((peer) => {
            const sender = peer.connection.getSenders().find(s => s.track?.kind === 'video')
            if (sender) {
              sender.replaceTrack(videoTrack)
            }
          })
        }
      }
    }
  }

  removePeer(peerId) {
    const peer = this.peers.get(peerId)
    if (peer) {
      peer.connection.close()
      this.peers.delete(peerId)
      this.onPeerRemoved(peerId)
    }
  }

  cleanup() {
    // Stop VAD
    this.stopVAD()

    // Stop all tracks
    if (this.localStream) {
      this.localStream.getTracks().forEach(track => track.stop())
      this.localStream = null
    }

    if (this.screenStream) {
      this.screenStream.getTracks().forEach(track => track.stop())
      this.screenStream = null
    }

    // Close all peer connections
    this.peers.forEach((peer, peerId) => {
      peer.connection.close()
    })
    this.peers.clear()
  }

  // Audio input mode management
  setAudioInputMode(mode) {
    this.audioInputMode = mode

    if (mode === 'always') {
      this.stopVAD()
      this.updateAudioState(true)
    } else if (mode === 'ptt') {
      this.stopVAD()
      this.updateAudioState(false)
    } else if (mode === 'vad') {
      this.isPushToTalkActive = false
      this.startVAD()
    }
  }

  getAudioInputMode() {
    return this.audioInputMode
  }

  // Push-to-talk controls
  startPushToTalk() {
    if (this.audioInputMode === 'ptt') {
      this.isPushToTalkActive = true
      this.updateAudioState(true)
      return true
    }
    return false
  }

  stopPushToTalk() {
    if (this.audioInputMode === 'ptt') {
      this.isPushToTalkActive = false
      this.updateAudioState(false)
      return true
    }
    return false
  }

  // Voice Activity Detection
  startVAD() {
    if (!this.localStream) return

    try {
      // Create audio context if not exists
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      }

      // Create analyser
      this.analyser = this.audioContext.createAnalyser()
      this.analyser.fftSize = 2048
      this.analyser.smoothingTimeConstant = this.smoothingFactor

      // Connect audio source
      const source = this.audioContext.createMediaStreamSource(this.localStream)
      source.connect(this.analyser)

      // Reset calibration
      this.calibrationSamples = 0
      this.minNoiseLevel = Infinity
      this.maxNoiseLevel = 0

      // Start checking for voice activity
      this.vadCheckInterval = setInterval(() => {
        this.checkVoiceActivity()
      }, 100) // Check every 100ms
    } catch (error) {
      console.error('Failed to start VAD:', error)
    }
  }

  stopVAD() {
    if (this.vadCheckInterval) {
      clearInterval(this.vadCheckInterval)
      this.vadCheckInterval = null
    }

    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close().catch(err => console.error('Error closing audio context:', err))
      this.audioContext = null
    }

    this.analyser = null
    this.isVoiceDetected = false
  }

  checkVoiceActivity() {
    if (!this.analyser) return

    const dataArray = new Uint8Array(this.analyser.frequencyBinCount)
    this.analyser.getByteFrequencyData(dataArray)

    // Calculate average volume
    let sum = 0
    for (let i = 0; i < dataArray.length; i++) {
      sum += dataArray[i]
    }
    const average = sum / dataArray.length

    // Calibration phase (first 20 samples)
    if (this.calibrationSamples < 20) {
      this.minNoiseLevel = Math.min(this.minNoiseLevel, average)
      this.maxNoiseLevel = Math.max(this.maxNoiseLevel, average)
      this.calibrationSamples++
      return
    }

    // Adaptive threshold based on calibration
    const range = this.maxNoiseLevel - this.minNoiseLevel
    const adaptiveThreshold = this.minNoiseLevel + (range * this.vadThreshold / 100)

    // Detect voice activity
    const wasVoiceDetected = this.isVoiceDetected
    this.isVoiceDetected = average > adaptiveThreshold

    // Update audio state only on changes
    if (this.isVoiceDetected !== wasVoiceDetected) {
      this.updateAudioState(this.isVoiceDetected)

      // Callback for UI updates
      if (this.onVoiceActivityChange) {
        this.onVoiceActivityChange(this.isVoiceDetected, average, adaptiveThreshold)
      }
    }
  }

  setVADThreshold(threshold) {
    this.vadThreshold = Math.max(0, Math.min(100, threshold))
  }

  getVADThreshold() {
    return this.vadThreshold
  }

  // Update audio track enabled state
  updateAudioState(enabled) {
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach(track => {
        track.enabled = enabled
      })
    }
  }

  // Callback handlers (to be set by the application)
  onIceCandidate = (peerId, candidate) => {}
  onTrack = (peerId, stream) => {}
  onNegotiationNeeded = (peerId, description) => {}
  onPeerRemoved = (peerId) => {}
  onVoiceActivityChange = (isActive, level, threshold) => {}
}

export default new WebRTCService()
