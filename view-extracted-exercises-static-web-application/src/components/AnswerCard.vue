<script setup>
defineProps({
  answer: {
    type: Object,
    required: true
  }
});
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

    <p v-if="answer.rendered.prose" class="formula mt-4 text-stone-700">{{ answer.rendered.prose }}</p>

    <ul v-if="answer.rendered.items" class="mt-4 space-y-2">
      <li
        v-for="item in answer.rendered.items"
        :key="item"
        class="rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3 formula text-stone-800"
      >
        {{ item }}
      </li>
    </ul>

    <pre
      v-if="answer.rendered.code"
      class="mt-4 overflow-x-auto rounded-2xl bg-stone-950 px-4 py-4 text-sm leading-6 text-stone-100"
    ><code>{{ answer.rendered.code }}</code></pre>

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
