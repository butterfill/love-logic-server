import { computed, ref } from "vue";

import { normalizeExtractedDocument } from "../domain/normalize.js";
import { clearLegacyExtractedData } from "../domain/storage.js";

const MIGRATION_NOTICE =
  "Previously saved data from an older version of the viewer was removed. Please re-upload your JSON archive.";

export function createExtractedDataStore({ repository, legacyStorage } = {}) {
  const rawDocument = ref(null);
  const normalizedDocument = ref(null);
  const isReady = ref(false);
  const isBusy = ref(false);
  const migrationNotice = ref("");
  const activity = ref({
    label: "",
    detail: "",
    progress: null,
    mode: null
  });
  const normalized = computed(() => normalizedDocument.value);

  function setActivity(nextActivity) {
    activity.value = {
      label: nextActivity.label ?? "",
      detail: nextActivity.detail ?? "",
      progress: nextActivity.progress ?? null,
      mode: nextActivity.mode ?? null
    };
  }

  async function initialize() {
    isBusy.value = true;
    setActivity({
      label: "Loading saved archive",
      detail: "Opening IndexedDB snapshot",
      progress: null,
      mode: "initialize"
    });

    if (clearLegacyExtractedData(legacyStorage)) {
      migrationNotice.value = MIGRATION_NOTICE;
    }

    try {
      const snapshot = await repository.loadSnapshot();
      rawDocument.value = snapshot?.document ?? null;
      normalizedDocument.value = snapshot?.normalized ?? null;

      if (rawDocument.value && !normalizedDocument.value) {
        setActivity({
          label: "Loading saved archive",
          detail: "Preparing cached indexes",
          progress: 70,
          mode: "initialize"
        });
        normalizedDocument.value = normalizeExtractedDocument(rawDocument.value);
        await repository.saveSnapshot({
          document: rawDocument.value,
          normalized: normalizedDocument.value
        });
      }
    } finally {
      isReady.value = true;
      isBusy.value = false;
      setActivity({ label: "", detail: "", progress: null, mode: null });
    }
  }

  async function importDocument(document) {
    isBusy.value = true;
    setActivity({
      label: "Importing archive",
      detail: "Normalizing exercises and answers",
      progress: 68,
      mode: "import"
    });

    try {
      const normalizedSnapshot = normalizeExtractedDocument(document);
      setActivity({
        label: "Importing archive",
        detail: "Saving archive to IndexedDB",
        progress: 90,
        mode: "import"
      });
      await repository.saveSnapshot({
        document,
        normalized: normalizedSnapshot
      });
      rawDocument.value = document;
      normalizedDocument.value = normalizedSnapshot;
      migrationNotice.value = "";
    } finally {
      isBusy.value = false;
      setActivity({ label: "", detail: "", progress: null, mode: null });
    }
  }

  async function clear() {
    isBusy.value = true;
    setActivity({
      label: "Clearing archive",
      detail: "Removing stored data",
      progress: null,
      mode: "clear"
    });

    try {
      await repository.clearSnapshot();
      rawDocument.value = null;
      normalizedDocument.value = null;
    } finally {
      isBusy.value = false;
      setActivity({ label: "", detail: "", progress: null, mode: null });
    }
  }

  return {
    rawDocument,
    normalized,
    isReady,
    isBusy,
    migrationNotice,
    activity,
    hasData: computed(() => Boolean(normalized.value)),
    initialize,
    importDocument,
    clear
  };
}
