<script setup>
import { ref } from "vue";

import RenderedAnswerView from "./RenderedAnswerView.vue";

defineProps({
  answer: {
    type: Object,
    required: true
  }
});

const activeTab = ref("rendered");
</script>

<template>
  <article class="panel p-5">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <p class="text-xs uppercase tracking-[0.22em] text-stone-500">Answer</p>
        <h3 class="mt-1 text-lg font-semibold text-stone-900">{{ answer.rendered.title }}</h3>
      </div>
      <div class="flex flex-wrap gap-2 text-xs text-stone-500">
        <span v-if="answer.created" class="chip">{{ new Date(answer.created).toLocaleString() }}</span>
        <span v-if="answer._id" class="chip">id {{ answer._id }}</span>
      </div>
    </div>

    <div class="mt-4 inline-flex rounded-full border border-stone-300 bg-stone-100 p-1">
      <button
        class="rounded-full px-4 py-2 text-sm font-medium transition"
        :class="activeTab === 'rendered' ? 'bg-white text-stone-900 shadow-sm' : 'text-stone-600'"
        @click="activeTab = 'rendered'"
      >
        Rendered
      </button>
      <button
        class="rounded-full px-4 py-2 text-sm font-medium transition"
        :class="activeTab === 'raw' ? 'bg-white text-stone-900 shadow-sm' : 'text-stone-600'"
        @click="activeTab = 'raw'"
      >
        Raw
      </button>
    </div>

    <RenderedAnswerView v-if="activeTab === 'rendered'" :view="answer.rendered" />

    <pre
      v-else
      class="mt-4 overflow-x-auto rounded-2xl bg-stone-950 px-4 py-4 text-sm leading-6 text-stone-100"
    ><code>{{ answer.raw.code }}</code></pre>

    <div class="mt-4 grid gap-3 text-sm text-stone-600 sm:grid-cols-2">
      <div v-if="answer.machineFeedback" class="rounded-2xl border border-stone-200 bg-white px-4 py-3">
        <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Machine feedback</p>
        <pre class="mt-2 whitespace-pre-wrap text-xs">{{ JSON.stringify(answer.machineFeedback, null, 2) }}</pre>
      </div>
      <div v-if="answer.humanFeedback" class="rounded-2xl border border-stone-200 bg-white px-4 py-3">
        <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Human feedback</p>
        <pre class="mt-2 whitespace-pre-wrap text-xs">{{ JSON.stringify(answer.humanFeedback, null, 2) }}</pre>
      </div>
    </div>
  </article>
</template>
