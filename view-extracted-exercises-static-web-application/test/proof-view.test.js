import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

import ProofView from "../src/components/ProofView.vue";

describe("ProofView", () => {
  it("renders sentence and justification in separate aligned columns", () => {
    const wrapper = mount(ProofView, {
      props: {
        view: {
          kind: "proof",
          maxDepth: 2,
          rows: [
            {
              type: "line",
              number: "1",
              depth: 1,
              sentence: "A",
              justification: "Premise",
              citations: "",
              rails: [true, false]
            },
            {
              type: "line",
              number: "2",
              depth: 2,
              sentence: "A ∧ B",
              justification: "∧ Intro",
              citations: "1, 1",
              rails: [true, true]
            }
          ]
        }
      }
    });

    const sentence = wrapper.get('[data-proof-cell="sentence-2"]');
    const justification = wrapper.get('[data-proof-cell="justification-2"]');

    expect(sentence.text()).toBe("A ∧ B");
    expect(justification.text()).toContain("∧ Intro");
    expect(justification.text()).toContain("1, 1");
    expect(justification.text()).not.toContain("A ∧ B");
  });
});
