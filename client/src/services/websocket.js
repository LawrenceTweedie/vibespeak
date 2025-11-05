class WebSocketService {
  constructor() {
    this.ws = null
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
    this.reconnectDelay = 1000
    this.handlers = new Map()
  }

  connect(url) {
    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(url)

        this.ws.onopen = () => {
          console.log('WebSocket connected')
          this.reconnectAttempts = 0
          resolve()
        }

        this.ws.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data)
            this.handleMessage(data)
          } catch (error) {
            console.error('Failed to parse message:', error)
          }
        }

        this.ws.onerror = (error) => {
          console.error('WebSocket error:', error)
          reject(error)
        }

        this.ws.onclose = () => {
          console.log('WebSocket closed')
          this.attemptReconnect(url)
        }
      } catch (error) {
        reject(error)
      }
    })
  }

  attemptReconnect(url) {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      console.log(`Reconnecting... Attempt ${this.reconnectAttempts}`)

      setTimeout(() => {
        this.connect(url).catch((error) => {
          console.error('Reconnection failed:', error)
        })
      }, this.reconnectDelay * this.reconnectAttempts)
    } else {
      console.error('Max reconnection attempts reached')
    }
  }

  send(type, data = {}) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type, ...data }))
    } else {
      console.error('WebSocket is not connected')
    }
  }

  on(type, handler) {
    if (!this.handlers.has(type)) {
      this.handlers.set(type, [])
    }
    this.handlers.get(type).push(handler)
  }

  off(type, handler) {
    if (this.handlers.has(type)) {
      const handlers = this.handlers.get(type)
      const index = handlers.indexOf(handler)
      if (index > -1) {
        handlers.splice(index, 1)
      }
    }
  }

  handleMessage(data) {
    const { type } = data
    if (this.handlers.has(type)) {
      this.handlers.get(type).forEach(handler => handler(data))
    }
  }

  join(roomId, userId, peerId, mediaState) {
    this.send('join', {
      roomId,
      userId,
      peerId,
      audio: mediaState.audio,
      video: mediaState.video,
      screen: mediaState.screen
    })
  }

  leave() {
    this.send('leave')
  }

  sendOffer(targetPeerId, sdp) {
    this.send('offer', { targetPeerId, sdp })
  }

  sendAnswer(targetPeerId, sdp) {
    this.send('answer', { targetPeerId, sdp })
  }

  sendIceCandidate(targetPeerId, candidate) {
    this.send('ice-candidate', { targetPeerId, candidate })
  }

  updateMediaState(audio, video, screen) {
    this.send('media-state', { audio, video, screen })
  }

  sendChat(message) {
    this.send('chat', { message })
  }

  disconnect() {
    if (this.ws) {
      this.ws.close()
      this.ws = null
    }
    this.handlers.clear()
  }
}

export default new WebSocketService()
