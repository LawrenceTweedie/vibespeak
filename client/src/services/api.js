import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

export default {
  // Users
  async register(data) {
    const response = await api.post('/users/register', data)
    return response.data
  },

  async login(data) {
    const response = await api.post('/users/login', data)
    return response.data
  },

  async getUsers() {
    const response = await api.get('/users/list')
    return response.data
  },

  // Rooms
  async createRoom(data) {
    const response = await api.post('/rooms/create', data)
    return response.data
  },

  async getRooms(userId) {
    const response = await api.get('/rooms/list', { params: { user_id: userId } })
    return response.data
  },

  async getRoom(roomId) {
    const response = await api.get(`/rooms/${roomId}`)
    return response.data
  },

  async getRoomByCode(code) {
    const response = await api.get(`/rooms/code/${code}`)
    return response.data
  },

  async joinRoom(roomId, userId, password) {
    const response = await api.post('/rooms/join', { room_id: roomId, user_id: userId, password })
    return response.data
  },

  async leaveRoom(roomId, userId) {
    const response = await api.post('/rooms/leave', { room_id: roomId, user_id: userId })
    return response.data
  },

  async updateMediaState(roomId, userId, state) {
    const response = await api.post('/rooms/media', {
      room_id: roomId,
      user_id: userId,
      ...state
    })
    return response.data
  },

  async checkHealth() {
    const response = await api.get('/health')
    return response.data
  }
}
