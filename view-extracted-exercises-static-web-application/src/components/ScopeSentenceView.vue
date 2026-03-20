<script setup>
import { computed } from "vue";

const props = defineProps({
  sentence: {
    type: Object,
    required: true
  }
});

function highlightSelectedSymbol(html, selection) {
  if (!selection?.symbolNum) {
    return html;
  }

  const parser = new DOMParser();
  const document = parser.parseFromString(`<div>${html}</div>`, "text/html");
  const root = document.body.firstElementChild;
  const wrappers = Array.from(root.querySelectorAll(`._symbolWrap[data-symbolNum="${selection.symbolNum}"]`));

  if (wrappers.length === 0) {
    return html;
  }

  const targetDepth = Number(selection.scopeDepth ?? 0);
  const target =
    wrappers.find((wrapper) => countExpressionDepth(wrapper) === targetDepth) ??
    wrappers[0];

  const highlight = document.createElement("span");
  highlight.className = "scope-answer-highlight";
  highlight.innerHTML = target.innerHTML;
  target.replaceChildren(highlight);

  return root.innerHTML;
}

function countExpressionDepth(element) {
  let depth = 0;
  let current = element.parentElement;

  while (current) {
    if (current.classList.contains("_expressionWrap")) {
      depth += 1;
    }
    current = current.parentElement;
  }

  return depth;
}

const decoratedHtml = computed(() => {
  return highlightSelectedSymbol(props.sentence.html, props.sentence.selection);
});
</script>

<template>
  <div class="rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3 formula text-stone-800" v-html="decoratedHtml" />
</template>
