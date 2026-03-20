import { describe, expect, it } from "vitest";

import { normalizeExtractedDocument } from "../src/domain/normalize.js";

describe("normalizeExtractedDocument", () => {
  it("builds bookmarkable course and exercise indexes from extracted data", () => {
    const normalized = normalizeExtractedDocument({
      generatedAt: "2026-03-20T00:00:00.000Z",
      instructor: { emailAddress: "teacher@example.com" },
      courses: [
        {
          name: "logic-101",
          description: "Logic 101",
          exerciseSets: [
            {
              variant: "normal",
              description: "Main set",
              lectures: [
                {
                  name: "lecture_01",
                  units: [
                    {
                      name: "unit-1",
                      exercises: [
                        {
                          exerciseId: "/ex/q/Define%20logical%20validity",
                          answers: [{ _id: "answer-1", answer: { content: { sentence: "An argument is valid." } } }]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    });

    expect(normalized.courseCount).toBe(1);
    expect(normalized.courses[0].id).toBe("logic-101");
    expect(normalized.courses[0].exerciseCount).toBe(1);
    expect(normalized.courses[0].exercises[0].slug).toBe(
      encodeURIComponent("/ex/q/Define%20logical%20validity")
    );
    expect(normalized.courses[0].exercises[0].badges).toEqual(
      expect.arrayContaining(["Question", "normal", "Lecture 1", "unit-1"])
    );
    expect(normalized.exercisesBySlug[encodeURIComponent("/ex/q/Define%20logical%20validity")].answers).toHaveLength(1);
  });
});
