import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'
import ws from '@/services/websocket'
import webrtc from '@/services/webrtc'
import sounds from '@/services/sounds'
import { useSettingsStore } from './settings'

export const useRoomStore = defineStore('room', () => {
  const settingsStore = useSettingsStore()
  const currentRoom = ref(null)
  const participants = ref([])
  const remoteStreams = ref(new Map())
  const localStream = ref(null)
  const mediaState = ref({
    audio: true,
    video: false,
    screen: false
  })
  const peerId = ref(null)
  const currentUserId = ref(null)
  const isConnected = ref(false)

  const participantCount = computed(() => participants.value.length)

  async function createRoom(data) {
    try {
      const response = await api.createRoom(data)
      if (response.success) {
        currentRoom.value = response.data
        return response.data
      }
    } catch (error) {
      console.error('Failed to create room:', error)
      throw error
    }
  }

  async function joinRoom(roomId, userId, password = null) {
    try {
      // Store user ID for later use
      currentUserId.value = userId

      // Join room via API
      const response = await api.joinRoom(roomId, userId, password)
      if (!response.success) {
        throw new Error(response.message)
      }

      currentRoom.value = response.data

      // Try to get media stream, but don't fail if unavailable
      try {
        localStream.value = await webrtc.getMediaStream(
          mediaState.value.audio,
          mediaState.value.video,
          settingsStore.selectedAudioInput,
          settingsStore.selectedVideoInput
        )
      } catch (mediaError) {
        console.warn('Failed to get media stream, continuing without media:', mediaError)
        // Continue without media - text chat will still work
        localStream.value = null
        mediaState.value.audio = false
        mediaState.value.video = false
      }

      // Connect to WebSocket
      const wsUrl = import.meta.env.VITE_WS_URL || 'ws://localhost:8080'
      await ws.connect(wsUrl)

      // Setup WebRTC callbacks
      setupWebRTCHandlers()

      // Setup WebSocket handlers
      setupWebSocketHandlers()

      // Generate peer ID
      peerId.value = `peer_${userId}_${Date.now()}`

      // Join via WebSocket
      ws.join(roomId, userId, peerId.value, mediaState.value)

      isConnected.value = true

      // Play join sound
      sounds.playJoinRoom()

      return response.data
    } catch (error) {
      console.error('Failed to join room:', error)
      throw error
    }
  }

  async function leaveRoom(userId) {
    try {
      // Play leave sound before leaving
      sounds.playLeaveRoom()

      if (currentRoom.value) {
        await api.leaveRoom(currentRoom.value.id, userId)
      }

      // Clean up
      ws.leave()
      ws.disconnect()
      webrtc.cleanup()

      if (localStream.value) {
        localStream.value.getTracks().forEach(track => track.stop())
        localStream.value = null
      }

      currentRoom.value = null
      participants.value = []
      remoteStreams.value.clear()
      isConnected.value = false
      currentUserId.value = null
    } catch (error) {
      console.error('Failed to leave room:', error)
      throw error
    }
  }

  function setupWebRTCHandlers() {
    webrtc.onIceCandidate = (targetPeerId, candidate) => {
      ws.sendIceCandidate(targetPeerId, candidate)
    }

    webrtc.onTrack = (remotePeerId, stream) => {
      remoteStreams.value.set(remotePeerId, stream)
    }

    webrtc.onNegotiationNeeded = async (targetPeerId, description) => {
      if (description.type === 'offer') {
        ws.sendOffer(targetPeerId, description)
      }
    }

    webrtc.onPeerRemoved = (remotePeerId) => {
      remoteStreams.value.delete(remotePeerId)
    }
  }

  function setupWebSocketHandlers() {
    // Joined room
    ws.on('joined', (data) => {
      peerId.value = data.peerId
      participants.value = data.participants || []

      // Create peer connections for existing participants
      data.participants.forEach(async (participant) => {
        await webrtc.createPeerConnection(participant.peerId, false)
      })
    })

    // New peer joined
    ws.on('peer-joined', async (data) => {
      participants.value.push({
        peerId: data.peerId,
        userId: data.userId,
        audio: data.audio,
        video: data.video,
        screen: data.screen
      })

      // Play user joined sound
      sounds.playUserJoined()

      // Wait a bit for the peer to be ready
      setTimeout(async () => {
        await webrtc.createPeerConnection(data.peerId, false)
      }, 1000)
    })

    // Peer left
    ws.on('peer-left', (data) => {
      participants.value = participants.value.filter(p => p.peerId !== data.peerId)
      remoteStreams.value.delete(data.peerId)
      webrtc.removePeer(data.peerId)

      // Play user left sound
      sounds.playUserLeft()
    })

    // WebRTC signaling
    ws.on('offer', async (data) => {
      try {
        const answer = await webrtc.handleOffer(data.fromPeerId, data.sdp)
        if (answer) {
          ws.sendAnswer(data.fromPeerId, answer)
        }
      } catch (error) {
        console.error('Error handling offer:', error)
      }
    })

    ws.on('answer', async (data) => {
      await webrtc.handleAnswer(data.fromPeerId, data.sdp)
    })

    ws.on('ice-candidate', async (data) => {
      await webrtc.handleIceCandidate(data.fromPeerId, data.candidate)
    })

    // Media state changes
    ws.on('peer-media-state', (data) => {
      const participant = participants.value.find(p => p.peerId === data.peerId)
      if (participant) {
        participant.audio = data.audio
        participant.video = data.video
        participant.screen = data.screen
      }
    })
  }

  async function toggleAudio() {
    mediaState.value.audio = !mediaState.value.audio
    webrtc.toggleAudio(mediaState.value.audio)
    ws.updateMediaState(mediaState.value.audio, mediaState.value.video, mediaState.value.screen)

    // Play sound
    if (mediaState.value.audio) {
      sounds.playMicOn()
    } else {
      sounds.playMicOff()
    }

    if (currentRoom.value && currentUserId.value) {
      await api.updateMediaState(currentRoom.value.id, currentUserId.value, {
        audio_enabled: mediaState.value.audio
      })
    }
  }

  async function toggleVideo() {
    try {
      if (!mediaState.value.video) {
        // Enable video
        if (!localStream.value || !localStream.value.getVideoTracks().length) {
          localStream.value = await webrtc.getMediaStream(
            mediaState.value.audio,
            true,
            settingsStore.selectedAudioInput,
            settingsStore.selectedVideoInput
          )
        }
      }

      mediaState.value.video = !mediaState.value.video
      webrtc.toggleVideo(mediaState.value.video)
      ws.updateMediaState(mediaState.value.audio, mediaState.value.video, mediaState.value.screen)

      // Play sound
      if (mediaState.value.video) {
        sounds.playVideoOn()
      } else {
        sounds.playVideoOff()
      }

      if (currentRoom.value && currentUserId.value) {
        await api.updateMediaState(currentRoom.value.id, currentUserId.value, {
          video_enabled: mediaState.value.video
        })
      }
    } catch (error) {
      console.warn('Failed to toggle video:', error)
      mediaState.value.video = false
      throw error
    }
  }

  async function toggleScreenShare(sourceId = null) {
    try {
      mediaState.value.screen = !mediaState.value.screen

      if (mediaState.value.screen) {
        await webrtc.startScreenShare(sourceId)
        sounds.playScreenOn()
      } else {
        webrtc.stopScreenShare()
        sounds.playScreenOff()
      }

      ws.updateMediaState(mediaState.value.audio, mediaState.value.video, mediaState.value.screen)

      if (currentRoom.value && currentUserId.value) {
        await api.updateMediaState(currentRoom.value.id, currentUserId.value, {
          screen_sharing: mediaState.value.screen
        })
      }
    } catch (error) {
      console.error('Failed to toggle screen share:', error)
      mediaState.value.screen = false
      throw error
    }
  }

  return {
    currentRoom,
    participants,
    remoteStreams,
    localStream,
    mediaState,
    peerId,
    currentUserId,
    isConnected,
    participantCount,
    createRoom,
    joinRoom,
    leaveRoom,
    toggleAudio,
    toggleVideo,
    toggleScreenShare
  }
})
