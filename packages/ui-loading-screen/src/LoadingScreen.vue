<template>
  <div class="relative flex h-screen w-screen items-center justify-center bg-slate-950 text-white">
    <div class="flex flex-col items-center gap-4">
      <h1 class="text-4xl font-bold tracking-wide">Labafero Roleplay</h1>
      <p class="text-lg text-slate-300">Carregando...</p>
    </div>

    <div class="absolute right-6 bottom-6 flex gap-2">
      <button
        type="button"
        class="rounded-full border border-white/20 bg-white/10 px-4 py-2 text-sm text-white/80 backdrop-blur transition hover:bg-white/20"
        @click="toggleAudio"
      >
        {{ isPlaying ? "Pausar música" : "Tocar música" }}
      </button>
      <button
        v-if="props.tracks.length > 1"
        type="button"
        class="rounded-full border border-white/20 bg-white/10 px-4 py-2 text-sm text-white/80 backdrop-blur transition hover:bg-white/20"
        @click="skipTrack"
      >
        Próxima faixa
      </button>
    </div>

    <audio
      ref="audioEl"
      :src="currentTrackSrc"
      autoplay
      class="hidden"
      @ended="skipTrack"
    ></audio>
  </div>
</template>

<script setup>
import { computed, nextTick, ref } from "vue";
import { TRACKS } from "./placeholders.js";

const props = defineProps({
  tracks: { type: Array, default: () => TRACKS },
});

const audioEl = ref(null);
const isPlaying = ref(true);
const currentTrackIndex = ref(0);

const currentTrackSrc = computed(() => props.tracks[currentTrackIndex.value] ?? "");

function toggleAudio() {
  const audio = audioEl.value;
  if (!audio) {
    return;
  }
  if (audio.paused) {
    audio.play();
    isPlaying.value = true;
  } else {
    audio.pause();
    isPlaying.value = false;
  }
}

function skipTrack() {
  if (props.tracks.length === 0) {
    return;
  }
  currentTrackIndex.value = (currentTrackIndex.value + 1) % props.tracks.length;
  nextTick(() => {
    const audio = audioEl.value;
    if (!audio) {
      return;
    }
    audio.currentTime = 0;
    if (isPlaying.value) {
      audio.play();
    }
  });
}
</script>
