<script setup>
defineProps({
  view: {
    type: Object,
    required: true
  }
});
</script>

<template>
  <div class="overflow-x-auto rounded-2xl bg-stone-950 px-4 py-4 text-sm text-stone-100">
    <div class="min-w-[42rem] space-y-1 font-mono">
      <div
        v-for="(row, index) in view.rows"
        :key="`${row.number}-${index}`"
        class="grid items-stretch gap-x-3"
        :style="{
          gridTemplateColumns: `4rem ${Math.max(view.maxDepth, 1) * 1.1}rem minmax(18rem, 1fr) minmax(12rem, auto)`
        }"
      >
        <div class="pt-1 text-right text-stone-400">
          {{ row.number }}
        </div>

        <div
          class="grid"
          :style="{ gridTemplateColumns: `repeat(${Math.max(view.maxDepth, 1)}, minmax(0, 1fr))` }"
        >
          <div
            v-for="(active, railIndex) in row.rails"
            :key="railIndex"
            class="relative min-h-7"
          >
            <span
              v-if="active"
              class="absolute inset-y-0 left-1/2 w-px -translate-x-1/2 bg-stone-500"
            />
          </div>
        </div>

        <div
          v-if="row.type === 'divider'"
          class="flex items-center"
          :data-proof-cell="`sentence-${row.number}`"
        >
          <div class="w-full border-t border-stone-400/80" />
        </div>
        <div
          v-else
          class="formula pt-1 text-stone-50"
          :data-proof-cell="`sentence-${row.number}`"
        >
          {{ row.sentence }}
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
