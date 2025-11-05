<template>
  <div class="media-controls">
    <button
      :class="['control-btn', { active: mediaState.audio }]"
      @click="$emit('toggle-audio')"
      title="Toggle Microphone"
    >
      <span v-if="mediaState.audio">🎤</span>
      <span v-else>🔇</span>
    </button>

    <button
      :class="['control-btn', { active: mediaState.video }]"
      @click="$emit('toggle-video')"
      title="Toggle Camera"
    >
      <span v-if="mediaState.video">📹</span>
      <span v-else>📷</span>
    </button>

    <button
      :class="['control-btn', { active: mediaState.screen }]"
      @click="$emit('toggle-screen')"
      title="Toggle Screen Share"
    >
      <span v-if="mediaState.screen">🖥️</span>
      <span v-else>📺</span>
    </button>

    <button
      class="control-btn leave-btn"
      @click="$emit('leave')"
      title="Leave Room"
    >
      <span>📞</span>
    </button>
  </div>
</template>

<script setup>
defineProps({
  mediaState: {
    type: Object,
    required: true
  }
})

defineEmits(['toggle-audio', 'toggle-video', 'toggle-screen', 'leave'])
</script>

<style scoped>
.media-controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  align-items: center;
  padding: 1.5rem;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(10px);
  border-radius: 1rem;
}

.control-btn {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font-size: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.control-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.1);
}

.control-btn.active {
  background: linear-gradient(45deg, #667eea, #764ba2);
}

.leave-btn {
  background: rgba(255, 59, 48, 0.3) !important;
}

.leave-btn:hover {
  background: rgba(255, 59, 48, 0.5) !important;
}
</style>
