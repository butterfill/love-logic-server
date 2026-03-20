<script setup>
import { computed } from "vue";

const props = defineProps({
  view: {
    type: Object,
    required: true
  }
});

const railSpacingRem = 1.1;

const sentenceColumnWidth = computed(() => {
  const maxSentenceLength = Math.max(
    ...props.view.rows.map((row) => (row.type === "line" ? row.sentence.length : 6)),
    0
  );
  return `calc(${maxSentenceLength + 2}ch + ${(props.view.maxDepth + 1) * railSpacingRem}rem)`;
});

</script>

<template>
  <div class="overflow-x-auto rounded-2xl bg-stone-950 px-4 py-4 text-sm text-stone-100">
    <div class="min-w-[42rem] space-y-1 font-mono">
      <div
        v-for="(row, index) in view.rows"
        :key="`${row.number}-${index}`"
        class="grid items-stretch gap-x-[3ch] rounded-lg px-2"
        :class="index % 2 === 0 ? 'bg-white/0' : 'bg-white/[0.035]'"
        :data-proof-row="row.number"
        :style="{
          gridTemplateColumns: `4rem ${sentenceColumnWidth} max-content`
        }"
      >
        <div class="pt-1 text-right text-stone-400">
          {{ row.number }}
        </div>

        <div
          class="relative min-h-7"
          :style="{ width: sentenceColumnWidth }"
        >
          <span
            v-for="(active, railIndex) in row.rails"
            :key="railIndex"
            v-show="active"
            class="absolute inset-y-0 w-px bg-stone-500"
            :style="{ left: `${railIndex * railSpacingRem}rem` }"
          />

          <div
            v-if="row.type === 'divider'"
            class="flex items-center pt-3"
            :data-proof-cell="`sentence-${row.number}`"
            :style="{ marginInlineStart: `${Math.max(row.depth - 1, 0) * railSpacingRem}rem` }"
          >
            <div class="w-full border-t border-stone-400/80" />
          </div>
          <div
            v-else
            class="formula pt-1 text-stone-50"
            :data-proof-cell="`sentence-${row.number}`"
            :style="{ paddingInlineStart: `${row.depth * railSpacingRem}rem` }"
          >
            {{ row.sentence }}
          </div>
        </div>

        <div
          v-if="row.type === 'divider'"
          :data-proof-cell="`justification-${row.number}`"
        />
        <div
          v-else
          class="flex flex-wrap items-baseline gap-x-2 pt-1 text-stone-300"
          :data-proof-cell="`justification-${row.number}`"
        >
          <span class="font-medium text-stone-200">{{ row.justification }}</span>
          <span v-if="row.citations" class="text-stone-400">{{ row.citations }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
