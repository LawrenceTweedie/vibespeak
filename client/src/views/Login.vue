<template>
  <div class="login-container">
    <div class="login-box">
      <h1>VibeSpeak</h1>
      <p class="subtitle">Real-time Communication Platform</p>

      <div class="tabs">
        <button
          :class="{ active: mode === 'login' }"
          @click="mode = 'login'"
        >
          Login
        </button>
        <button
          :class="{ active: mode === 'register' }"
          @click="mode = 'register'"
        >
          Register
        </button>
      </div>

      <form @submit.prevent="handleSubmit">
        <div class="form-group">
          <input
            v-model="form.username"
            type="text"
            placeholder="Username"
            required
          />
        </div>

        <div v-if="mode === 'register'" class="form-group">
          <input
            v-model="form.email"
            type="email"
            placeholder="Email"
            required
          />
        </div>

        <div class="form-group">
          <input
            v-model="form.password"
            type="password"
            placeholder="Password"
            required
          />
        </div>

        <div v-if="mode === 'register'" class="form-group">
          <input
            v-model="form.display_name"
            type="text"
            placeholder="Display Name (optional)"
          />
        </div>

        <div v-if="error" class="error">{{ error }}</div>

        <button type="submit" class="submit-btn" :disabled="loading">
          {{ loading ? 'Please wait...' : mode === 'login' ? 'Login' : 'Register' }}
        </button>
      </form>

      <div class="demo-info">
        <p>Demo credentials:</p>
        <p><strong>Username:</strong> demo | <strong>Password:</strong> password</p>
      </div>

      <!-- HTTP Warning -->
      <div v-if="!isSecure" class="http-warning">
        <p>⚠️ <strong>Note:</strong> Video/audio requires HTTPS</p>
        <router-link to="/download" class="download-link">
          Download Desktop App
        </router-link>
      </div>

      <!-- Download Link -->
      <div class="download-link-section">
        <router-link to="/download" class="text-download-link">
          📥 Download Desktop App
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'

const isSecure = computed(() => {
  return window.location.protocol === 'https:' ||
         window.location.hostname === 'localhost' ||
         window.location.hostname === '127.0.0.1'
})

const router = useRouter()
const userStore = useUserStore()

const mode = ref('login')
const loading = ref(false)
const error = ref('')

const form = ref({
  username: '',
  email: '',
  password: '',
  display_name: ''
})

async function handleSubmit() {
  error.value = ''
  loading.value = true

  try {
    if (mode.value === 'login') {
      await userStore.login({
        username: form.value.username,
        password: form.value.password
      })
    } else {
      await userStore.register(form.value)
    }

    router.push('/home')
  } catch (err) {
    error.value = err.response?.data?.message || 'An error occurred'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100vw;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-box {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  padding: 2.5rem;
  border-radius: 1rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 400px;
}

h1 {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
  text-align: center;
  background: linear-gradient(45deg, #fff, #e0e0e0);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.subtitle {
  text-align: center;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 2rem;
  font-size: 0.95rem;
}

.tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.tabs button {
  flex: 1;
  padding: 0.75rem;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  border-radius: 0.5rem;
  font-weight: 500;
}

.tabs button.active {
  background: rgba(255, 255, 255, 0.3);
}

.form-group {
  margin-bottom: 1rem;
}

input {
  width: 100%;
  padding: 0.875rem;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 0.5rem;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font-size: 1rem;
}

input::placeholder {
  color: rgba(255, 255, 255, 0.6);
}

input:focus {
  border-color: rgba(255, 255, 255, 0.5);
  background: rgba(255, 255, 255, 0.15);
}

.error {
  background: rgba(255, 59, 48, 0.3);
  color: #fff;
  padding: 0.75rem;
  border-radius: 0.5rem;
  margin-bottom: 1rem;
  font-size: 0.9rem;
}

.submit-btn {
  width: 100%;
  padding: 0.875rem;
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: #fff;
  border-radius: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.demo-info {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
  text-align: center;
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.7);
}

.demo-info strong {
  color: #fff;
}

.http-warning {
  margin-top: 1.5rem;
  padding: 1rem;
  background: rgba(255, 152, 0, 0.2);
  border: 1px solid rgba(255, 152, 0, 0.5);
  border-radius: 0.5rem;
  text-align: center;
}

.http-warning p {
  color: #fff;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.download-link {
  display: inline-block;
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.3);
  color: #fff;
  text-decoration: none;
  border-radius: 0.4rem;
  font-weight: 600;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.download-link:hover {
  background: rgba(255, 255, 255, 0.4);
  transform: translateY(-1px);
}

.download-link-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
  text-align: center;
}

.text-download-link {
  color: rgba(255, 255, 255, 0.9);
  text-decoration: none;
  font-size: 0.95rem;
  transition: color 0.2s;
}

.text-download-link:hover {
  color: #fff;
  text-decoration: underline;
}
</style>
