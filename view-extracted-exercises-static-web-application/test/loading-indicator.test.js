import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

import LoadingIndicator from "../src/components/LoadingIndicator.vue";

describe("LoadingIndicator", () => {
  it("renders an indeterminate loading message", () => {
    const wrapper = mount(LoadingIndicator, {
      props: {
        label: "Loading saved archive",
        detail: "Opening IndexedDB snapshot",
        progress: null
      }
    });

    expect(wrapper.text()).toContain("Loading saved archive");
    expect(wrapper.text()).toContain("Opening IndexedDB snapshot");
    expect(wrapper.find('[data-loading-progress="value"]').exists()).toBe(false);
  });

  it("renders determinate progress", () => {
    const wrapper = mount(LoadingIndicator, {
      props: {
        label: "Importing archive",
        detail: "Normalizing exercises",
        progress: 72
      }
    });

    expect(wrapper.get('[data-loading-progress="value"]').text()).toContain("72%");
  });
});
