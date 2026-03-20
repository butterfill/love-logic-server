import { describe, expect, it } from "vitest";

import { parseExerciseQuestion, renderAnswerSummary } from "../src/domain/renderers.js";

describe("parseExerciseQuestion", () => {
  it("renders proof exercises into premises and conclusion blocks", () => {
    const question = parseExerciseQuestion("/ex/proof/from/A and B|B/to/A");

    expect(question.title).toBe("Write a proof");
    expect(question.blocks[0].items).toEqual(["A ∧ B", "B"]);
    expect(question.blocks[1].items).toEqual(["A"]);
  });

  it("renders translation exercises with domain, names, predicates and sentence", () => {
    const question = parseExerciseQuestion(
      "/ex/trans/domain/2things/names/a=thing1|b=thing2/predicates/Fish1-x-is-a-fish|Loves2/sentence/exists x Fish(x)"
    );

    expect(question.title).toContain("Translate");
    expect(question.blocks[0].items).toEqual(["thing-1", "thing-2"]);
    expect(question.blocks[1].items).toEqual(["a : thing1", "b : thing2"]);
    expect(question.blocks[2].items[0]).toContain("Fish1");
    expect(question.blocks[3].items[0]).toContain("∃x");
  });
});

describe("renderAnswerSummary", () => {
  it("renders proof answers as code blocks", () => {
    expect(
      renderAnswerSummary({
        answer: { content: { proof: "| A\n|---\n| A" } }
      })
    ).toEqual({
      title: "Proof",
      code: "| A\n|---\n| A"
    });
  });

  it("renders truth-value answers as item lists", () => {
    expect(
      renderAnswerSummary({
        answer: { content: { TorF: [true, false] } }
      })
    ).toEqual({
      title: "Truth Values",
      items: ["#1: true", "#2: false"]
    });
  });
});
