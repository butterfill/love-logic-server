import { mount, RouterLinkStub } from "@vue/test-utils";
import { ref } from "vue";
import { describe, expect, it, vi } from "vitest";

vi.mock("vue-router", () => ({
  RouterLink: {
    name: "RouterLink",
    props: ["to"],
    template: "<a><slot /></a>"
  },
  useRoute: () => ({
    params: {
      courseId: "logic-101"
    }
  })
}));

import CourseExercisesPage from "../src/views/CourseExercisesPage.vue";

function createStore() {
  return {
    normalized: ref({
      courses: [
        {
          id: "logic-101",
          name: "logic-101",
          description: "Logic 101",
          exercises: [
            {
              slug: "exercise-1",
              exerciseId: "/ex/TorF/qq/A",
              badges: ["TorF", "Lecture 1", "Logically Valid Arguments"],
              question: { title: "True or False", prose: null },
              lectureName: "lecture_01",
              unitName: "validity",
              answerCount: 2
            },
            {
              slug: "exercise-2",
              exerciseId: "/ex/q/What%20is%20validity",
              badges: ["Question", "Lecture 2"],
              question: { title: "Question", prose: "Define validity" },
              lectureName: "lecture_02",
              unitName: "revision",
              answerCount: 0
            }
          ]
        }
      ]
    })
  };
}

describe("CourseExercisesPage", () => {
  it("shows the current result count and filters by badge and answered-only", async () => {
    const wrapper = mount(CourseExercisesPage, {
      global: {
        provide: {
          extractedDataStore: createStore()
        },
        stubs: {
          RouterLink: RouterLinkStub
        }
      }
    });

    expect(wrapper.text()).toContain("displaying 2 of 2");
    expect(wrapper.text()).toContain("TorF · 1");
    expect(wrapper.text()).toContain("Lecture 1 · 1");

    await wrapper.get("button:nth-of-type(2)").trigger("click");
    expect(wrapper.text()).toContain("displaying 1 of 2");
    expect(wrapper.text()).toContain("/ex/TorF/qq/A");
    expect(wrapper.text()).not.toContain("/ex/q/What%20is%20validity");

    await wrapper.get("button:first-of-type").trigger("click");
    expect(wrapper.text()).toContain("displaying 1 of 2");
  });
});
