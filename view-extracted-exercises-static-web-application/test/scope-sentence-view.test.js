import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

import ScopeSentenceView from "../src/components/ScopeSentenceView.vue";

describe("ScopeSentenceView", () => {
  it("highlights the selected symbol with inverted styling", () => {
    const wrapper = mount(ScopeSentenceView, {
      props: {
        sentence: {
          html: '<span class="_symbolWrap" data-symbolNum="7">∀</span>xFx',
          selection: { symbolNum: "7", scopeDepth: 0 }
        }
      }
    });

    expect(wrapper.html()).toContain("scope-answer-highlight");
    expect(wrapper.text()).toContain("∀");
  });

  it("uses scopeDepth to choose the correct nested symbol", () => {
    const wrapper = mount(ScopeSentenceView, {
      props: {
        sentence: {
          html:
            '<span class="_expressionWrap">' +
            '<span class="_symbolWrap" data-symbolNum="1">∀</span>' +
            '<span class="_expressionWrap">' +
            '<span class="_symbolWrap" data-symbolNum="1">∃</span>' +
            "</span>" +
            "</span>",
          selection: { symbolNum: "1", scopeDepth: 2 }
        }
      }
    });

    const highlights = wrapper.element.querySelectorAll(".scope-answer-highlight");
    expect(highlights).toHaveLength(1);
    expect(highlights[0].textContent).toBe("∃");
  });
});
