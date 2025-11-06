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

  async getScreenStream() {
    try {
      // Check if mediaDevices is available
      if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
        throw new Error('Screen sharing is not supported. Please use HTTPS or download the desktop app.')
      }

      this.screenStream = await navigator.mediaDevices.getDisplayMedia({
        video: {
          cursor: 'always'
        },
        audio: false
      })

      // Handle when user stops sharing via browser UI
      this.screenStream.getVideoTracks()[0].onended = () => {
        this.stopScreenShare()
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
      await peer.connection.setRemoteDescription(answer)
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

  async startScreenShare() {
    try {
      this.screenStream = await this.getScreenStream()

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

  // Callback handlers (to be set by the application)
  onIceCandidate = (peerId, candidate) => {}
  onTrack = (peerId, stream) => {}
  onNegotiationNeeded = (peerId, description) => {}
  onPeerRemoved = (peerId) => {}
}

export default new WebRTCService()
