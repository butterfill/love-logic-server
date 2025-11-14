# Love-Logic-Server: Exercise Grading Logic & Core Algorithms

**Document Version:** 1.0  
**Date:** November 14, 2025  
**Classification:** Core Intellectual Property - Automated Grading System

---

## Executive Summary

This document provides a comprehensive technical specification of the love-logic-server's exercise grading system. The automated grading logic is the core intellectual property of this application, enabling instant feedback on student logic exercises. The system uses a combination of client-side machine grading, server-side validation, and human grading caching through the GradedAnswers system.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Exercise Types](#exercise-types)
   - [Truth Table Exercises (tt)](#truth-table-exercises-tt)
   - [Proof Exercises (proof)](#proof-exercises-proof)
   - [Translation Exercises (trans)](#translation-exercises-trans)
   - [Create Exercise (create)](#create-exercise-create)
   - [Counterexample Exercises (counter)](#counterexample-exercises-counter)
   - [True/False Exercises (TorF)](#truefalse-exercises-torf)
   - [Scope Exercises (scope)](#scope-exercises-scope)
   - [Tree Exercises (tree)](#tree-exercises-tree)
   - [Question Exercises (q)](#question-exercises-q)
3. [Answer Submission & Grading Flow](#answer-submission--grading-flow)
4. [GradedAnswers Cache System](#gradedanswers-cache-system)
5. [Core Algorithms](#core-algorithms)
6. [Exercise Metadata & Collection Structure](#exercise-metadata--collection-structure)

---

## Architecture Overview

### System Components

1. **Client-Side Processing**
   - Answer capture and formatting in `client/ex/*.coffee` templates
   - Real-time validation using logic libraries
   - Machine grading feedback generation
   - Integration with AWFOL (first-order logic library)

2. **Server-Side Processing**
   - Answer submission validation via `submitExercise` Meteor method
   - Database persistence to `SubmittedExercises` collection
   - Human feedback storage and updates

3. **Caching System**
   - `GradedAnswers` MongoDB collection stores graded answers
   - Enables automatic grading of identical answers previously graded by humans
   - Answer deduplication using hash of answer content

4. **Logic Libraries**
   - AWFOL (client/lib/awfol/awfol.bundle.js): First-order logic parsing and evaluation
   - Truth Table Engine (client/lib/truth_table/): Truth value evaluation
   - Possible Worlds (client/lib/possible_world/): World/situation evaluation

### Grading Strategy

```
Student Submits Answer
    ↓
Client: Generate Machine Feedback (if possible)
    ↓
Client: Calculate Answer Hash
    ↓
Client: Check GradedAnswers for identical answer
    ↓
Server: Persist Submission
    ├─ If human feedback cached → Auto-assign feedback
    └─ If no cache hit → Mark for human grading
    ↓
Tutor: Reviews & Grades (if needed)
    ↓
Grade Stored in GradedAnswers for future auto-grading
```

---

## Exercise Types

### Truth Table Exercises (tt)

**URL Structure:**
```
/ex/tt/qq/{sentence1}|{sentence2}|...
/ex/tt/from/{premise1}|{premise2}|.../to/{conclusion}
/ex/tt/from/{premise1}|{premise2}|.../to/{conclusion}/noQ/
```

**Exercise Purpose:**
Tests student ability to construct truth tables for:
- Single sentences (evaluate contradiction, tautology, contingency)
- Multiple sentences (evaluate logical equivalence, entailment)
- Arguments (determine validity via truth table analysis)

**Answer Format:**

```coffeescript
answer:
  type: 'tt'
  content:
    tt: [
      [true, false, true, false],    # row 1: [A value, B value, sentence1 value, ...]
      [true, true, false, true],     # row 2
      [false, false, true, false],   # row 3
      [false, true, false, true]     # row 4
    ]
    TorF: [true, false, true]        # (Optional) answers to follow-up questions
    dialectName: 'lpl'
    dialectVersion: '1.0'
```

**Answer Structure Details:**
- `tt` array: Each inner array represents one row of the truth table
- Columns are ordered: [sentence letter columns] + [sentence columns]
- Sentence letters ordered alphabetically (A, B, C, ...)
- Sentence columns represent value of each formula in that row
- Values: `true`, `false`, or `null` (if incomplete)
- `TorF` array (if asking questions): Answers to validity/equivalence questions

**Grading Algorithm:**

```
Step 1: Validate Row Count
  - Calculate expected rows = 2^(number of sentence letters)
  - Return error if student rows ≠ expected rows

Step 2: Validate Row Ordering
  - For each sentence letter, check binary pattern
  - Row order must be: [all false], [A=F,B=T], [A=T,B=F], [A=T,B=T]
  - Ensure rows follow standard binary counting pattern (reverse)

Step 3: Validate Column Values
  For each row and each sentence:
    - Evaluate sentence using current row's truth assignments
    - Compare student's value to computed actual value
    - All values must match exactly

Step 4: Validate Follow-up Questions (if present)
  If asking about single sentence:
    - correctTorFAnswers[0] = (no row where sentence is true) → contradiction
    - correctTorFAnswers[1] = (no row where sentence is false) → tautology
    - correctTorFAnswers[2] = (at least one row where sentence is true) → contingency
  
  If asking about argument validity:
    - correctTorFAnswers[0] = (no row where premises all true AND conclusion false) → valid
    - correctTorFAnswers[1..n] = (each row is a counterexample) → premise all true & conclusion false
  
  If asking about two sentences:
    - correctTorFAnswers[0] = (truth values identical in all rows) → logically equivalent
    - correctTorFAnswers[1] = (no row where sentence1 true AND sentence2 false) → sentence1 entails sentence2
    - correctTorFAnswers[2] = (no row where sentence2 true AND sentence1 false) → sentence2 entails sentence1

Step 5: Return Result
  Return {isCorrect: boolean, message: string}
```

**Edge Cases Handled:**
- Variable number of sentences (1, 2, or more)
- With/without follow-up questions
- Argument vs. sentence distinction
- Incomplete tables (null values)
- Invalid row counts or orderings

**Key Functions:**
- `ix.truthTable.checkAnswer(values)` - Main grading function
- `ix.truthTable.checkAnswerCorrectNofRows(values)` - Row count validation
- `ix.truthTable.checkAnswerCorrectRowOrder(values)` - Row ordering validation
- `ix.truthTable.getSentenceLetters()` - Extract sentence letters from formulas

---

### Proof Exercises (proof)

**URL Structure:**
```
/ex/proof/from/{premise1}|{premise2}|.../to/{conclusion}
/ex/proof/orInvalid/from/{premise1}|{premise2}|.../to/{conclusion}
```

**Exercise Purpose:**
Tests student ability to construct formal proofs using natural deduction rules.

**Answer Format:**

```coffeescript
answer:
  type: 'proof'
  content:
    proof: "| A and B\n| ---\n| A\n|∧Elim 1"  # Natural deduction proof text
    TorF: [false]                            # For orInvalid: answer to validity question
    dialectName: 'LPL'
    dialectVersion: '1.0'
```

**Proof Text Format:**
- Each line prefixed with `|`
- Premises listed first: `| Premise`
- Separator line: `|---`
- Proof lines contain formula and justification
- Format: `| {formula} {rule} {line_references}`
- Example: `| A    ∧Elim 1` means "A from ∧ Elimination applied to line 1"

**Grading Algorithm:**

```
Step 1: Parse Proof
  - Call proof.parse(proofText)
  - If parsing fails, return error message
  - Returns proof object or error string

Step 2: Verify Proof Structure
  - Call theProof.verify()
  - Checks:
    * Each inference step follows proof rules
    * Correct number of premises/conclusions used
    * No circular dependencies
    * All line references valid
  - Returns {isCorrect: boolean, errorMessages: string}

Step 3: Validate Premises and Conclusion
  - Extract conclusion from proof
  - Extract premises from proof
  - Compare to exercise specification:
    * Conclusion must match expected conclusion
    * Proof premises must be subset of allowed premises
    * All allowed premises may not be used

Step 4: Check Specific Subtype Requirements
  If orInvalid subtype:
    - Student must answer whether argument is valid (TorF[0])
    - Answer is checked against proof validity
  
  If regular proof:
    - Just verify proof is correct

Step 5: Return Result
  machineFeedback:
    isCorrect: boolean
    comment: string describing result
```

**Edge Cases Handled:**
- Invalid proof syntax
- Incomplete proofs
- Proof validity vs. argument validity
- Premises and conclusion extraction
- Multiple possible proof rules

**Key Functions:**
- `proof.parse(proofText)` - Parse proof text to proof object
- `theProof.verify()` - Verify proof correctness
- `ix.checkPremisesAndConclusionOfProof(theProof)` - Validate against exercise spec
- `ix.checkPremisesOfProofAreThePremisesAllowed(theProof, thePremises)` - Check premise usage

---

### Translation Exercises (trans)

**URL Structure:**
```
/ex/trans/domain/{domain_spec}/names/{name_assignments}/predicates/{predicate_defs}/sentence/{english_sentence}
/ex/trans/domain/{domain_spec}/names/{name_assignments}/predicates/{predicate_defs}/sentence/{fol_formula}
```

**Example URL:**
```
/ex/trans/domain/people/names/a=Ayesha|b=Beatrice/predicates/Runner1-x-is-a-runner|FasterThan2-xIsFasterThanY/sentence/Ayesha is a faster runner than Beatrice
```

**Exercise Purpose:**
Tests student ability to translate between English and first-order logic, or vice versa.

**Answer Format:**

For English → FOL translation:
```coffeescript
answer:
  type: 'trans'
  content:
    sentence: "Runner(a) and FasterThan(a,b)"
    dialectName: 'LPL'
    dialectVersion: '1.0'
machineFeedback:
  isFOLsentence: true
  hasFreeVariables: false
  usedCorrectNames: true
  usedCorrectPredicates: true
  comment: "Your answer is a sentence of LPL."
answerPNFsimplifiedSorted: "Runner(a) ∧ FasterThan(a,b)"
```

For FOL → English translation:
```coffeescript
answer:
  type: 'trans'
  content:
    sentence: "Ayesha is a runner who is faster than Beatrice"
# No machine feedback for English answers
```

**Grading Algorithm:**

**Case 1: Translation TO FOL (English input → FOL output)**

```
Step 1: Parse Student Answer
  - Try to parse student's text as FOL sentence
  - If parsing fails → error, answer not FOL
  - If success, continue

Step 2: Check for Free Variables
  - Extract free variables from parsed formula
  - If free variables exist:
    * Return error (answer must be sentence, no free variables)
    * Suggest student forgot quantifier or made bracket mistake

Step 3: Convert to PNF (Prenex Normal Form)
  - Convert answer to PNF
  - Simplify and sort for canonical comparison
  - Store as answerPNFsimplifiedSorted

Step 4: Validate Names Used
  - Extract names used in formula
  - Compare against allowed names in exercise
  - If non-allowed names used → error

Step 5: Validate Predicates Used
  - Extract predicates (name and arity)
  - Compare against allowed predicates in exercise
  - If non-allowed predicates used → error

Step 6: Try Cached Grading
  - Check GradedAnswers for this answer
  - If found and graded by human → use cached result
  - Otherwise, continue to Step 7

Step 7: Grade by Equivalence
  For each graded answer in cache:
    - Convert both to PNF
    - Check logical equivalence using isPNFExpressionEquivalent()
    - If equivalent and correct → mark as correct
    - If equivalent but incorrect → mark as incorrect

Step 8: Return Result
  If no cached equivalent found:
    - Return comment about answer being valid FOL
    - Leave isCorrect undefined (requires human grading)
  Else:
    - Return cached correctness
```

**Case 2: Translation FROM FOL (FOL input → English output)**

```
Step 1: Check Cache
  - Hash student's English answer
  - Normalize: lowercase, trim spaces, remove punctuation variations
  - Look up in GradedAnswers

Step 2: Return Result
  - If cache hit → return cached feedback
  - If cache miss → no machine feedback available
  - Submit for human grading
```

**Edge Cases Handled:**
- Free variables in answers
- Non-allowed names or predicates
- Case sensitivity in FOL
- Multiple spaces and formatting variations
- Logical equivalence (for FOL→FOL)
- English answer normalization

**Key Functions:**
- `fol.parseUsingSystemParser(text)` - Parse FOL formula
- `answerFOLobject.getFreeVariableNames()` - Check for free variables
- `answerFOLobject.convertToPNFsimplifyAndSort()` - Normalize for comparison
- `answerFOLobject.getNames()` - Extract names used
- `answerFOLobject.getPredicates()` - Extract predicates used

---

### Create Exercise (create)

**URL Structure:**
```
/ex/create/qq/{sentence1}|{sentence2}|...
/ex/create/orValid/from/{premise1}|{premise2}|.../to/{conclusion}
/ex/create/orInconsistent/qq/{sentence1}|{sentence2}|...
```

**Exercise Purpose:**
Tests student ability to create a possible world (situation) that satisfies given conditions:
- Make all given sentences true
- Make all premises true and conclusion false (counterexample)
- Make sentences logically inconsistent

**Answer Format:**

```coffeescript
answer:
  type: 'create'
  content:
    world: [
      {x:0, y:0, w:2, h:2, n:"a", c:"white", f:[":","^","D"]},
      {x:4, y:0, w:2, h:2, n:"b", c:"pink", f:[":'","-","D"]}
    ]
    TorF: [true]  # For orValid/orInconsistent: answer to validity/consistency question
    dialectName: 'LPL'
    dialectVersion: '1.0'
```

**World Object Structure (abbreviated):**
- `x`, `y`: Grid position
- `w`, `h`: Width and height in grid units
- `n`: Name(s) assigned to object (may be empty)
- `c`: Color (CSS color name: white, pink, purple, orange, etc.)
- `f`: Face array [eyes, nose, mouth] - symbols determining predicates

**Face Symbols:**
- Eyes: `:`, `}:`, `;`, `:'`, `|%` 
- Nose: `-`, `>`, `^`
- Mouth: `)`, `|`, `(`, `D`, `()`, `{}`

**Predicate Mapping from Face:**
- Color → Color predicates (White, Pink, Purple, Orange, etc.)
- Eyes/Nose/Mouth → Predicate based on symbol-to-property mapping
- Height (3=Tall, <3=Short) → Tall/Short predicates
- Width (3=Wide, <3=Narrow) → Wide/Narrow predicates
- Spatial relationships (LeftOf, RightOf, Above, Below, Adjacent, etc.)

**Grading Algorithm:**

```
Step 1: Validate World Structure
  - Try to create situation from serialized world
  - Check for duplicate name assignments
  - If error → return error message and isCorrect=false

Step 2: Determine Exercise Type
  If sentence(s) specified:
    Branch A: Make sentences true
  Else if argument specified (premises + conclusion):
    Branch B: Make counterexample
  Else:
    Return error

Step 3: BRANCH A - Make Sentences True
  - Evaluate each sentence against created situation
  - For each sentence:
    * Try sentence.evaluate(possibleSituation)
    * If evaluation throws error → invalid situation
  - All sentences must evaluate to true
  - Set isCorrect = (all sentences true)
  - comment = "Your submitted possible situation is [not] correct."

Step 4: BRANCH B - Make Counterexample
  - Evaluate each premise → must all be true
  - Evaluate conclusion → must be false
  - For each premise:
    * If any false → isCorrect = false, comment about premises
  - Check conclusion:
    * If true → isCorrect = false, comment about conclusion
    * If false → isCorrect = true
  - comment = "Your submitted possible situation is [not] a counterexample."

Step 5: Specific Subtype Handling
  If orValid subtype:
    - Student answers whether argument is valid (TorF[0])
    - If world is valid counterexample → answer must be false
    - If cannot find counterexample → answer must be true
  
  If orInconsistent subtype:
    - Student answers whether sentences are inconsistent (TorF[0])
    - Inconsistent = no possible world makes all true
    - If world makes all true → answer must be false
    - If no such world exists → answer must be true

Step 6: Return Result
  machineFeedback:
    isCorrect: boolean
    comment: string describing outcome
```

**Edge Cases Handled:**
- Invalid situation (duplicate names)
- Non-evaluable formulas
- Evaluation errors during sentence checking
- Distinguishing argument vs. sentence exercises
- Handling subtype variations (orValid, orInconsistent)

**Key Functions:**
- `ix.possibleWorld.getSituationFromSerializedWord(data)` - Create situation object
- `ix.possibleWorld.getPredicatesFromSerializedObject(item)` - Extract predicates from object
- `sentence.evaluate(situation)` - Evaluate sentence in situation
- `ix.possibleWorld.checkSentencesTrue($grid)` - Interactive validation
- `ix.possibleWorld.checkSentencesAreCounterexample($grid)` - Check counterexample validity

---

### Counterexample Exercises (counter)

**URL Structure:**
```
/ex/counter/qq/{sentence1}|{sentence2}|...
/ex/counter/orValid/from/{premise1}|{premise2}|.../to/{conclusion}
/ex/counter/orInconsistent/qq/{sentence1}|{sentence2}|...
```

**Exercise Purpose:**
Similar to Create exercise but uses explicit counterexample object (direct FOL situation object rather than visual world).

**Answer Format:**

```coffeescript
answer:
  type: 'counter'
  content:
    counterexample:
      domain: [0, 1]                    # Object IDs in domain
      names: {a: 0, b: 1}               # Name-to-object mappings
      predicates: {
        Happy: [[0]],                   # Unary predicates as arrays of tuples
        White: [[1]],
        Adjacent: [[0,1], [1,0]]        # Binary predicates
      }
    TorF: [false]  # For orValid/orInconsistent subtypes
    dialectName: 'LPL'
    dialectVersion: '1.0'
```

**Situation Structure:**
- `domain`: Array of object identifiers (usually integers 0, 1, 2, ...)
- `names`: Object mapping names (a, b, c, ...) to domain elements
- `predicates`: Object with predicate names as keys
  - Each predicate maps to array of tuples
  - Unary predicates: tuples of length 1, e.g., `[[0], [1]]` means "applies to 0 and 1"
  - Binary predicates: tuples of length 2, e.g., `[[0,1]]` means "applies to pair (0,1)"
  - N-ary predicates: tuples of length n

**Grading Algorithm:**

```
Step 1: Validate Situation Structure
  - Check domain is non-empty
  - Check all name references point to domain elements
  - Check all extension tuples reference only domain elements
  - If errors → return error message and isCorrect=false

Step 2: Determine Exercise Type (same as Create)
  Branch A: Make sentences true
  Branch B: Make counterexample (premises true, conclusion false)

Step 3: Grading (same as Create Steps 3-5)
  - Evaluate sentences in situation
  - Check all true for Branch A
  - Check premises true & conclusion false for Branch B

Step 4: Return Result
  machineFeedback:
    isCorrect: boolean
    comment: string
```

**Differences from Create:**
- Create uses visual world representation
- Counter uses mathematical FOL situations
- Predicates explicitly specified as relation tuples
- No face symbols or color mapping needed

**Key Functions:**
- `parseExtension(txt)` - Parse predicate extension text to array format
- `extensionToString(extension)` - Format extension for display
- `sentence.evaluate(counterexample)` - Evaluate in situation

---

### True/False Exercises (TorF)

**URL Structure:**
```
/ex/TorF/qq/{sentence1}|{sentence2}|...
/ex/TorF/from/{premise1}|{premise2}|.../to/{conclusion}/TTrow/{assignments}
/ex/TorF/from/{premise1}|{premise2}|.../to/{conclusion}/world/{world_json}
/ex/TorF/from/{premise1}|{premise2}|.../to/{conclusion}/qq/{question}
```

**Example URLs:**
```
/ex/TorF/qq/A or B|B and not A|(A∨B)∧¬(B∧¬A)
/ex/TorF/from/Happy(a)|not White(b)/to/exists x (Happy(x) and White(x))/world/{...}
/ex/TorF/from/not A|A arrow B/to/not B/TTrow/A:F|B:T
```

**Exercise Purpose:**
Tests student ability to evaluate truth values of sentences under specific conditions:
- Truth values according to a truth table row
- Truth values in a possible world
- Validity/counterexample properties of arguments
- Logical properties of sentences

**Answer Format:**

```coffeescript
answer:
  type: 'TorF'
  content:
    TorF: [true, false, true, false]  # Array of boolean values
    dialectName: 'LPL'
    dialectVersion: '1.0'
```

**Grading Algorithm:**

```
Step 1: Extract World Information
  Try in order:
    a) Get possible world from URL parameter
    b) Get truth table row assignment from TTrow parameter
    c) If neither available, use default (propositional evaluation)

Step 2: Create World Object
  For truth table row:
    world = {A: true, B: false, ...}  # Simple key-value mapping
  
  For possible world:
    world = {domain, predicates, names}  # Full FOL situation

Step 3: For Each Sentence
  If sentence is evaluable formula:
    - Evaluate sentence against world
    - Compare to student's answer
  
  If sentence is about counterexample:
    - Extract counterexample definition from sentence text
    - Check premises true, conclusion false in world
    - Compare to student's answer
  
  If sentence is about validity/consistency:
    - Parse sentence semantic meaning
    - Determine expected truth value
    - Compare to student's answer

Step 4: Check All Answers
  errors = []
  For each sentence:
    result = checkOneAnswer(answer[idx], sentence)
    if result is false → add idx to errors
  
  If errors.length = 0 → isCorrect = true
  Else → isCorrect = false, comment with percentage correct

Step 5: Return Result
  machineFeedback:
    isCorrect: boolean
    comment: "You got X% right." (if not 100%)
```

**Sentence Evaluation Details:**

For standard formulas:
- `sentence.evaluate(world)` returns true/false/undefined

For counterexample detection:
- Text contains "counterexample"
- Check if world is counterexample to argument
- Counterexample = premises true AND conclusion false
- Handle negations in question text

**Edge Cases Handled:**
- Multiple sentence types (formulas, counterexample questions)
- Truth table rows vs. full situations
- Negated questions ("not a counterexample")
- Partial credit reporting
- Non-evaluable formulas

**Key Functions:**
- `checkOneAnswer(answer, sentence)` - Evaluate single answer
- `checkAllAnswers(answers)` - Validate all student answers
- `getWorld()` - Extract world from URL or state
- `sentence.evaluate(world)` - FOL evaluation

---

### Scope Exercises (scope)

**URL Structure:**
```
/ex/scope/qq/{sentence1}|{sentence2}|...
```

**Example:**
```
/ex/scope/qq/∃x ∀y Loves(x,y)|∀x ∃y Loves(x,y)
```

**Exercise Purpose:**
Tests student understanding of quantifier scope by requiring them to identify the scope of a specific quantifier occurrence.

**Answer Format:**

```coffeescript
answer:
  type: 'scope'
  content:
    scope: [
      {scopeDepth: 1, symbolNum: "0"},   # First sentence: symbol 0, scope depth 1
      {scopeDepth: 2, symbolNum: "1"}    # Second sentence: symbol 1, scope depth 2
    ]
    dialectName: 'LPL'
    dialectVersion: '1.0'
```

**Scope Depth Definition:**
- Scope depth = number of nested operator/quantifier wrappings
- Depth 1 = topmost scope (minimal nesting)
- Depth 2 = inside one nesting level
- Etc.

**Symbol Identification:**
- Each symbol/operator in a sentence gets a unique data-symbolNum attribute
- Student selects which symbol's scope to identify
- System counts DOM nesting levels to determine depth

**Grading Algorithm:**

```
Step 1: Extract Answer
  - For each sentence, identify selected symbol
  - If no symbol selected → record as empty/missing

Step 2: Validate Scope Depth
  For each sentence with selected symbol:
    - Expected: scopeDepth must be 1 (symbol at correct depth)
    - Incorrect: any other scopeDepth
    - The quantifier at depth 1 is the target quantifier

Step 3: Calculate Correctness
  correctTorFAnswers = [scopeDepth == 1 for each answer]
  
  isCorrect = not (false in correctTorFAnswers)
  
  If isCorrect:
    comment = "Well done!"
  Else:
    nofIncorrect = count of false values
    comment = "You got #{nofIncorrect} wrong."

Step 4: Return Result
  machineFeedback:
    isCorrect: boolean
    comment: string
```

**Edge Cases Handled:**
- Multiple sentences in single exercise
- No symbol selected (empty answer)
- Nested quantifiers (multiple scope depths)
- Quantifier vs. operator scope
- Visual highlighting of selected scope

**Key Functions:**
- `getAnswer()` - Extract student selections from DOM
- `setAnswer(answers)` - Restore previously saved answer
- `selectSymbol($el)` - Handle symbol click
- Scope depth computed from `.parents('._expressionWrap').length`

---

### Tree Exercises (tree)

**URL Structure:**
```
/ex/tree/require/{requirement}/from/{premise1}|{premise2}|.../to/{conclusion}
/ex/tree/require/{requirement}/qq/{sentence1}|{sentence2}|...
```

**Requirements:**
- `complete` - All branches closed or open (marked)
- `closed` - All branches closed (argument valid)
- `closedOrCompleteOpenBranch` - All branches closed OR has complete open branch
- `stateIfValid` - Must state if argument is valid
- `stateIfConsistent` - Must state if sentences are consistent

**Exercise Purpose:**
Tests student ability to construct analytic tableau (tree proofs) to determine logical properties.

**Answer Format:**

```coffeescript
answer:
  type: 'tree'
  content:
    tree: {
      # Bare tree proof object - represents complete tree structure
      # Contains nodes, branches, closures, etc.
    }
    TorF: [true]  # For stateIfValid/stateIfConsistent: validity/consistency answers
    dialectName: 'LPL'
    dialectVersion: '1.0'
```

**Tree Object Structure:**
- Represents analytic tableau proof tree
- Nodes contain formulas
- Branches represent alternative possibilities
- Open branches left unclosed
- Closed branches marked with closure evidence

**Grading Algorithm:**

```
Step 1: Validate Tree Structure
  - Call tree.decorateTreeProof(treeProof)
  - Call treeProof.verify()
  - Check for structural errors:
    * Invalid nodes
    * Malformed branches
    * Missing closures
  - Returns {isCorrect, errorMessages}

Step 2: Check Premises/Set Members
  If argument (conclusion specified):
    allowedPremises = premises ∪ {¬conclusion}
  Else (set of sentences):
    allowedPremises = sentences
  
  Verify tree doesn't use premises outside allowed set:
    test = ix.checkPremisesOfProofAreThePremisesAllowed(treeProof, allowedPremises)
    If string error → tree uses wrong premises

Step 3: Check Specific Requirements
  For each requirement in URL:
    
    If 'complete':
      - Check treeProof.areAllBranchesClosedOrOpen()
      - All branches must have closure mark or open mark
    
    If 'closed':
      - Check treeProof.areAllBranchesClosed()
      - All branches must be closed
    
    If 'closedOrCompleteOpenBranch':
      - Either: all branches closed
      - Or: at least one complete open branch with no contradictions
    
    If 'stateIfValid':
      - Check tree structure meets closedOrCompleteOpenBranch
      - Check student answer: TorF[0] = true iff all branches closed
      - Valid = all branches closed (proof by contradiction)
      - Invalid = has open branch (counterexample exists)
    
    If 'stateIfConsistent':
      - Check tree structure meets closedOrCompleteOpenBranch
      - Check student answer: TorF[0] = true iff NOT all branches closed
      - Consistent = has open branch (situation satisfies sentences)
      - Inconsistent = all branches closed (no satisfying situation)

Step 4: Return Result
  If any requirement check fails:
    machineFeedback:
      isCorrect: false
      comment: specific error message
  Else:
    machineFeedback:
      isCorrect: true
      comment: "Your answer is correct."
```

**Edge Cases Handled:**
- Empty/incomplete trees
- Incorrectly marked branches
- Wrong premises used
- Incorrect validity/consistency answers
- Multiple requirement combinations
- Tree format conversions (symbols vs. text)

**Key Functions:**
- `tree.decorateTreeProof(treeProof)` - Add display/validation info
- `tree.makeTreeProof(text)` - Create tree from text
- `treeProof.verify()` - Validate tree correctness
- `treeProof.areAllBranchesClosed()` - Check if argument valid
- `treeProof.hasOpenBranch()` - Check if has open branch
- `treeProof.convertToSymbols()` - Render with logical symbols
- `treeProof.toBareTreeProof()` - Serialize for storage

---

### Question Exercises (q)

**URL Structure:**
```
/ex/q/{question_text}
```

**Example:**
```
/ex/q/Define logically valid argument
/ex/q/state the rules for conjunction
```

**Exercise Purpose:**
Tests student understanding through open-ended questions requiring written answers.

**Answer Format:**

```coffeescript
answer:
  type: 'q'
  content: "An argument is valid just if there is no possible situation in which the premises are true and the conclusion is false."
  dialectName: 'lpl'
  dialectVersion: '1.0'
```

**Grading Algorithm:**

```
Step 1: Check for Cached Grading
  - Hash student's answer (normalized: lowercase, trim, remove punctuation)
  - Look up in GradedAnswers collection
  - If found → return cached feedback

Step 2: Normalize Answer Text
  - Convert to lowercase
  - Replace multiple spaces with single space
  - Trim leading/trailing whitespace
  - Remove variation in punctuation

Step 3: Find Matching Graded Answers
  - Search GradedAnswers for answers with same hash
  - If multiple grades → check for conflicts
    * conflict = some graded as correct, some as incorrect
    * Don't auto-grade if conflict exists

Step 4: Return Result
  If no cache hit or conflict:
    - No machine feedback available
    - Submit for human grading
  If cache hit:
    humanFeedback:
      isCorrect: boolean (from cache)
      comment: string (tutor's comment from cache)
```

**Answer Deduplication:**
Uses `ix.hashAnswer()` which:
1. Extracts answer content
2. Lowercases text
3. Removes extra whitespace
4. Trims whitespace
5. Combines with exerciseId
6. Hashes with XXH (murmur-like hash function)

**Edge Cases Handled:**
- Blank answers (optional)
- Minor text variations (case, punctuation)
- Conflicting human grades
- Multiple graders of same answer

**Key Functions:**
- `ix.gradeUsingGradedAnswers(doc)` - Look up cached grades
- `ix.hashAnswer(answerDoc)` - Generate answer hash
- `ix.hash(text)` - Hash function (XXH)

---

## Answer Submission & Grading Flow

### High-Level Flow

```
User submits answer
    ↓
[CLIENT] Capture answer and format for submission
    ↓
[CLIENT] Generate machine feedback (if applicable)
    ├─ Truth table: Check rows, formulas
    ├─ Proof: Parse and verify structure
    ├─ Translation: Check FOL or English validity
    ├─ Create/Counter: Evaluate situation
    ├─ TorF: Evaluate formulas in world
    ├─ Scope: Check quantifier scope
    ├─ Tree: Verify tableau structure
    └─ Question: Try to find cached grade
    ↓
[CLIENT] Calculate answer hash (for caching)
    ├─ For text answers: normalize case, spacing
    ├─ For structured answers: stringify content
    └─ Append exerciseId to hash input
    ↓
[CLIENT] Check GradedAnswers collection for cached results
    ├─ If found → may reuse cached feedback
    └─ If not found → continue to submission
    ↓
[CLIENT] Call Meteor.method 'submitExercise'
    ↓
[SERVER] Validate and store submission
    ├─ Check user is authenticated
    ├─ Create SubmittedExercises document
    ├─ Use findAndModify to upsert (avoid duplicates)
    └─ Store: owner, exerciseId, answer, machineFeedback, created date
    ↓
[SERVER] Return confirmation to client
    ↓
[CLIENT] Show success message
```

### submitExercise Meteor Method

**Location:** `love-logic.coffee`, lines 205-229

```coffeescript
submitExercise : (exercise) ->
  # Input: exercise object containing answer and feedback
  # Process:
  userId = Meteor.user()?._id
  if not userId or 'userId' of exercise
    throw new Meteor.Error "not-authorized"
  
  # Add metadata to submission
  newDoc = _.defaults(exercise, {
    owner : userId
    ownerName : Meteor.user().profile?.name
    email : Meteor.user().emails[0].address
    created : new Date()
  })
  
  # Only runs on server
  if Meteor.isClient
    return undefined
  
  # Upsert document (insert if not exists, update if exists)
  rawSubmittedExercises = SubmittedExercises.rawCollection()
  findAndModify = Meteor.wrapAsync(rawSubmittedExercises.findAndModify, rawSubmittedExercises)
  
  # Find query: match owner, exerciseId, and no existing human feedback
  query = { 
    owner : userId, 
    exerciseId : exercise.exerciseId, 
    humanFeedback : {$exists:false} 
  }
  
  # Upsert operation: insert or update
  findAndModify(query, {}, newDoc, {upsert: true})
```

**Key Properties:**
- **Idempotency:** Repeated submissions with same exerciseId replace previous submission (unless already graded by human)
- **Protection:** Cannot override human feedback once submitted
- **Metadata:** Automatically adds owner, name, email, timestamp
- **No Client Simulation:** Method runs only on server (security)

### SubmittedExercises Collection Schema

```
{
  _id: ObjectId,
  
  # User information
  owner: userId,
  ownerName: String,
  email: String,
  
  # Exercise identification
  exerciseId: String (encoded path),
  
  # Student's answer
  answer: {
    type: String (tt|proof|trans|create|counter|TorF|scope|tree|q),
    content: Mixed (varies by type),
    dialectName: String (optional),
    dialectVersion: String (optional)
  },
  
  # Machine-generated feedback (if available)
  machineFeedback: {
    isCorrect: Boolean (optional),
    comment: String (optional),
    // Type-specific fields (e.g., isFOLsentence, hasFreeVariables)
  },
  
  # Human-generated feedback (tutor grading)
  humanFeedback: {
    isCorrect: Boolean,
    comment: String,
    graderId: userId,
    studentSeen: Boolean,
    studentEverSeen: Boolean
  },
  
  # Metadata
  created: Date,
  userAgent: String
}
```

### Client-Side Grading Integration

**Location:** `client/ex/*.coffee` (each exercise type template)

**Pattern:**

```coffeescript
Template.exercise_type_ex.events
  'click button#submit' : (event, template) ->
    # Step 1: Get student answer
    answer = ix.getAnswer()
    
    # Step 2: Try machine grading
    result = doMachineGrading(answer)
    machineFeedback = {
      isCorrect: result.isCorrect
      comment: result.message
    }
    
    # Step 3: Prepare submission document
    doc = {
      answer: {
        type: 'exercise_type'
        content: answer
      }
      machineFeedback: machineFeedback  # may be undefined
    }
    
    # Step 4: Try cached grading (for text answers)
    humanFeedback = ix.gradeUsingGradedAnswers(doc)
    if humanFeedback?
      doc.humanFeedback = humanFeedback
    
    # Step 5: Add dialect info
    ix.addDialectInfoToAnswerDoc(doc)
    
    # Step 6: Submit
    ix.submitExercise(doc, callback)
```

---

## GradedAnswers Cache System

### Purpose

Enables automatic grading of answers previously graded by human instructors. Avoids re-grading identical answers and provides consistent feedback across all students.

### Collection Structure

**Location:** `love-logic.coffee`, line 21

```
@GradedAnswers = new Mongo.Collection('graded_answers')
```

**Document Schema:**

```
{
  _id: ObjectId,
  
  # Identification (composite unique key)
  exerciseId: String,
  ownerIdHash: String,              # Hash of original grader's ID
  answerHash: String,               # Hash of answer content
  
  # Grading result
  isCorrect: Boolean,
  comment: String (optional),
  
  # For FOL translation caching
  answerPNFsimplifiedSorted: String (optional),
  
  # For proof/tree proofs
  answer: {
    content: {
      dialectName: String,
      dialectVersion: String
    }
  },
  
  # Metadata
  graderId: userId,
  created: Date (implicit)
}
```

### Answer Hashing Algorithm

**Location:** `client/lib/ix.coffee`, lines 191-218

```coffeescript
ix.hash = (text) ->
  return XXH(text, 0xFFFA).toString(36)

ix.hashAnswer = (answerDoc) ->
  toHash = answerDoc.answer.content
  
  if _.isString(toHash)
    # For text answers: normalize case and whitespace
    toHash = toHash.toLowerCase()
                   .replace(/\s+/g, ' ')    # Multiple spaces → single space
                   .trim()                   # Remove leading/trailing
  else
    # For structured answers
    if _.isString(toHash.sentence)
      unless answerDoc.answerPNFsimplifiedSorted?
        toHash = _.clone(toHash)
        toHash.sentence = toHash.sentence.toLowerCase()
                                         .replace(/\s+/g, ' ')
                                         .trim()
    toHash = JSON.stringify(toHash)
  
  exerciseId = ix.getExerciseId()
  if not exerciseId?
    throw new Meteor.Error "could not get exercise id"
  
  toHash += exerciseId  # Append exercise ID
  r = ix.hash(toHash)
  return r
```

**Hash Strategy:**
- **Text answers:** Normalize case, whitespace; hash normalized text + exerciseId
- **Structured answers:** Stringify JSON; hash normalized JSON + exerciseId
- **FOL answers:** When possible, use PNF form for equivalence detection
- **Hash function:** XXH (32-bit Murmur-like hash) converted to base-36 string

**Advantages:**
- Case-insensitive matching for English text
- Whitespace-invariant matching
- Exercise-specific (same answer = different hash for different exercises)
- Efficient string comparison

### Grading with Cache

**Location:** `client/lib/ix.coffee`, lines 220-285

```coffeescript
ix.gradeUsingGradedAnswers = (answerDoc, o) ->
  o ?= {}
  exerciseId = ix.getExerciseId()
  return undefined if GradedAnswers.find({exerciseId}).count() is 0
  
  answerDoc ?= {answer:{content:ix.getAnswer()}}
  answerHash = ix.hashAnswer(answerDoc)
  
  # Add dialect after hash (doesn't affect correctness)
  ix.addDialectInfoToAnswerDoc(answerDoc)
  
  # Look for exact hash match
  thisAnswersGrades = GradedAnswers.find({exerciseId, answerHash})
  
  # Check for unique correct answer
  if o.uniqueAnswer and thisAnswersGrades.count() is 0
    if GradedAnswers.find({exerciseId, isCorrect:true}).count() isnt 0
      return { isCorrect:false }
  
  # No exact match found
  if thisAnswersGrades.count() is 0
    # Try PNF equivalence (for FOL expressions)
    if answerDoc.answerPNFsimplifiedSorted?
      return _gradePNF(answerDoc)
    else
      return undefined 
  
  # Found matching grades
  isCorrect = undefined
  comment = ''
  conflict = false
  
  for grade in thisAnswersGrades.fetch()
    if isCorrect isnt undefined and isCorrect isnt grade.isCorrect
      conflict = true
    isCorrect = grade.isCorrect
    if grade.comment?
      comment += grade.comment
  
  result = {}
  if comment? and comment isnt ''
    result.comment = comment
  if not conflict and isCorrect?
    result.isCorrect = isCorrect
  
  return result
```

**Matching Strategy:**
1. **Exact hash match:** If answerHash matches, use cached grade
2. **PNF equivalence:** For FOL answers, check logical equivalence
3. **Conflict detection:** If multiple grades with different outcomes, don't auto-grade
4. **Unique answer:** For some exercises (TorF), if only one correct answer exists and student's doesn't match it, auto-mark as incorrect
5. **Comment aggregation:** Combine comments from all matching grades

### PNF Equivalence Checking

**Location:** `client/lib/ix.coffee`, lines 258-285

```coffeescript
_gradePNF = (answerDoc) ->
  isCorrect = undefined
  comment = ''
  conflict = false
  answerPNF = answerDoc.answerPNFsimplifiedSorted
  exerciseId = ix.getExerciseId()
  
  for graded in GradedAnswers.find({exerciseId}).fetch()
    gradedPNF = graded.answerPNFsimplifiedSorted
    
    # Parse both with correct dialect
    ix.setDialectFromThisAnswer(graded.answer)
    g = fol.parse(gradedPNF)
    
    ix.setDialectFromThisAnswer(answerDoc.answer)
    a = fol.parse(answerPNF)
    
    # Check if logically equivalent
    test = a.isPNFExpressionEquivalent(g)
    
    if test
      if isCorrect isnt undefined and isCorrect isnt graded.isCorrect
        conflict = true
      isCorrect = graded.isCorrect
      if graded.comment?
        comment += graded.comment
  
  result = {}
  if comment? and comment isnt ''
    result.comment = comment
  if isCorrect? and not conflict
    result.isCorrect = isCorrect
  
  return result
```

**Equivalence Strategy:**
- Convert both answers to PNF (Prenex Normal Form)
- Simplify and sort both forms
- Use `isPNFExpressionEquivalent()` method
- Handles logically equivalent but syntactically different answers
- Sets correct dialect context before parsing

### Adding Grades to Cache

**Location:** `love-logic.coffee`, lines 318-346

```coffeescript
addGradedExercise : (exerciseId, ownerIdHash, answerHash, isCorrect, comment, answerPNFsimplifiedSorted, dialectName, dialectVersion) ->
  graderId = Meteor.user()?._id
  if not graderId
    throw new Meteor.Error "not-authorized"
  
  newDoc = {
    graderId
    exerciseId
    ownerIdHash
    answerHash
  }
  
  if answerPNFsimplifiedSorted
    newDoc.answerPNFsimplifiedSorted = answerPNFsimplifiedSorted
  
  if isCorrect?
    newDoc.isCorrect = isCorrect
  
  if comment? 
    newDoc.comment = comment
  
  if dialectName?
    newDoc.answer ?= {}
    newDoc.answer.content ?= {}
    newDoc.answer.content.dialectName = dialectName
    newDoc.answer.content.dialectVersion = dialectVersion
  
  # Upsert (only runs on server)
  if Meteor.isClient
    return undefined
  
  rawGradedAnswers = GradedAnswers.rawCollection()
  findAndModify = Meteor.wrapAsync(rawGradedAnswers.findAndModify, rawGradedAnswers)
  
  query = { $and:[
    {exerciseId}
    {ownerIdHash}
    {answerHash}
  ] }
  
  findAndModify(query, {}, newDoc, {upsert: true})
```

**Idempotency:**
- Uses composite key: (exerciseId, ownerIdHash, answerHash)
- Findandmodify = idempotent upsert
- Same grade added multiple times = no duplicates
- Comments can be updated/appended

### Human Grading Workflow

```
Tutor accesses /grade page
    ↓
System fetches submissions needing feedback
    ↓
Tutor views student submission
    ├─ Sees exercise question
    ├─ Sees student answer
    └─ Sees machine feedback (if available)
    ↓
Tutor grades: marks correct/incorrect
    ↓
Tutor adds comment (optional)
    ↓
Tutor submits feedback
    ↓
[SERVER] addHumanFeedback method:
    ├─ Check tutor is authorized (student's tutor)
    ├─ Update SubmittedExercises with humanFeedback
    ├─ Calculate answer hash
    └─ Call addGradedExercise to cache
    ↓
[SERVER] addGradedExercise:
    ├─ Create GradedAnswers document
    ├─ Store isCorrect, comment
    ├─ Store answerHash for future matching
    └─ Upsert (no duplicates)
    ↓
Future students with identical answer:
    ├─ System finds cached grade via hash
    ├─ Auto-applies feedback
    └─ Student sees "auto-graded" feedback

```

---

## Core Algorithms

### Truth Table Evaluation Algorithm

**File:** `client/lib/ix.coffee`, lines 811-904

**Algorithm: checkAnswer(values)**

```
Input: values = array of rows, each row = [letter values...] + [formula values...]
Output: {isCorrect: boolean, message: string}

Step 1: Determine expected structure
  letters = getSentenceLetters()  # [A, B, C, ...] sorted
  sentences = getSentencesOrPremisesAndConclusion()
  expectedNofRows = 2^(letters.length)
  nofColumns = letters.length + sentences.length

Step 2: Check row count
  if values.length ≠ expectedNofRows
    return {isCorrect: false, message: "wrong number of rows"}

Step 3: Check row order
  for num from expectedNofRows-1 down to 0
    binaryStr = pad0(num.toString(2), letters.length)
    expected = [each char is "1"]
    actual = values[expectedNofRows-1-num].splice(0, letters.length)
    if expected ≠ actual
      return {isCorrect: false, message: "rows not in correct order"}

Step 4: Check truth values in each row
  for each row in values
    for each sentence in sentences
      world = {}
      for each letter, idx in letters
        world[letter] = row[idx]
      
      submittedValue = row[letters.length + sentence_idx]
      actualValue = sentence.evaluate(world)
      
      if submittedValue ≠ actualValue
        return {isCorrect: false, message: "wrong truth values"}

Step 5: Return success
  return {isCorrect: true, message: ""}
```

**Key Properties:**
- Validates structural correctness (count, order) before semantic correctness
- All values must match computed values exactly
- Handles contingency (mix of true/false) naturally

### Proof Verification Algorithm

**External Library:** Proof engine (not shown in source)

**High-level Flow:**

```
Input: proofText = natural deduction proof as formatted string
Output: {isCorrect: boolean, errorMessages: string}

Step 1: Parse proof text
  - Split by lines (| delimited)
  - Extract premises (before separator |---)
  - Extract proof lines (after separator)
  - Parse each line: formula + justification

Step 2: Build proof tree
  - Create nodes for each line
  - Link line references in justifications
  - Build dependency graph

Step 3: Verify each rule application
  For each proof line:
    - Identify rule used (∧Intro, ∨Elim, ∃Intro, etc.)
    - Verify line references are valid
    - Verify rule preconditions met
    - Verify conclusion matches stated formula
  
  Return errors if any rule application invalid

Step 4: Check conclusion
  - Proof's conclusion must equal exercise's conclusion
  - Cannot introduce new premises

Step 5: Return result
  if all steps valid → {isCorrect: true}
  else → {isCorrect: false, errorMessages: detailed errors}
```

### FOL Situation Evaluation Algorithm

**File:** `client/lib/ix.coffee`, lines 604-639

```
Input: data = serialized world objects
       sentence = AWFOL sentence object
Output: boolean (true/false) or undefined if not evaluable

Step 1: Extract domain
  domain = []
  for each item in data
    domain.push(index)

Step 2: Extract names
  names = {}
  for each item in data
    if item.name is non-empty
      for each name in item.name.split(/[\s,]+/)
        names[name] = item_index

Step 3: Extract unary predicates
  predicates = {}
  for each item in data
    newPredicates = getPredicatesFromSerializedObject(item)
    for each predicate in newPredicates
      predicates[predicate] = [[item_index], ...] (add to extension)

Step 4: Extract binary predicates
  for each binaryPredicate in binaryPredicates
    predicates[binaryPredicate] = []
    for each a in data
      for each b in data
        if binaryPredicate.test(a, b)
          predicates[binaryPredicate].push([a.index, b.index])

Step 5: Evaluate sentence
  situation = {domain, predicates, names}
  result = sentence.evaluate(situation)
  return result

Binary Predicate Tests:
  LeftOf(a,b) = a.x + a.width ≤ b.x
  RightOf(a,b) = a.x ≥ b.x + b.width
  Above(a,b) = a.y + a.height ≤ b.y
  Below(a,b) = a.y ≥ b.y + b.height
  Adjacent(a,b) = HorizontallyAdjacent(a,b) OR VerticallyAdjacent(a,b)
  HorizontallyAdjacent(a,b) = x-edges align AND y-ranges overlap
  VerticallyAdjacent(a,b) = y-edges align AND x-ranges overlap
  WiderThan(a,b) = a.width > b.width
  TallerThan(a,b) = a.height > b.height
  SameShape(a,b) = a.height/a.width = b.height/b.width
  LargerThan(a,b) = a.area > b.area
  SameSize(a,b) = a.area = b.area
```

### Scope Depth Calculation

**File:** `client/ex/scope_ex.coffee`, lines 40-48

```
For each sentence and selected symbol:

Step 1: Find selected element in DOM
  $el = element with class '_scopeSelected'

Step 2: Count nesting depth
  scopeDepth = $el.parents('._expressionWrap').length

Step 3: Record result
  answer.push({
    scopeDepth: scopeDepth,
    symbolNum: $el.attr('data-symbolNum')
  })

Step 4: Grade
  Expected scopeDepth = 1 (the directly nested quantifier)
  Other depths = incorrect
```

---

## Exercise Metadata & Collection Structure

### Exercise Collection

**Location:** `lib/exercise-collection.coffee`

**Structure:**

```coffeescript
@Courses = new Mongo.Collection('courses')
@ExerciseSets = new Mongo.Collection('exercise_sets')
```

### ExerciseSets Document Schema

```
{
  _id: ObjectId,
  
  # Identification
  courseName: String,        # e.g., "UK_W20_PH126"
  variant: String,           # e.g., "normal" or "fast"
  description: String,
  
  # Ownership
  owner: userId,
  created: Date,
  hidden: Boolean (optional),
  
  # Content structure
  lectures: [
    {
      type: 'lecture',
      name: String,
      slides: URL,
      handout: URL,
      units: [
        {
          type: 'unit',
          name: String,
          slides: URL,
          rawReading: [String],         # e.g., ['5.1', '6.1']
          rawExercises: [String],       # URLs or exercise IDs
          dialectName: String (optional)
        }
      ]
    }
  ]
}
```

### Exercise URL Format

**General Structure:**
```
/ex/{exerciseType}/{subtype}/{param}/{value}/{param}/{value}...
```

**Common Parameters:**

| Parameter | Values | Example |
|-----------|--------|---------|
| `qq` | Sentence list (pipe-separated) | `/ex/tt/qq/A\|B\|A and B` |
| `from` | Premises (pipe-separated) | `/ex/proof/from/A\|B/to/C` |
| `to` | Conclusion | `/ex/proof/from/A/to/B` |
| `world` | JSON serialized situation | `/ex/TorF/from/P/to/Q/world/{...}` |
| `TTrow` | Truth value assignments | `/ex/TorF/from/P/to/Q/TTrow/A:T\|B:F` |
| `noQ` | No follow-up questions | `/ex/tt/qq/A\|B/noQ/` |
| `require` | Proof requirements | `/ex/tree/require/complete/from/P/to/Q` |
| `orValid` | Alternative form of validity | `/ex/create/orValid/from/P/to/Q` |
| `orInvalid` | Alternative form of invalidity | `/ex/proof/orInvalid/from/P/to/Q` |
| `domain` | Domain specification | `/ex/trans/domain/people/names/a=Ayesha` |
| `names` | Name definitions | `/ex/trans/names/a=Ayesha\|b=Beatrice` |
| `predicates` | Predicate definitions | `/ex/trans/predicates/Happy1\|Loves2` |
| `sentence` | Sentence to translate | `/ex/trans/sentence/Ayesha is happy` |

### URL Encoding/Decoding

**Location:** `client/lib/ix.coffee`, lines 104-108

```coffeescript
ix.convertToExerciseId = (exerciseLink) ->
  # Remove trailing slash
  exerciseLink = exerciseLink.replace /\/?$/, ''
  # Encode each part separately
  return (encodeURIComponent(decodeURIComponent(i)) for i in exerciseLink.split('/')).join('/')
```

**Purpose:**
- Handles special characters in URLs
- Prevents double-encoding issues
- Allows for parameter values with pipes, spaces, etc.

**Example Encoding:**
```
Input:  /ex/trans/domain/people/sentence/Ayesha is faster
Output: /ex/trans/domain/people/sentence/Ayesha%20is%20faster
```

### Parameter Extraction Functions

**From URL Parameters:**
```coffeescript
ix.getSentencesFromParam()      # /qq/... or _sentences param
ix.getPremisesFromParams()      # /from/... 
ix.getConclusionFromParams()    # /to/...
ix.getTTrowFromParam()          # /TTrow/...
ix.getWorldFromParam()          # /world/...
ix.getSentenceFromParam()       # /sentence/...
ix.getQuestion()                # /q/... question text
```

**Fallback Strategy:**
1. First check URL route parameters (FlowRouter)
2. If not found, check exerciseId field of data context
3. Parse exerciseId as encoded path
4. Decode and extract parameters

---

## Human Grading Workflow

### Tutor Interface

**Retrieving Exercises for Grading:**

```coffeescript
# Method: getExercisesToGrade
# Location: love-logic.coffee, lines 384-418

getExercisesToGrade : (limitToSubscribersToThisExerciseSet) ->
  # Get tutor's email
  tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  
  # Get all tutee IDs
  tuteeIds = wy.getTuteeIds(tutor_email)
  
  # Optionally limit to specific exercise set subscribers
  if limitToSubscribersToThisExerciseSet?
    exerciseSetId = ExerciseSets.findOne({
      courseName: limitToSubscribersToThisExerciseSet.courseName
      variant: limitToSubscribersToThisExerciseSet.variant
    })._id
    
    # Get only tutees subscribed to this set
    subscribedTutees = Subscriptions.find({
      owner: {$in: tuteeIds}
      exerciseSetId: exerciseSetId
    }).fetch()
    tuteeIds = (x.owner for x in subscribedTutees)
  
  # Find submissions needing feedback
  pipeline = []
  
  # Build match stage: tutee submissions with missing feedback
  needsFeedback = {
    $or: [
      # Correctness not yet determined
      {
        $and: [
          {"humanFeedback.isCorrect": {$exists: false}}
          {"machineFeedback.isCorrect": {$exists: false}}
        ]
      }
      # Machine marked false, needs human comment
      {
        $and: [
          {"machineFeedback.isCorrect": {$ne: true}}
          {"humanFeedback": {$exists: false}}
        ]
      }
    ]
  }
  
  pipeline.push({$match: {
    $and: [
      {owner: {$in: tuteeIds}}
      needsFeedback
    ]
  }})
  
  # Project and group by exercise
  pipeline.push({$project: {exerciseId: 1}})
  pipeline.push({$group: {_id: "$exerciseId"}})
  pipeline.push({$project: {exerciseId: "$_id", _id: 0}})
  
  result = SubmittedExercises.aggregate(pipeline)
  return result
```

**Grading Criteria:**
1. **Machine grading unavailable:** If both humanFeedback.isCorrect and machineFeedback.isCorrect don't exist
2. **Machine feedback exists but negative:** If machineFeedback.isCorrect ≠ true and no human feedback yet
3. **Tutor relationship:** Only exercises from student's assigned tutees
4. **Subscription filtering:** Optionally limited to specific exercise sets

### Adding Human Feedback

```coffeescript
# Method: addHumanFeedback
# Location: love-logic.coffee, lines 268-285

addHumanFeedback : (submission, humanFeedback) ->
  # Validate authorization
  if not Meteor.userId() 
    throw new Meteor.Error "not-authorized"
  
  # Check ownership hasn't changed
  oldOwner = SubmittedExercises.findOne({_id:submission._id})?.owner
  if oldOwner isnt submission.owner
    throw new Meteor.Error "Owner may not be changed"
  
  # Check grader is student's tutor (server-side only)
  if Meteor.isServer
    tutorEmail = Meteor.users.findOne(submission.owner)?.profile?.seminar_tutor
    if not tutorEmail
      throw new Meteor.Error "Student has no tutor assigned"
    
    userEmails = (x.address for x in Meteor.user().emails)
    if not (tutorEmail in userEmails)
      throw new Meteor.Error "You are not this student's tutor"
  
  # Add student notification flags
  humanFeedback.studentSeen = false
  
  # Update submission with feedback
  SubmittedExercises.update(submission, {
    $set: {humanFeedback: humanFeedback}
  })
  
  # NOTE: Client should also call addGradedExercise to cache result
```

### Feedback Display to Student

**Status Indicators:**
- **No feedback:** Exercise shows as "pending"
- **Machine feedback only:** Shows as "auto-graded" with feedback
- **Human feedback new:** Student receives notification
- **Human feedback viewed:** Marked as seen

**Methods for Student Feedback Interaction:**

```coffeescript
studentSeenFeedback : (exercise) ->
  userId = Meteor.user()._id
  if not userId or exercise.owner isnt userId
    throw new Meteor.Error "not-authorized"
  
  SubmittedExercises.update(exercise, {
    $set: {
      'humanFeedback.studentSeen': true
      'humanFeedback.studentEverSeen': true
    }
  })
```

---

## Implementation Notes

### Key Design Decisions

1. **Client-Side Machine Grading**
   - Faster feedback to students
   - Reduces server load
   - Enables offline capability (with Meteor Ground)
   - Validates answer structure before submission

2. **Hash-Based Answer Deduplication**
   - Fast lookup in GradedAnswers
   - Handles minor text variations
   - Exercise-specific (prevents false matches)
   - PNF equivalence for FOL expressions

3. **Findandmodify for Upsert**
   - Prevents duplicate submissions
   - Atomic operation (no race conditions)
   - Preserves human feedback (doesn't override)

4. **Dialect Tracking**
   - Stores dialect info with answer
   - Enables correct re-parsing of stored answers
   - Supports multiple logic systems
   - Separate from hash (doesn't affect matching)

5. **Situation Representation**
   - Two forms: visual (possible world) and mathematical (counterexample)
   - Both map to same FOL evaluation
   - Visual form for intuitive UI
   - Mathematical form for precise logic

### Security Considerations

1. **Authentication:**
   - All server methods check `Meteor.user()`
   - All mutations restricted to authenticated users

2. **Authorization:**
   - Students can only submit their own answers
   - Tutors can only grade their own students
   - Methods validate ownership before operation

3. **Data Validation:**
   - Client-side validation for UX
   - Server-side validation for security
   - No client simulation for sensitive operations

4. **Answer Integrity:**
   - Human feedback cannot be overridden by resubmission
   - Timestamps track grading history
   - Grader ID recorded for accountability

### Performance Optimizations

1. **Caching Strategy:**
   - Reduces database queries for frequently answered questions
   - Hash-based lookup is O(1) with indexed collection
   - PNF equivalence checks expensive but infrequent

2. **Batch Operations:**
   - Aggregation pipeline for "exercises to grade"
   - Projects and groups to avoid returning full documents

3. **Client-Side Processing:**
   - All answer formatting done locally
   - Dialect management in memory
   - Session storage for work-in-progress

---

## Glossary

| Term | Definition |
|------|-----------|
| **AWFOL** | Automated World-based First-Order Logic - the logic system used |
| **PNF** | Prenex Normal Form - standardized representation of FOL formulas |
| **Counterexample** | A situation where premises are true but conclusion is false |
| **Dialect** | Variant of logic system (e.g., LPL, Standard FOL) |
| **Situation** | A possible world - assignment of truth values and extensions |
| **Tableau** | Analytic tree proof - systematic testing for logical properties |
| **Entailment** | Logical consequence - if premises true, conclusion must be true |
| **Equivalence** | Two formulas true in exactly same situations |
| **Free Variable** | Variable not bound by any quantifier |
| **Extension** | Set of objects satisfying a predicate |

---

## Appendix: Relevant Source Files

**Main Files:**
- `/love-logic.coffee` - Core Meteor methods and collections
- `lib/exercise-collection.coffee` - Exercise metadata and structure
- `client/lib/ix.coffee` - Core client-side utilities

**Exercise Types (client/ex/):**
- `tt_ex.coffee` - Truth table exercises
- `proof_ex.coffee` - Proof exercises
- `trans_ex.coffee` - Translation exercises
- `create_ex.coffee` - Create exercises
- `counter_ex.coffee` - Counterexample exercises
- `TorF_ex.coffee` - True/False exercises
- `scope_ex.coffee` - Scope exercises
- `tree_ex.coffee` - Tree exercises
- `q_ex.coffee` - Question exercises

**Libraries (client/lib/):**
- `awfol/awfol.bundle.js` - First-order logic library
- `truth_table/truth_table.coffee` - Truth table UI and validation
- `possible_world/possible_world.coffee` - World visualization and evaluation
- `routes.coffee` - URL routing and parameter extraction

---

**Document End**

---

*This document is the intellectual property of love-logic-server. The grading algorithms and logic systems described herein are proprietary innovations that enable automated assessment of logical reasoning.*

