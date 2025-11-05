<template>
  <div class="room">
    <header class="room-header">
      <div class="room-info">
        <h2>{{ roomStore.currentRoom?.name }}</h2>
        <span class="room-code">Code: {{ roomStore.currentRoom?.room_code }}</span>
        <span class="participant-count">
          {{ roomStore.participantCount + 1 }} participants
        </span>
      </div>
    </header>

    <div class="room-content">
      <VideoGrid
        :local-stream="roomStore.localStream"
        :remote-streams="roomStore.remoteStreams"
        :participants="roomStore.participants"
      />
    </div>

    <footer class="room-footer">
      <MediaControls
        :media-state="roomStore.mediaState"
        @toggle-audio="handleToggleAudio"
        @toggle-video="handleToggleVideo"
        @toggle-screen="handleToggleScreen"
        @leave="handleLeave"
      />
    </footer>

    <!-- Error Modal -->
    <div v-if="error" class="modal-overlay" @click="error = null">
      <div class="modal error-modal" @click.stop>
        <h3>Error</h3>
        <p>{{ error }}</p>
        <button @click="error = null" class="primary">OK</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useRoomStore } from '@/stores/room'
import VideoGrid from '@/components/VideoGrid.vue'
import MediaControls from '@/components/MediaControls.vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const roomStore = useRoomStore()

const error = ref(null)

onMounted(async () => {
  try {
    // If not already connected, join the room
    if (!roomStore.isConnected) {
      const roomId = parseInt(route.params.id)
      await roomStore.joinRoom(roomId, userStore.user.id)
    }
  } catch (err) {
    console.error('Failed to setup room:', err)
    error.value = err.message || 'Failed to join room'
    setTimeout(() => {
      router.push('/home')
    }, 2000)
  }
})

onBeforeUnmount(async () => {
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
    await roomStore.toggleScreenShare()
  } catch (err) {
    error.value = 'Failed to toggle screen share: ' + err.message
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
}

.room-footer {
  padding: 1.5rem;
  background: #2c2c2c;
  border-top: 1px solid #444;
  display: flex;
  justify-content: center;
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
</style>
