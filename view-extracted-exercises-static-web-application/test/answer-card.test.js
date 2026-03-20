import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

import AnswerCard from "../src/components/AnswerCard.vue";

describe("AnswerCard", () => {
  it("shows the rendered tab by default and allows switching to the raw tab", async () => {
    const wrapper = mount(AnswerCard, {
      props: {
        answer: {
          _id: "answer-1",
          rendered: {
            kind: "truth-values",
            title: "Truth values",
            items: [{ label: "A", value: "true" }]
          },
          raw: {
            kind: "raw",
            title: "Raw data",
            code: '{\n  "answer": true\n}'
          }
        }
      }
    });

    expect(wrapper.text()).toContain("Truth values");
    expect(wrapper.text()).toContain("A");
    expect(wrapper.text()).not.toContain('"answer": true');

    await wrapper.get("button:last-of-type").trigger("click");

    expect(wrapper.text()).toContain('"answer": true');
  });
});
