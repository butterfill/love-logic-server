<script setup>
defineProps({
  label: {
    type: String,
    required: true
  },
  detail: {
    type: String,
    default: ""
  },
  progress: {
    type: Number,
    default: null
  }
});
</script>

<template>
  <section class="panel p-6">
    <div class="flex items-center gap-4">
      <div class="relative h-12 w-12">
        <span class="absolute inset-0 rounded-full border-2 border-stone-300/80" />
        <span class="absolute inset-0 rounded-full border-2 border-transparent border-t-stone-900 border-r-stone-600 animate-spin" />
      </div>
      <div class="min-w-0 flex-1">
        <p class="text-xs uppercase tracking-[0.3em] text-stone-500">Loading</p>
        <h2 class="mt-2 text-2xl font-semibold text-stone-900">{{ label }}</h2>
        <p v-if="detail" class="mt-2 text-sm text-stone-600">{{ detail }}</p>
      </div>
      <div
        v-if="progress !== null"
        class="rounded-full bg-stone-900 px-3 py-1 text-sm font-medium text-stone-50"
        data-loading-progress="value"
      >
        {{ Math.round(progress) }}%
      </div>
    </div>

    <div class="mt-5 h-2 overflow-hidden rounded-full bg-stone-200">
      <div
        v-if="progress !== null"
        class="h-full rounded-full bg-[linear-gradient(90deg,#0f4c5c_0%,#8f5e25_100%)] transition-[width] duration-300"
        :style="{ width: `${Math.max(4, Math.min(progress, 100))}%` }"
      />
      <div
        v-else
        class="h-full w-1/3 rounded-full bg-[linear-gradient(90deg,#0f4c5c_0%,#8f5e25_100%)] animate-[loading-slide_1.1s_ease-in-out_infinite]"
      />
    </div>
  </section>
</template>
