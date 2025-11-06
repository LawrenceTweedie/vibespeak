<template>
  <div class="home">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2>VibeSpeak</h2>
        <div class="user-actions">
          <button @click="goToSettings" class="settings-btn" title="Settings">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
        <div class="user-info">
          <span>{{ userStore.user?.display_name || userStore.user?.username }}</span>
          <button @click="handleLogout" class="logout-btn">Logout</button>
        </div>
      </div>

      <div class="sidebar-content">
        <button @click="showCreateModal = true" class="create-room-btn">
          + Create Room
        </button>

        <div class="rooms-section">
          <h3>Available Rooms</h3>
          <div v-if="loading" class="loading">Loading rooms...</div>
          <div v-else-if="rooms.length === 0" class="no-rooms">
            No rooms available. Create one!
          </div>
          <div v-else class="rooms-list">
            <div
              v-for="room in rooms"
              :key="room.id"
              class="room-item"
              @click="handleJoinRoom(room)"
            >
              <div class="room-header">
                <h4>{{ room.name }}</h4>
                <span class="participant-count">
                  <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z"/>
                  </svg>
                  {{ room.participant_count || 0 }}/{{ room.max_participants }}
                </span>
              </div>
              <p v-if="room.description" class="room-description">{{ room.description }}</p>
              <div v-if="isUserInRoom(room)" class="room-code">
                Code: {{ room.room_code }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </aside>

    <main class="main-content">
      <div class="welcome">
        <h1>Welcome to VibeSpeak</h1>
        <p>Create a room or join an existing one to start communicating</p>

        <div class="features">
          <div class="feature">
            <div class="feature-icon">🎥</div>
            <h3>Video Calls</h3>
            <p>High-quality video communication</p>
          </div>
          <div class="feature">
            <div class="feature-icon">🎤</div>
            <h3>Voice Chat</h3>
            <p>Crystal clear audio</p>
          </div>
          <div class="feature">
            <div class="feature-icon">📺</div>
            <h3>Screen Sharing</h3>
            <p>Share your screen with others</p>
          </div>
        </div>
      </div>
    </main>

    <!-- Create Room Modal -->
    <div v-if="showCreateModal" class="modal-overlay" @click="showCreateModal = false">
      <div class="modal" @click.stop>
        <h2>Create Room</h2>
        <form @submit.prevent="handleCreateRoom">
          <div class="form-group">
            <label>Room Name</label>
            <input v-model="createForm.name" type="text" required />
          </div>
          <div class="form-group">
            <label>Description</label>
            <textarea v-model="createForm.description" rows="3"></textarea>
          </div>
          <div class="form-group">
            <label>Max Participants</label>
            <input v-model.number="createForm.max_participants" type="number" min="2" max="50" />
          </div>
          <div class="form-group">
            <label>
              <input v-model="createForm.is_public" type="checkbox" />
              Public Room
            </label>
          </div>
          <div v-if="!createForm.is_public" class="form-group">
            <label>Password (optional)</label>
            <input v-model="createForm.password" type="password" />
          </div>
          <div class="modal-actions">
            <button type="button" @click="showCreateModal = false">Cancel</button>
            <button type="submit" class="primary">Create</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useRoomStore } from '@/stores/room'
import api from '@/services/api'

const router = useRouter()
const userStore = useUserStore()
const roomStore = useRoomStore()

const loading = ref(false)
const rooms = ref([])
const showCreateModal = ref(false)
let refreshInterval = null

const createForm = ref({
  name: '',
  description: '',
  max_participants: 10,
  is_public: true,
  password: ''
})

onMounted(async () => {
  await loadRooms()
  // Refresh rooms every 5 seconds
  refreshInterval = setInterval(loadRooms, 5000)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})

async function loadRooms() {
  loading.value = true
  try {
    const response = await api.getRooms(userStore.user?.id)
    rooms.value = response.data || []
  } catch (error) {
    console.error('Failed to load rooms:', error)
  } finally {
    loading.value = false
  }
}

async function handleCreateRoom() {
  try {
    const data = {
      ...createForm.value,
      owner_id: userStore.user.id
    }
    await roomStore.createRoom(data)
    showCreateModal.value = false
    await loadRooms()
  } catch (error) {
    console.error('Failed to create room:', error)
    alert('Failed to create room')
  }
}

