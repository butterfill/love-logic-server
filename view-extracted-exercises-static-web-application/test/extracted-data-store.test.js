import { describe, expect, it } from "vitest";

import { createExtractedDataStore } from "../src/stores/extracted-data.js";

function createRepository(initialDocument = null) {
  let saved = initialDocument;

  return {
    async loadDocument() {
      return saved;
    },
    async saveDocument(document) {
      saved = document;
    },
    async clearDocument() {
      saved = null;
    }
  };
}

function createLegacyStorage(initialValue = null) {
  const data = new Map();
  if (initialValue !== null) {
    data.set("view-extracted-exercises-static-web-application:data", initialValue);
  }

  return {
    getItem(key) {
      return data.has(key) ? data.get(key) : null;
    },
    removeItem(key) {
      data.delete(key);
    }
  };
}

describe("createExtractedDataStore", () => {
  it("initializes from persisted documents and clears them", async () => {
    const repository = createRepository({
      instructor: { emailAddress: "teacher@example.com" },
      courses: []
    });
    const store = createExtractedDataStore({ repository, legacyStorage: createLegacyStorage() });

    await store.initialize();

    expect(store.hasData.value).toBe(true);
    expect(store.normalized.value.instructor.emailAddress).toBe("teacher@example.com");

    await store.clear();

    expect(store.hasData.value).toBe(false);
    expect(store.normalized.value).toBeNull();
  });

  it("wipes legacy localStorage data and exposes a migration notice", async () => {
    const store = createExtractedDataStore({
      repository: createRepository(),
      legacyStorage: createLegacyStorage(JSON.stringify({ instructor: { emailAddress: "teacher@example.com" } }))
    });

    await store.initialize();

    expect(store.hasData.value).toBe(false);
    expect(store.migrationNotice.value).toContain("re-upload");
  });
});
