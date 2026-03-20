import { describe, expect, it } from "vitest";

import { STORAGE_KEY, clearExtractedData, loadExtractedData, saveExtractedData } from "../src/domain/storage.js";

function createStorage() {
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
  it("stores and loads extracted documents in browser storage", () => {
    const storage = createStorage();
    const document = { instructor: { emailAddress: "teacher@example.com" } };

    saveExtractedData(storage, document);

    expect(storage.getItem(STORAGE_KEY)).toContain("teacher@example.com");
    expect(loadExtractedData(storage)).toEqual(document);
  });

  it("clears the saved document", () => {
    const storage = createStorage();
    saveExtractedData(storage, { ok: true });

    clearExtractedData(storage);

    expect(loadExtractedData(storage)).toBeNull();
  });
});
