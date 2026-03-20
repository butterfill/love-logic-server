import { computed, ref } from "vue";

import { normalizeExtractedDocument } from "../domain/normalize.js";
import { clearLegacyExtractedData } from "../domain/storage.js";

const MIGRATION_NOTICE =
  "Previously saved data from an older version of the viewer was removed. Please re-upload your JSON archive.";

export function createExtractedDataStore({ repository, legacyStorage } = {}) {
  const rawDocument = ref(null);
  const isReady = ref(false);
  const isBusy = ref(false);
  const migrationNotice = ref("");
  const normalized = computed(() =>
    rawDocument.value ? normalizeExtractedDocument(rawDocument.value) : null
  );

  async function initialize() {
    if (clearLegacyExtractedData(legacyStorage)) {
      migrationNotice.value = MIGRATION_NOTICE;
    }

    rawDocument.value = await repository.loadDocument();
    isReady.value = true;
  }

  async function importDocument(document) {
    isBusy.value = true;

    try {
      await repository.saveDocument(document);
      rawDocument.value = document;
      migrationNotice.value = "";
    } finally {
      isBusy.value = false;
    }
  }

  async function clear() {
    isBusy.value = true;

    try {
      await repository.clearDocument();
      rawDocument.value = null;
    } finally {
      isBusy.value = false;
    }
  }

  return {
    rawDocument,
    normalized,
    isReady,
    isBusy,
    migrationNotice,
    hasData: computed(() => Boolean(normalized.value)),
    initialize,
    importDocument,
    clear
  };
}
