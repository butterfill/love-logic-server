import { describe, expect, it } from "vitest";

import { createExtractedDataStore } from "../src/stores/extracted-data.js";

function createRepository(initialSnapshot = null) {
  let saved = initialSnapshot;

  return {
    async loadSnapshot() {
      return saved;
    },
    async saveSnapshot(snapshot) {
      saved = snapshot;
    },
    async clearSnapshot() {
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
      document: {
        instructor: { emailAddress: "teacher@example.com" },
        courses: []
      },
      normalized: {
        instructor: { emailAddress: "teacher@example.com" },
        courses: [],
        exercisesBySlug: {},
        uploadedAt: null,
        courseCount: 0,
        exerciseCount: 0
      }
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

  it("normalizes documents once on import and persists the normalized snapshot", async () => {
    const repository = createRepository();
    const store = createExtractedDataStore({ repository, legacyStorage: createLegacyStorage() });

    await store.initialize();
    await store.importDocument({
      instructor: { emailAddress: "teacher@example.com" },
      courses: []
    });

    expect(store.normalized.value.instructor.emailAddress).toBe("teacher@example.com");
    await expect(repository.loadSnapshot()).resolves.toMatchObject({
      document: {
        instructor: { emailAddress: "teacher@example.com" }
      },
      normalized: {
        instructor: { emailAddress: "teacher@example.com" }
      }
    });
  });
});
