<template>
  <div v-if="show" class="source-picker-overlay" @click="handleCancel">
    <div class="source-picker-modal" @click.stop>
      <h2>Choose what to share</h2>

      <div class="source-tabs">
        <button
          :class="{ active: activeTab === 'screen' }"
          @click="activeTab = 'screen'"
        >
          Entire Screen
        </button>
        <button
          :class="{ active: activeTab === 'window' }"
          @click="activeTab = 'window'"
        >
          Window
        </button>
      </div>

      <div class="sources-grid">
        <div
          v-for="source in filteredSources"
          :key="source.id"
          class="source-item"
          :class="{ selected: selectedSource?.id === source.id }"
          @click="selectedSource = source"
        >
          <img :src="source.thumbnail" :alt="source.name" />
          <span class="source-name">{{ source.name }}</span>
        </div>
      </div>

      <div class="modal-actions">
        <button @click="handleCancel" class="btn-cancel">Cancel</button>
        <button
          @click="handleSelect"
          class="btn-primary"
          :disabled="!selectedSource"
        >
          Share
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  show: Boolean,
  sources: Array
})

const emit = defineEmits(['select', 'cancel'])

const activeTab = ref('screen')
const selectedSource = ref(null)

const filteredSources = computed(() => {
  if (!props.sources) return []
  return props.sources.filter(source => {
    if (activeTab.value === 'screen') {
      return source.id.startsWith('screen:')
    } else {
      return source.id.startsWith('window:')
    }
  })
})

watch(() => props.show, (newVal) => {
  if (newVal) {
    selectedSource.value = null
    // Auto-select first screen by default
    if (filteredSources.value.length > 0) {
      selectedSource.value = filteredSources.value[0]
    }
  }
})

watch(activeTab, () => {
  // Auto-select first item when switching tabs
  if (filteredSources.value.length > 0) {
    selectedSource.value = filteredSources.value[0]
  }
})

function handleSelect() {
  if (selectedSource.value) {
    emit('select', selectedSource.value)
  }
}

function handleCancel() {
  emit('cancel')
}
</script>

<style scoped>
.source-picker-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.source-picker-modal {
  background: #2c2c2c;
  border-radius: 1rem;
  padding: 2rem;
  width: 90%;
  max-width: 800px;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
}

.source-picker-modal h2 {
  margin: 0 0 1.5rem 0;
  font-size: 1.5rem;
}

.source-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  border-bottom: 2px solid #444;
}

.source-tabs button {
  padding: 0.75rem 1.5rem;
  background: transparent;
  border: none;
  color: #999;
  font-weight: 500;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  transition: all 0.2s;
}

.source-tabs button.active {
  color: #667eea;
  border-bottom-color: #667eea;
}

.sources-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1rem;
  overflow-y: auto;
  max-height: 400px;
  padding: 0.5rem;
  margin-bottom: 1.5rem;
}

.source-item {
  background: #1a1a1a;
  border: 2px solid transparent;
  border-radius: 0.5rem;
  padding: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.source-item:hover {
  background: #252525;
  border-color: #444;
}

.source-item.selected {
  border-color: #667eea;
  background: rgba(102, 126, 234, 0.1);
}

.source-item img {
  width: 100%;
  height: 120px;
  object-fit: contain;
  background: #000;
  border-radius: 0.25rem;
}

.source-name {
  font-size: 0.85rem;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.modal-actions button {
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: #1a1a1a;
  color: #fff;
  border: 1px solid #444;
}

.btn-cancel:hover {
  background: #252525;
}

.btn-primary {
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: #fff;
  border: none;
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary:not(:disabled):hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

/* Scrollbar styling */
.sources-grid::-webkit-scrollbar {
  width: 8px;
}

.sources-grid::-webkit-scrollbar-track {
  background: #1a1a1a;
  border-radius: 4px;
}

.sources-grid::-webkit-scrollbar-thumb {
  background: #444;
  border-radius: 4px;
}

.sources-grid::-webkit-scrollbar-thumb:hover {
  background: #555;
}
</style>
