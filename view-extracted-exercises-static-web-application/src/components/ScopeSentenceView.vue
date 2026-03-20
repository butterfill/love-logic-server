<script setup>
import { computed } from "vue";

const props = defineProps({
  sentence: {
    type: Object,
    required: true
  }
});

const decoratedHtml = computed(() => {
  if (!props.sentence.selection?.symbolNum) {
    return props.sentence.html;
  }

  const symbolNum = String(props.sentence.selection.symbolNum).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(
    `(<span[^>]*class="[^"]*_symbolWrap[^"]*"[^>]*data-symbolNum="${symbolNum}"[^>]*>)([\\s\\S]*?)(</span>)`,
    "i"
  );
  return props.sentence.html.replace(pattern, '$1<span class="scope-answer-highlight">$2</span>$3');
});
</script>

<template>
  <div class="rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3 formula text-stone-800" v-html="decoratedHtml" />
</template>
