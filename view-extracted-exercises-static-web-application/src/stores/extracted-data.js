import { computed, ref } from "vue";

import { normalizeExtractedDocument } from "../domain/normalize.js";
import { clearExtractedData, loadExtractedData, saveExtractedData } from "../domain/storage.js";

export function createExtractedDataStore(storage) {
  const rawDocument = ref(loadExtractedData(storage));
  const normalized = computed(() =>
    rawDocument.value ? normalizeExtractedDocument(rawDocument.value) : null
  );

  function importDocument(document) {
    saveExtractedData(storage, document);
    rawDocument.value = document;
  }

  function clear() {
    clearExtractedData(storage);
    rawDocument.value = null;
  }

  return {
    rawDocument,
    normalized,
    hasData: computed(() => Boolean(normalized.value)),
    importDocument,
    clear
  };
}
