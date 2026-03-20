<script setup>
import ScopeSentenceView from "./ScopeSentenceView.vue";

defineProps({
  view: {
    type: Object,
    required: true
  }
});

function gridColumn(start, span) {
  return `${start} / span ${Math.max(span ?? 1, 1)}`;
}

function gridRow(start, span) {
  return `${start} / span ${Math.max(span ?? 1, 1)}`;
}
</script>

<template>
  <div class="mt-4">
    <p v-if="view.dialectLabel" class="mb-3 text-xs uppercase tracking-[0.2em] text-stone-500">
      {{ view.dialectLabel }}
    </p>

    <div v-if="view.kind === 'proof'" class="overflow-x-auto rounded-2xl bg-stone-950 px-4 py-4 text-sm leading-7 text-stone-100">
      <div v-for="line in view.lines" :key="line" class="font-mono">{{ line }}</div>
    </div>

    <div v-else-if="view.kind === 'sentence'" class="rounded-2xl border border-stone-200 bg-stone-50 px-4 py-4">
      <p class="formula text-stone-900">{{ view.normalizedSentence }}</p>
      <p v-if="view.normalizedSentence !== view.sentence" class="mt-3 text-sm text-stone-500">{{ view.sentence }}</p>
    </div>

    <ul v-else-if="view.kind === 'truth-values'" class="space-y-2">
      <li
        v-for="item in view.items"
        :key="`${item.label}-${item.value}`"
        class="flex items-start justify-between gap-4 rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3"
      >
        <span class="formula text-stone-800">{{ item.label }}</span>
        <span class="chip">{{ item.value }}</span>
      </li>
    </ul>

    <div v-else-if="view.kind === 'truth-table'" class="overflow-x-auto rounded-2xl border border-stone-200 bg-stone-50">
      <table class="min-w-full border-collapse">
        <thead class="bg-stone-100">
          <tr>
            <th v-for="header in view.headers" :key="header" class="px-4 py-3 text-center text-sm font-semibold text-stone-700 formula">
              {{ header }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, rowIndex) in view.rows" :key="rowIndex" class="border-t border-stone-200">
            <td v-for="(value, columnIndex) in row" :key="`${rowIndex}-${columnIndex}`" class="px-4 py-3 text-center text-sm text-stone-800">
              {{ value }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else-if="view.kind === 'possible-world'" class="rounded-[2rem] border border-stone-200 bg-stone-50 p-5">
      <div
        class="grid gap-3 rounded-[1.5rem] bg-[radial-gradient(circle_at_20%_20%,rgba(255,255,255,0.9),rgba(255,255,255,0.4)),linear-gradient(180deg,#dfeaf0_0%,#d4e0d0_100%)] p-4"
        :style="{
          gridTemplateColumns: `repeat(${view.columns}, minmax(0, 1fr))`,
          gridTemplateRows: `repeat(${view.rows}, minmax(3rem, 5rem))`
        }"
      >
        <article
          v-for="object in view.objects"
          :key="object.id"
          class="relative rounded-[1.5rem] border border-stone-300/60 shadow-sm"
          :class="`world-color-${object.colour}`"
          :style="{
            gridColumn: gridColumn(object.x + 1, object.width),
            gridRow: gridRow(object.y + 1, object.height)
          }"
        >
          <div class="flex h-full flex-col justify-between px-3 py-3">
            <div class="text-center">
              <div class="font-['Trebuchet_MS','Gill_Sans',sans-serif] text-xl leading-none tracking-tight text-stone-900">
                <span>{{ object.face[0] }}</span><span>{{ object.face[1] }}</span><span>{{ object.face[2] }}</span>
              </div>
            </div>
            <div>
              <p class="truncate text-center text-xs font-semibold uppercase tracking-[0.2em] text-stone-700">
                {{ object.name || "[no name]" }}
              </p>
              <div class="mt-2 flex flex-wrap justify-center gap-1">
                <span v-for="descriptor in object.descriptors" :key="descriptor" class="rounded-full bg-white/75 px-2 py-1 text-[10px] font-medium text-stone-700">
                  {{ descriptor }}
                </span>
              </div>
            </div>
          </div>
        </article>
      </div>
    </div>

    <div v-else-if="view.kind === 'counterexample'" class="grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
      <section class="rounded-2xl border border-stone-200 bg-stone-50 p-4">
        <h4 class="text-sm font-semibold uppercase tracking-[0.2em] text-stone-500">Domain</h4>
        <p class="mt-3 text-sm text-stone-800">{{ view.domain.join(", ") || "[empty]" }}</p>

        <h4 class="mt-5 text-sm font-semibold uppercase tracking-[0.2em] text-stone-500">Names</h4>
        <ul class="mt-3 space-y-2">
          <li v-for="[name, value] in view.names" :key="name" class="flex justify-between rounded-xl bg-white px-3 py-2 text-sm text-stone-800">
            <span>{{ name }}</span>
            <span>{{ value }}</span>
          </li>
        </ul>
      </section>

      <section class="rounded-2xl border border-stone-200 bg-stone-50 p-4">
        <h4 class="text-sm font-semibold uppercase tracking-[0.2em] text-stone-500">Predicates</h4>
        <ul class="mt-3 space-y-2">
          <li v-for="predicate in view.predicates" :key="predicate.name" class="rounded-xl bg-white px-3 py-2 text-sm text-stone-800">
            <span class="font-semibold">{{ predicate.name }}</span>
            <span class="ml-2">{{ predicate.extension }}</span>
          </li>
        </ul>
      </section>
    </div>

    <div v-else-if="view.kind === 'scope'" class="space-y-3">
      <ScopeSentenceView v-for="(sentence, index) in view.sentences" :key="index" :sentence="sentence" />
    </div>

    <pre
      v-else
      class="overflow-x-auto rounded-2xl bg-stone-950 px-4 py-4 text-sm leading-6 text-stone-100"
    ><code>{{ view.code }}</code></pre>
  </div>
</template>
