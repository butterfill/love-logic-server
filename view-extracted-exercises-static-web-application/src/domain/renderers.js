import { fol } from "@butterfill/awfol/browser";

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

function formatBoolArray(values) {
  return values.map((value, index) => `#${index + 1}: ${String(value)}`);
}

export function renderAnswerSummary(answerDocument) {
  const content = answerDocument?.answer?.content ?? {};

  if (typeof content.proof === "string") {
    return {
      title: "Proof",
      code: content.proof
    };
  }

  if (typeof content.sentence === "string") {
    return {
      title: "Sentence",
      prose: content.sentence
    };
  }

  if (Array.isArray(content.TorF)) {
    return {
      title: "Truth Values",
      items: formatBoolArray(content.TorF)
    };
  }

  if (content.counterexample || content.world) {
    return {
      title: "Possible Situation",
      code: JSON.stringify(content.counterexample ?? content.world, null, 2)
    };
  }

  if (content.tree) {
    return {
      title: "Tree",
      code: JSON.stringify(content.tree, null, 2)
    };
  }

  return {
    title: "Answer Data",
    code: JSON.stringify(content, null, 2)
  };
}

export function createExerciseRecord({ course, exerciseSet, lecture, unit, exercise }) {
  const question = parseExerciseQuestion(exercise.exerciseId);
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
    question,
    answers: (exercise.answers ?? []).map((answer) => ({
      ...answer,
      rendered: renderAnswerSummary(answer)
    }))
  };
}
