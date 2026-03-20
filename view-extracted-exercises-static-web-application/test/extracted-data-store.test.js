import { describe, expect, it } from "vitest";

import { createExtractedDataStore } from "../src/stores/extracted-data.js";

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

describe("createExtractedDataStore", () => {
  it("imports and clears extracted documents", () => {
    const storage = createStorage();
    const store = createExtractedDataStore(storage);

    store.importDocument({
      instructor: { emailAddress: "teacher@example.com" },
      courses: []
    });

    expect(store.hasData.value).toBe(true);
    expect(store.normalized.value.instructor.emailAddress).toBe("teacher@example.com");

    store.clear();

    expect(store.hasData.value).toBe(false);
    expect(store.normalized.value).toBeNull();
  });
});
