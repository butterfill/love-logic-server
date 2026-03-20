<script setup>
import { computed, inject, ref } from "vue";
import { useRouter } from "vue-router";

const store = inject("extractedDataStore");
const router = useRouter();
const showClearModal = ref(false);

const instructorLabel = computed(
  () => store.normalized.value?.instructor?.emailAddress ?? "No data loaded"
);
const showClearButton = computed(() => store.hasData.value);

function openClearModal() {
  showClearModal.value = true;
}

function cancelClear() {
  showClearModal.value = false;
}

function confirmClear() {
  store.clear();
  showClearModal.value = false;
  router.push({ name: "upload" });
}
</script>

<template>
  <div class="mx-auto flex min-h-screen max-w-7xl flex-col px-4 py-6 sm:px-6 lg:px-8">
    <header class="mb-6 panel overflow-hidden">
      <div class="flex flex-col gap-4 bg-[linear-gradient(135deg,#0f4c5c_0%,#8f5e25_100%)] px-6 py-6 text-stone-50 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.35em] text-stone-200">Extracted Exercises Viewer</p>
          <h1 class="mt-2 text-3xl font-semibold tracking-tight">Instructor course archive</h1>
          <p class="mt-2 text-sm text-stone-200">Stored locally in this browser for private, repeatable review.</p>
        </div>
        <div class="flex items-center gap-3">
          <span class="chip border-stone-200/40 bg-stone-50/10 text-stone-50">{{ instructorLabel }}</span>
          <button
            v-if="showClearButton"
            class="rounded-full border border-stone-50/40 px-4 py-2 text-sm font-medium text-stone-50 transition hover:bg-stone-50/10"
            @click="openClearModal"
          >
            clear all data
          </button>
        </div>
      </div>
    </header>

    <main class="flex-1">
      <RouterView />
    </main>

    <div
      v-if="showClearModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-stone-950/40 px-4"
      @click.self="cancelClear"
    >
      <div class="panel w-full max-w-md p-6">
        <h2 class="text-xl font-semibold text-stone-900">Remove stored data?</h2>
        <p class="mt-3 text-sm leading-6 text-stone-600">
          This clears the uploaded JSON from browser storage. You will need to upload a file again before
          using the viewer.
        </p>
        <div class="mt-6 flex justify-end gap-3">
          <button class="rounded-full px-4 py-2 text-sm text-stone-600 hover:bg-stone-100" @click="cancelClear">
            Cancel
          </button>
          <button
            class="rounded-full bg-stone-900 px-4 py-2 text-sm font-medium text-white hover:bg-stone-700"
            @click="confirmClear"
          >
            clear all data
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
