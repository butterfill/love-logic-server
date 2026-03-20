import { fol, parseProof } from "@butterfill/awfol/browser";

function safeDecode(value) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function safeParseFormula(text) {
  try {
    return fol.parseUsingSystemParser(text).toString({ replaceSymbols: true });
  } catch {
    return text;
  }
}

function toReadableSentence(text) {
  const decoded = safeDecode(text);
  return safeParseFormula(decoded);
}

function parseSegmentedExerciseId(exerciseId) {
  const parts = exerciseId.split("/").filter(Boolean).map(safeDecode);
  return {
    parts,
    type: parts[1] ?? "unknown",
    subtype: parts[2] ?? null
  };
}

function parseSentenceList(raw) {
  return raw.split("|").map(toReadableSentence);
}

function parseFormulaObjectsFromText(raw) {
  return safeDecode(raw)
    .split("|")
    .map((text) => {
      try {
        return fol.parseUsingSystemParser(text);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

function buildProofQuestion(parts) {
  const fromIndex = parts.indexOf("from");
  const toIndex = parts.indexOf("to");
  const premises = fromIndex >= 0 ? parseSentenceList(parts[fromIndex + 1] ?? "") : [];
  const conclusion = toIndex >= 0 ? toReadableSentence(parts[toIndex + 1] ?? "") : "";
  return {
    title: "Write a proof",
    blocks: [
      premises.length
        ? { label: `Premises (${premises.length})`, items: premises }
        : { label: "Premises", items: ["[No premises]"] },
      { label: "Conclusion", items: [conclusion] }
    ]
  };
}

function buildQuestionQuestion(parts) {
  return {
    title: "Question",
    prose: safeDecode(parts[2] ?? "")
  };
}

function buildTruthQuestion(parts) {
  const qqIndex = parts.indexOf("qq");
  const fromIndex = parts.indexOf("from");
  const toIndex = parts.indexOf("to");

  if (qqIndex >= 0) {
    return {
      title: "Truth Table Exercise",
      blocks: [{ label: "Sentences", items: parseSentenceList(parts[qqIndex + 1] ?? "") }]
    };
  }

  return {
    title: "Truth Table Argument",
    blocks: [
      { label: "Premises", items: parseSentenceList(parts[fromIndex + 1] ?? "") },
      { label: "Conclusion", items: [toReadableSentence(parts[toIndex + 1] ?? "")] }
    ]
  };
}

function buildTorFQuestion(parts) {
  const qqIndex = parts.indexOf("qq");
  const fromIndex = parts.indexOf("from");
  const toIndex = parts.indexOf("to");

  if (qqIndex >= 0) {
    return {
      title: "True or False",
      blocks: [{ label: "Statements", items: parseSentenceList(parts[qqIndex + 1] ?? "") }]
    };
  }

  if (fromIndex >= 0 && toIndex >= 0) {
    return {
      title: "True or False Argument",
      blocks: [
        { label: "Premises", items: parseSentenceList(parts[fromIndex + 1] ?? "") },
        { label: "Conclusion", items: [toReadableSentence(parts[toIndex + 1] ?? "")] }
      ]
    };
  }

  return {
    title: "True or False",
    prose: parts.slice(2).join(" / ")
  };
}

function parseDomain(raw) {
  if (raw.includes("|")) {
    return raw.split("|").map(safeDecode);
  }

  const match = raw.match(/^([0-9]+)([\s\S]*?)(s?)$/);
  if (!match) {
    return [safeDecode(raw)];
  }

  const count = Number.parseInt(match[1], 10);
  const label = match[2];
  return Array.from({ length: count }, (_, index) => `${label}-${index + 1}`);
}

function buildTranslationQuestion(parts) {
  const domainIndex = parts.indexOf("domain");
  const namesIndex = parts.indexOf("names");
  const predicatesIndex = parts.indexOf("predicates");
  const sentenceIndex = parts.indexOf("sentence");
  const sentence = safeDecode(parts[sentenceIndex + 1] ?? "");

  let title = "Translation Exercise";
  try {
    fol.parseUsingSystemParser(sentence);
    title = `Translate ${fol.getPredLanguageName()} to English`;
  } catch {
    title = `Translate English to ${fol.getPredLanguageName()}`;
  }

  return {
    title,
    blocks: [
      { label: "Domain", items: parseDomain(parts[domainIndex + 1] ?? "") },
      {
        label: "Names",
        items: safeDecode(parts[namesIndex + 1] ?? "")
          .split("|")
          .filter(Boolean)
          .map((item) => item.replace(/=/g, " : "))
      },
      {
        label: "Predicates",
        items: safeDecode(parts[predicatesIndex + 1] ?? "")
          .split("|")
          .filter(Boolean)
      },
      { label: "Sentence", items: [toReadableSentence(sentence)] }
    ]
  };
}

function buildCreateLikeQuestion(parts, heading) {
  const qqIndex = parts.indexOf("qq");
  const fromIndex = parts.indexOf("from");
  const toIndex = parts.indexOf("to");

  if (qqIndex >= 0) {
    return {
      title: heading,
      blocks: [{ label: "Sentences", items: parseSentenceList(parts[qqIndex + 1] ?? "") }]
    };
  }

  return {
    title: heading,
    blocks: [
      { label: "Premises", items: parseSentenceList(parts[fromIndex + 1] ?? "") },
      { label: "Conclusion", items: [toReadableSentence(parts[toIndex + 1] ?? "")] }
    ]
  };
}

function buildTreeQuestion(parts) {
  const requireIndex = parts.indexOf("require");
  const requirements =
    requireIndex >= 0 ? safeDecode(parts[requireIndex + 1] ?? "").split("|").filter(Boolean) : [];
  const baseQuestion = buildCreateLikeQuestion(parts, "Tree Exercise");
  return {
    ...baseQuestion,
    notes: requirements
  };
}

function buildScopeQuestion(parts) {
  const qqIndex = parts.indexOf("qq");
  return {
    title: "Scope Exercise",
    blocks: [{ label: "Sentences", items: parseSentenceList(parts[qqIndex + 1] ?? "") }]
  };
}

function buildFallbackQuestion(parts) {
  return {
    title: "Exercise",
    prose: parts.join(" / ")
  };
}

export function parseExerciseQuestion(exerciseId) {
  const parsed = parseSegmentedExerciseId(exerciseId);

  switch (parsed.type) {
    case "proof":
      return buildProofQuestion(parsed.parts);
    case "q":
      return buildQuestionQuestion(parsed.parts);
    case "tt":
      return buildTruthQuestion(parsed.parts);
    case "TorF":
      return buildTorFQuestion(parsed.parts);
    case "trans":
      return buildTranslationQuestion(parsed.parts);
    case "create":
      return buildCreateLikeQuestion(parsed.parts, "Create a Possible Situation");
    case "counter":
      return buildCreateLikeQuestion(parsed.parts, "Counterexample Exercise");
    case "tree":
      return buildTreeQuestion(parsed.parts);
    case "scope":
      return buildScopeQuestion(parsed.parts);
    default:
      return buildFallbackQuestion(parsed.parts);
  }
}

function getExerciseFormulaContext(exerciseId) {
  const { parts, type } = parseSegmentedExerciseId(exerciseId);
  const qqIndex = parts.indexOf("qq");
  const fromIndex = parts.indexOf("from");
  const toIndex = parts.indexOf("to");

  if (type === "tt" || type === "TorF" || type === "scope" || type === "create" || type === "counter") {
    if (qqIndex >= 0) {
      return {
        sentences: parseFormulaObjectsFromText(parts[qqIndex + 1] ?? ""),
        labels: parseSentenceList(parts[qqIndex + 1] ?? "")
      };
    }
  }

  if (fromIndex >= 0 && toIndex >= 0) {
    const premises = parseFormulaObjectsFromText(parts[fromIndex + 1] ?? "");
    const conclusion = parseFormulaObjectsFromText(parts[toIndex + 1] ?? "")[0];
    const labels = [
      ...parseSentenceList(parts[fromIndex + 1] ?? ""),
      toReadableSentence(parts[toIndex + 1] ?? "")
    ];
    return {
      premises,
      conclusion,
      sentences: conclusion ? [...premises, conclusion] : premises,
      labels
    };
  }

  return { sentences: [], labels: [] };
}

function getTruthTableLetters(formulaObjects) {
  const letters = new Set();
  for (const sentence of formulaObjects) {
    for (const letter of sentence.getSentenceLetters()) {
      letters.add(letter);
    }
  }
  return [...letters];
}

function formatTruthValue(value) {
  if (value === true) {
    return "T";
  }
  if (value === false) {
    return "F";
  }
  return "";
}

function renderTruthValues(answerDocument, exerciseId) {
  const values = answerDocument?.answer?.content?.TorF ?? [];
  const context = getExerciseFormulaContext(exerciseId);
  const labels =
    context.labels.length > 0
      ? context.labels
      : values.map((_, index) => `Statement ${index + 1}`);

  return {
    kind: "truth-values",
    title: "Truth values",
    items: values.map((value, index) => ({
      label: labels[index] ?? `Statement ${index + 1}`,
      value: String(value)
    }))
  };
}

function renderTruthTable(answerDocument, exerciseId) {
  const rows = answerDocument?.answer?.content?.tt ?? [];
  const context = getExerciseFormulaContext(exerciseId);
  const letters = getTruthTableLetters(context.sentences);
  return {
    kind: "truth-table",
    title: "Truth table",
    headers: [...letters, ...context.labels],
    rows: rows.map((row) => row.map(formatTruthValue))
  };
}

function renderProof(answerDocument) {
  const proofText = answerDocument?.answer?.content?.proof ?? "";
  const dialectName = answerDocument?.answer?.content?.dialectName;
  const dialectVersion = answerDocument?.answer?.content?.dialectVersion;
  const dialectLabel =
    dialectName || dialectVersion ? `${dialectName ?? "[unspecified]"} (version ${dialectVersion ?? "?"})` : null;

  try {
    const parsed = parseProof(proofText);
    if (typeof parsed === "string") {
      throw new Error(parsed);
    }

    return {
      kind: "proof",
      title: "Proof",
      dialectLabel,
      lines: parsed.toString({ numberLines: true }).split("\n")
    };
  } catch {
    return {
      kind: "proof",
      title: "Proof",
      dialectLabel,
      lines: proofText.split("\n")
    };
  }
}

function renderSentence(answerDocument) {
  const sentence = answerDocument?.answer?.content?.sentence ?? "";
  const dialectName = answerDocument?.answer?.content?.dialectName;
  const dialectVersion = answerDocument?.answer?.content?.dialectVersion;
  return {
    kind: "sentence",
    title: "Sentence",
    dialectLabel:
      dialectName || dialectVersion ? `${dialectName ?? "[unspecified]"} (version ${dialectVersion ?? "?"})` : null,
    sentence,
    normalizedSentence: safeParseFormula(sentence)
  };
}

const POSSIBLE_WORLD_MOUTHS = [
  { symbol: ")", predicates: ["Happy", "Smiling"] },
  { symbol: "|", predicates: ["Neutral"] },
  { symbol: "(", predicates: ["Sad"] },
  { symbol: "D", predicates: ["Laughing", "Happy"] },
  { symbol: "()", predicates: ["Surprised"] },
  { symbol: "{}", predicates: ["Angry"] }
];

const POSSIBLE_WORLD_EYES = [
  { symbol: ":", predicates: [] },
  { symbol: "}:", predicates: ["Frowning"] },
  { symbol: ";", predicates: ["Winking"] },
  { symbol: ":'", predicates: ["Crying"] },
  { symbol: "|%", predicates: ["Confused"] }
];

const POSSIBLE_WORLD_NOSE = [
  { symbol: "-", predicates: [] },
  { symbol: ">", predicates: ["HasLargeNose"] },
  { symbol: "^", predicates: [] }
];

const POSSIBLE_WORLD_ABBREVIATIONS = {
  w: "width",
  h: "height",
  n: "name",
  c: "colour",
  f: "face"
};

function unabbreviateWorldNode(node) {
  const normalized = {};
  for (const [key, value] of Object.entries(node)) {
    normalized[POSSIBLE_WORLD_ABBREVIATIONS[key] ?? key] = value;
  }
  return normalized;
}

function getPredicatesForFace(symbol, catalogue) {
  return catalogue.find((item) => item.symbol === symbol)?.predicates ?? [];
}

function getPossibleWorldDescriptors(node) {
  const [eyesSymbol, noseSymbol, mouthSymbol] = node.face ?? [":", "-", "|"];
  const facialPredicates = [
    ...getPredicatesForFace(mouthSymbol, POSSIBLE_WORLD_MOUTHS),
    ...getPredicatesForFace(eyesSymbol, POSSIBLE_WORLD_EYES),
    ...getPredicatesForFace(noseSymbol, POSSIBLE_WORLD_NOSE)
  ];

  const colour = node.colour ? node.colour[0].toUpperCase() + node.colour.slice(1) : "White";
  const shape = node.height === 3 ? "Tall" : "Short";
  const width = node.width === 3 ? "Wide" : "Narrow";

  return [colour, shape, width, ...facialPredicates].filter(Boolean);
}

function renderPossibleWorld(answerDocument) {
  const world = answerDocument?.answer?.content?.world ?? [];
  const objects = world.map((rawNode, index) => {
    const node = unabbreviateWorldNode(rawNode);
    return {
      id: `object-${index}`,
      x: node.x ?? 0,
      y: node.y ?? 0,
      width: node.width ?? 2,
      height: node.height ?? 2,
      name: node.name ?? "",
      colour: node.colour ?? "white",
      face: node.face ?? [":", "-", "|"],
      descriptors: getPossibleWorldDescriptors(node)
    };
  });

  const maxX = Math.max(...objects.map((object) => object.x + object.width), 0);
  const maxY = Math.max(...objects.map((object) => object.y + object.height), 0);

  return {
    kind: "possible-world",
    title: "Possible situation",
    columns: Math.max(maxX, 6),
    rows: Math.max(maxY, 4),
    objects
  };
}

function renderCounterexample(answerDocument) {
  const counterexample = answerDocument?.answer?.content?.counterexample;
  return {
    kind: "counterexample",
    title: "Counterexample",
    domain: counterexample?.domain ?? [],
    names: Object.entries(counterexample?.names ?? {}),
    predicates: Object.entries(counterexample?.predicates ?? {}).map(([name, extension]) => ({
      name,
      extension: JSON.stringify(extension).replace(/^\[/, "{ ").replace(/\]$/, " }")
    }))
  };
}

function renderScope(answerDocument, exerciseId) {
  const answers = answerDocument?.answer?.content?.scope ?? [];
  const context = getExerciseFormulaContext(exerciseId);
  const renderedSentences = context.sentences.map((sentence, index) => ({
    html: sentence.toString({ replaceSymbols: true, wrapWithDivs: true }),
    selection: answers[index] ?? null
  }));

  return {
    kind: "scope",
    title: "Scope selections",
    sentences: renderedSentences
  };
}

function renderTree(answerDocument) {
  return {
    kind: "tree",
    title: "Tree proof",
    code: JSON.stringify(answerDocument?.answer?.content?.tree ?? {}, null, 2)
  };
}

function renderFallback(answerDocument) {
  return {
    kind: "fallback",
    title: "Answer data",
    code: JSON.stringify(answerDocument?.answer?.content ?? {}, null, 2)
  };
}

export function createRawAnswerView(answerDocument) {
  return {
    kind: "raw",
    title: "Raw data",
    code: JSON.stringify(answerDocument, null, 2)
  };
}

export function createRenderedAnswerView(answerDocument, exerciseId) {
  const content = answerDocument?.answer?.content ?? {};

  if (Array.isArray(content.tt)) {
    return renderTruthTable(answerDocument, exerciseId);
  }

  if (typeof content.proof === "string") {
    return renderProof(answerDocument);
  }

  if (typeof content.sentence === "string") {
    return renderSentence(answerDocument);
  }

  if (Array.isArray(content.TorF)) {
    return renderTruthValues(answerDocument, exerciseId);
  }

  if (Array.isArray(content.world)) {
    return renderPossibleWorld(answerDocument);
  }

  if (content.counterexample) {
    return renderCounterexample(answerDocument);
  }

  if (Array.isArray(content.scope)) {
    return renderScope(answerDocument, exerciseId);
  }

  if (content.tree) {
    return renderTree(answerDocument);
  }

  return renderFallback(answerDocument);
}

export function createExerciseRecord({ course, exerciseSet, lecture, unit, exercise }) {
  return {
    slug: encodeURIComponent(exercise.exerciseId),
    exerciseId: exercise.exerciseId,
    type: parseSegmentedExerciseId(exercise.exerciseId).type,
    courseName: course.name,
    courseId: encodeURIComponent(course.name),
    exerciseSetVariant: exerciseSet.variant,
    lectureName: lecture.name,
    unitName: unit.name,
    answerCount: exercise.answers?.length ?? 0,
    question: parseExerciseQuestion(exercise.exerciseId),
    answers: (exercise.answers ?? []).map((answer) => ({
      ...answer,
      rendered: createRenderedAnswerView(answer, exercise.exerciseId),
      raw: createRawAnswerView(answer)
    }))
  };
}
