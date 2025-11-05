import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useUserStore = defineStore('user', () => {
  const user = ref(null)
  const isAuthenticated = ref(false)

  async function register(data) {
    try {
      const response = await api.register(data)
      if (response.success) {
        user.value = response.data
        isAuthenticated.value = true
        localStorage.setItem('user', JSON.stringify(response.data))
        return response
      }
    } catch (error) {
      console.error('Registration failed:', error)
      throw error
    }
  }

  async function login(data) {
    try {
      const response = await api.login(data)
      if (response.success) {
        user.value = response.data
        isAuthenticated.value = true
        localStorage.setItem('user', JSON.stringify(response.data))
        return response
      }
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    }
  }

  function logout() {
    user.value = null
    isAuthenticated.value = false
    localStorage.removeItem('user')
  }

  function loadFromStorage() {
    const stored = localStorage.getItem('user')
    if (stored) {
      try {
        user.value = JSON.parse(stored)
        isAuthenticated.value = true
      } catch (error) {
        console.error('Failed to load user from storage:', error)
        localStorage.removeItem('user')
      }
    }
  }

  return {
    user,
    isAuthenticated,
    register,
    login,
    logout,
    loadFromStorage
  }
})
