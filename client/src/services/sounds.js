class SoundService {
  constructor() {
    this.sounds = {}
    this.enabled = true
    this.volume = 0.5

    // Initialize sounds
    this.initSounds()
  }

  initSounds() {
    // Create audio contexts for each sound
    const soundEffects = {
      micOn: this.createBeep(800, 0.1, 'sine'),
      micOff: this.createBeep(400, 0.1, 'sine'),
      videoOn: this.createBeep(1000, 0.15, 'sine'),
      videoOff: this.createBeep(500, 0.15, 'sine'),
      screenOn: this.createBeep(1200, 0.2, 'square'),
      screenOff: this.createBeep(600, 0.2, 'square'),
      joinRoom: this.createChord([523.25, 659.25, 783.99], 0.3),
      leaveRoom: this.createChord([783.99, 659.25, 523.25], 0.3),
      userJoined: this.createBeep(880, 0.2, 'sine'),
      userLeft: this.createBeep(440, 0.2, 'sine')
    }

    this.sounds = soundEffects
  }

  createBeep(frequency, duration, type = 'sine') {
    return () => {
      if (!this.enabled) return

      const audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const oscillator = audioContext.createOscillator()
      const gainNode = audioContext.createGain()

      oscillator.type = type
      oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime)

      gainNode.gain.setValueAtTime(this.volume, audioContext.currentTime)
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration)

      oscillator.connect(gainNode)
      gainNode.connect(audioContext.destination)

      oscillator.start(audioContext.currentTime)
      oscillator.stop(audioContext.currentTime + duration)

      // Clean up
      setTimeout(() => {
        audioContext.close()
      }, duration * 1000 + 100)
    }
  }

  createChord(frequencies, duration) {
    return () => {
      if (!this.enabled) return

      const audioContext = new (window.AudioContext || window.webkitAudioContext)()

      frequencies.forEach((freq, index) => {
        const oscillator = audioContext.createOscillator()
        const gainNode = audioContext.createGain()

        oscillator.type = 'sine'
        oscillator.frequency.setValueAtTime(freq, audioContext.currentTime)

        const startDelay = index * 0.05
        gainNode.gain.setValueAtTime(0, audioContext.currentTime + startDelay)
        gainNode.gain.linearRampToValueAtTime(this.volume * 0.3, audioContext.currentTime + startDelay + 0.01)
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + startDelay + duration)

        oscillator.connect(gainNode)
        gainNode.connect(audioContext.destination)

        oscillator.start(audioContext.currentTime + startDelay)
        oscillator.stop(audioContext.currentTime + startDelay + duration)
      })

      // Clean up
      setTimeout(() => {
        audioContext.close()
      }, (duration + 0.2) * 1000)
    }
  }

  play(soundName) {
    if (this.sounds[soundName]) {
      try {
        this.sounds[soundName]()
      } catch (error) {
        console.warn('Failed to play sound:', soundName, error)
      }
    }
  }

  setVolume(volume) {
    this.volume = Math.max(0, Math.min(1, volume))
  }

  setEnabled(enabled) {
    this.enabled = enabled
  }

  // Convenience methods
  playMicOn() { this.play('micOn') }
  playMicOff() { this.play('micOff') }
  playVideoOn() { this.play('videoOn') }
  playVideoOff() { this.play('videoOff') }
  playScreenOn() { this.play('screenOn') }
  playScreenOff() { this.play('screenOff') }
  playJoinRoom() { this.play('joinRoom') }
  playLeaveRoom() { this.play('leaveRoom') }
  playUserJoined() { this.play('userJoined') }
  playUserLeft() { this.play('userLeft') }
}

export default new SoundService()
