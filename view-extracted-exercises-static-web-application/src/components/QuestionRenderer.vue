<script setup>
defineProps({
  question: {
    type: Object,
    required: true
  }
});
</script>

<template>
  <section class="panel p-6">
    <p class="text-xs uppercase tracking-[0.28em] text-stone-500">Question</p>
    <h2 class="mt-2 text-2xl font-semibold text-stone-900">{{ question.title }}</h2>

    <p v-if="question.prose" class="formula mt-4 leading-7 text-stone-700">{{ question.prose }}</p>

    <div v-if="question.blocks?.length" class="mt-5 space-y-5">
      <div v-for="block in question.blocks" :key="block.label">
        <h3 class="text-sm font-semibold uppercase tracking-[0.2em] text-stone-500">{{ block.label }}</h3>
        <ul class="mt-3 space-y-2">
          <li
            v-for="item in block.items"
            :key="item"
            class="rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3 formula text-stone-800"
          >
            {{ item }}
          </li>
        </ul>
      </div>
    </div>

    <div v-if="question.notes?.length" class="mt-5 flex flex-wrap gap-2">
      <span v-for="note in question.notes" :key="note" class="chip">{{ note }}</span>
    </div>
  </section>
</template>
