import { describe, expect, it } from "vitest";

import { getRedirectForStoreState } from "../src/router.js";

function createStoreState({ isReady, hasData }) {
  return {
    isReady: { value: isReady },
    hasData: { value: hasData }
  };
}

describe("getRedirectForStoreState", () => {
  it("sends a fresh browser session to upload after initialization", () => {
    expect(
      getRedirectForStoreState(createStoreState({ isReady: true, hasData: false }), { name: "courses" })
    ).toEqual({ name: "upload" });
  });

  it("keeps navigation untouched before initialization completes", () => {
    expect(
      getRedirectForStoreState(createStoreState({ isReady: false, hasData: false }), { name: "courses" })
    ).toBeNull();
  });

  it("sends stored sessions away from the upload route", () => {
    expect(
      getRedirectForStoreState(createStoreState({ isReady: true, hasData: true }), { name: "upload" })
    ).toEqual({ name: "courses" });
  });
});
