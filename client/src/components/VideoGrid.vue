<template>
  <div class="video-grid">
    <!-- Local video -->
    <div class="video-container local" v-if="localStream">
      <video
        ref="localVideo"
        autoplay
        muted
        playsinline
      ></video>
      <div class="video-label">You</div>
    </div>

    <!-- Remote videos -->
    <div
      v-for="[peerId, stream] in remoteStreams"
      :key="peerId"
      class="video-container"
    >
      <video
        :ref="el => setRemoteVideo(peerId, el)"
        autoplay
        playsinline
      ></video>
      <div class="video-label">{{ getParticipantName(peerId) }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, nextTick } from 'vue'

const props = defineProps({
  localStream: {
    type: MediaStream,
    default: null
  },
  remoteStreams: {
    type: Map,
    required: true
  },
  participants: {
    type: Array,
    default: () => []
  }
})

const localVideo = ref(null)
const remoteVideos = ref(new Map())

function setRemoteVideo(peerId, el) {
  if (el) {
    remoteVideos.value.set(peerId, el)
    const stream = props.remoteStreams.get(peerId)
    if (stream) {
      el.srcObject = stream
    }
  }
}

function getParticipantName(peerId) {
  const participant = props.participants.find(p => p.peerId === peerId)
  return participant?.userId || peerId
}

watch(() => props.localStream, (newStream) => {
  if (localVideo.value && newStream) {
    localVideo.value.srcObject = newStream
  }
}, { immediate: true })

watch(() => props.remoteStreams, async (newStreams) => {
  await nextTick()
  newStreams.forEach((stream, peerId) => {
    const videoEl = remoteVideos.value.get(peerId)
    if (videoEl && !videoEl.srcObject) {
      videoEl.srcObject = stream
    }
  })
}, { deep: true })

onMounted(() => {
  if (localVideo.value && props.localStream) {
    localVideo.value.srcObject = props.localStream
  }
})
</script>

<style scoped>
.video-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
  padding: 1rem;
  height: 100%;
  overflow-y: auto;
}

.video-container {
  position: relative;
  background: #000;
  border-radius: 0.75rem;
  overflow: hidden;
  aspect-ratio: 16 / 9;
}

.video-container.local {
  border: 2px solid #667eea;
}

video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.video-label {
  position: absolute;
  bottom: 0.75rem;
  left: 0.75rem;
  padding: 0.5rem 0.75rem;
  background: rgba(0, 0, 0, 0.7);
  color: #fff;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
}

/* Responsive layouts */
@media (min-width: 768px) {
  .video-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1200px) {
  .video-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

/* Single participant - full screen */
.video-grid:has(.video-container:only-child) {
  grid-template-columns: 1fr;
}

.video-grid:has(.video-container:only-child) .video-container {
  aspect-ratio: 16 / 9;
  max-height: 100%;
}
</style>
