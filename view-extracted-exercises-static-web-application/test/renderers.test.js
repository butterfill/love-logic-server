import { describe, expect, it } from "vitest";

import {
  createRenderedAnswerView,
  parseExerciseQuestion
} from "../src/domain/renderers.js";

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
  it("renders proof answers as structured rows with separated justification", () => {
    const rendered = createRenderedAnswerView(
      {
        answer: { content: { proof: "| A\n|---\n| A" } }
      },
      "/ex/proof/from/A/to/A"
    );

    expect(rendered.title).toBe("Proof");
    expect(rendered.kind).toBe("proof");
    expect(rendered.dialectLabel).toBeNull();
    expect(rendered.maxDepth).toBe(1);
    expect(rendered.rows[0]).toMatchObject({
      type: "line",
      number: "1",
      depth: 1,
      sentence: "A",
      justification: "Premise"
    });
    expect(rendered.rows[1]).toMatchObject({
      type: "divider",
      number: "2x",
      depth: 1
    });
    expect(rendered.rows[2]).toMatchObject({
      type: "line",
      number: "3",
      depth: 1,
      sentence: "A",
      justification: ""
    });
  });

  it("renders proof citations separately from the rule name", () => {
    const rendered = createRenderedAnswerView(
      {
        answer: {
          content: {
            proof: "| A premise\n|| B premise\n||---\n|| A and B and intro 1,2"
          }
        }
      },
      "/ex/proof/from/A|B/to/A and B"
    );

    expect(rendered.rows[3]).toMatchObject({
      type: "line",
      number: "4",
      depth: 2,
      sentence: "A ∧ B",
      justification: "∧ Intro",
      citations: "1, 2"
    });
  });

  it("extracts boxed assumption markers from proof sentences", () => {
    const rendered = createRenderedAnswerView(
      {
        answer: {
          content: {
            proof: "| [a] Premise\n|| F(a) Premise"
          }
        }
      },
      "/ex/proof/from/-/to/exists x F(x)"
    );

    expect(rendered.rows[0]).toMatchObject({
      number: "1",
      boxLabel: "a",
      sentence: "",
      justification: "Premise"
    });
  });

  it("renders truth-value answers against their question sentences", () => {
    expect(
      createRenderedAnswerView(
        {
        answer: { content: { TorF: [true, false] } }
        },
        "/ex/TorF/qq/A and B|B"
      )
    ).toEqual({
      title: "Truth values",
      kind: "truth-values",
      items: [
        { label: "A ∧ B", value: "true" },
        { label: "B", value: "false" }
      ]
    });
  });

  it("renders possible situations as positioned world objects with recovered descriptors", () => {
    const view = createRenderedAnswerView(
      {
        answer: {
          content: {
            world: [{ x: 0, y: 1, w: 2, h: 3, n: "a", c: "red", f: [":", ">", ")"] }]
          }
        }
      },
      "/ex/create/qq/Red(a)"
    );

    expect(view.kind).toBe("possible-world");
    expect(view.objects[0]).toMatchObject({
      x: 0,
      y: 1,
      width: 2,
      height: 3,
      colour: "red",
      name: "a",
      face: [":", ">", ")"]
    });
    expect(view.objects[0].descriptors).toEqual(
      expect.arrayContaining(["Red", "Tall", "Narrow", "HasLargeNose", "Happy", "Smiling"])
    );
  });
});