async function handleJoinRoom(room) {
  let password = null
  if (room.password_hash && !room.is_public) {
    password = prompt('Enter room password:')
    if (!password) return
  }

  try {
    await roomStore.joinRoom(room.id, userStore.user.id, password)
    router.push(`/room/${room.id}`)
  } catch (error) {
    console.error('Failed to join room:', error)
    alert('Failed to join room: ' + error.message)
  }
}

function goToSettings() {
  router.push('/settings')
}

function handleLogout() {
  userStore.logout()
  router.push('/')
}

function isUserInRoom(room) {
  // Check if user is owner or participant
  if (room.owner_id === userStore.user?.id) {
    return true
  }
  if (room.participants && room.participants.some(p => p.id === userStore.user?.id)) {
    return true
  }
  return false
}
</script>

<style scoped>
.home {
  display: flex;
  width: 100vw;
  height: 100vh;
}

.sidebar {
  width: 300px;
  background: #2c2c2c;
  border-right: 1px solid #444;
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  padding: 1.5rem;
  border-bottom: 1px solid #444;
}

.sidebar-header h2 {
  margin-bottom: 1rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.user-actions {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 0.5rem;
}

.settings-btn {
  background: rgba(102, 126, 234, 0.1);
  border: none;
  color: #667eea;
  padding: 0.5rem;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.settings-btn:hover {
  background: rgba(102, 126, 234, 0.2);
  transform: scale(1.05);
}

.user-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9rem;
}

.logout-btn {
  padding: 0.4rem 0.8rem;
  background: rgba(255, 59, 48, 0.2);
  color: #ff3b30;
  border-radius: 0.3rem;
  font-size: 0.85rem;
}

.sidebar-content {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
}

.create-room-btn {
  width: 100%;
  padding: 0.875rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: #fff;
  border-radius: 0.5rem;
  font-weight: 600;
  margin-bottom: 1.5rem;
}

.rooms-section h3 {
  margin-bottom: 1rem;
  font-size: 0.95rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #999;
}

.rooms-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.room-item {
  background: #1a1a1a;
  padding: 0.75rem;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
  border-left: 3px solid transparent;
}

.room-item:hover {
  background: #252525;
  border-left-color: #667eea;
}

.room-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
}

.room-header h4 {
  font-size: 0.95rem;
  margin: 0;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.participant-count {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.75rem;
  color: #999;
  white-space: nowrap;
}

.participant-count svg {
  opacity: 0.7;
}

.room-description {
  font-size: 0.8rem;
  color: #999;
  margin: 0.25rem 0 0 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.room-code {
  font-size: 0.7rem;
  color: #667eea;
  font-weight: 500;
  margin-top: 0.25rem;
  padding: 0.2rem 0.4rem;
  background: rgba(102, 126, 234, 0.1);
  border-radius: 0.25rem;
  display: inline-block;
}

.main-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.welcome {
  text-align: center;
  max-width: 800px;
}

.welcome h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.welcome > p {
  font-size: 1.25rem;
  color: #999;
  margin-bottom: 3rem;
}

.features {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
}

.feature {
  padding: 2rem;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 1rem;
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.feature h3 {
  margin-bottom: 0.5rem;
}

.feature p {
  color: #999;
  font-size: 0.9rem;
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
  max-width: 500px;
}

.modal h2 {
  margin-bottom: 1.5rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  color: #ccc;
}

.form-group input[type="text"],
.form-group input[type="number"],
.form-group input[type="password"],
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  background: #1a1a1a;
  border: 1px solid #444;
  border-radius: 0.5rem;
  color: #fff;
}

.form-group input[type="checkbox"] {
  margin-right: 0.5rem;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1.5rem;
}

.modal-actions button {
  flex: 1;
  padding: 0.75rem;
  border-radius: 0.5rem;
  font-weight: 600;
}

.modal-actions button:first-child {
  background: #1a1a1a;
  color: #fff;
}

.modal-actions button.primary {
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: #fff;
}

.loading,
.no-rooms {
  text-align: center;
  color: #999;
  padding: 2rem;
}
</style>
