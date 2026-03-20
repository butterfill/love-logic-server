<script setup>
import { computed, inject, ref } from "vue";
import { useRouter } from "vue-router";

const store = inject("extractedDataStore");
const router = useRouter();
const errorMessage = ref("");
const isLoading = ref(false);

const summary = computed(() => store.normalized.value);

async function onFileChange(event) {
  const file = event.target.files?.[0];
  if (!file) {
    return;
  }

  isLoading.value = true;
  errorMessage.value = "";

  try {
    const raw = await file.text();
    const parsed = JSON.parse(raw);
    store.importDocument(parsed);
    router.push({ name: "courses" });
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : "Failed to read the JSON file.";
  } finally {
    isLoading.value = false;
    event.target.value = "";
  }
}
</script>

<template>
  <section class="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
    <div class="panel p-6">
      <p class="text-xs uppercase tracking-[0.3em] text-stone-500">Upload</p>
      <h2 class="mt-2 text-3xl font-semibold text-stone-900">Load an extracted JSON archive</h2>
      <p class="mt-4 max-w-2xl text-sm leading-7 text-stone-600">
        Choose a file produced by the `extract-exercises-for-instructor` CLI. The archive is stored in this
        browser only, so you do not need to upload it again on the next visit unless you clear the saved data.
      </p>

      <label class="mt-8 flex cursor-pointer flex-col items-center justify-center rounded-[2rem] border border-dashed border-stone-400 bg-stone-50 px-6 py-14 text-center transition hover:border-stone-700 hover:bg-white">
        <span class="text-sm font-semibold uppercase tracking-[0.25em] text-stone-500">JSON file</span>
        <span class="mt-3 text-2xl font-semibold text-stone-900">Choose archive</span>
        <span class="mt-2 text-sm text-stone-500">The file stays local to this browser.</span>
        <input class="sr-only" type="file" accept=".json,application/json" @change="onFileChange" />
      </label>

      <p v-if="errorMessage" class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{{ errorMessage }}</p>
      <p v-if="isLoading" class="mt-4 text-sm text-stone-500">Reading file…</p>
    </div>

    <aside class="panel p-6">
      <p class="text-xs uppercase tracking-[0.3em] text-stone-500">What appears after upload</p>
      <ul class="mt-5 space-y-3 text-sm leading-7 text-stone-700">
        <li>Searchable course table on the opening page.</li>
        <li>Bookmarkable course and exercise routes.</li>
        <li>Question display derived from the original exercise ids.</li>
        <li>Stored answers with machine and human feedback when present.</li>
      </ul>

      <div v-if="summary" class="mt-8 rounded-3xl bg-stone-900 px-5 py-5 text-stone-100">
        <p class="text-xs uppercase tracking-[0.22em] text-stone-400">Stored archive</p>
        <p class="mt-2 text-lg font-semibold">{{ summary.instructor?.emailAddress }}</p>
      </div>
    </aside>
  </section>
</template>
