import "fake-indexeddb/auto";

import { describe, expect, it } from "vitest";

import {
  LEGACY_STORAGE_KEY,
  clearLegacyExtractedData,
  createExtractedDataRepository
} from "../src/domain/storage.js";

function createLegacyStorage() {
  const data = new Map();
  return {
    getItem(key) {
      return data.has(key) ? data.get(key) : null;
    },
    setItem(key, value) {
      data.set(key, value);
    },
    removeItem(key) {
      data.delete(key);
    }
  };
}

describe("storage helpers", () => {
  let repositoryCount = 0;

  function createRepository() {
    repositoryCount += 1;
    return createExtractedDataRepository({
      databaseName: `view-extracted-exercises-static-web-application-test-${repositoryCount}`
    });
  }

  it("stores and loads extracted documents in IndexedDB", async () => {
    const repository = createRepository();
    const document = { instructor: { emailAddress: "teacher@example.com" } };

    await repository.saveDocument(document);

    await expect(repository.loadDocument()).resolves.toEqual(document);
  });

  it("clears the saved document from IndexedDB", async () => {
    const repository = createRepository();

    await repository.saveDocument({ ok: true });
    await repository.clearDocument();

    await expect(repository.loadDocument()).resolves.toBeNull();
  });

  it("detects and wipes the legacy localStorage archive", () => {
    const storage = createLegacyStorage();
    storage.setItem(LEGACY_STORAGE_KEY, JSON.stringify({ instructor: { emailAddress: "teacher@example.com" } }));

    expect(clearLegacyExtractedData(storage)).toBe(true);
    expect(storage.getItem(LEGACY_STORAGE_KEY)).toBeNull();
  });
});
