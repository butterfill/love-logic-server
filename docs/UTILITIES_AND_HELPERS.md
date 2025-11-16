# Love Logic Server - Utilities and Helpers Documentation

This document provides comprehensive documentation of all utility functions, helper libraries, and shared code in the love-logic-server project.

---

## Table of Contents

1. [Client-Side Utilities (ix.coffee)](#client-side-utilities-ixcoffee)
2. [Shared Utilities (wy.coffee)](#shared-utilities-wycoffee)
3. [Third-Party Libraries](#third-party-libraries)
4. [Logic Engine Components](#logic-engine-components)
5. [URL Encoding and Exercise Parameters](#url-encoding-and-exercise-parameters)
6. [Common Patterns and Functions](#common-patterns-and-functions)
7. [Component-Specific Utilities](#component-specific-utilities)

---

## Client-Side Utilities (ix.coffee)

The `client/lib/ix.coffee` file is a comprehensive collection of helper functions used across various templates and event handlers. All functions run on the **client only**.

### User Management Functions

#### `ix.getUserId()`
- **Purpose**: Returns the `_id` of the current user
- **Parameters**: None
- **Returns**: `String` - User ID, or `undefined` if not logged in
- **Behavior**: 
  - First checks for `user` query parameter via FlowRouter
  - Falls back to `Meteor.user()._id` if available
  - Returns `undefined` if no user is found
- **Usage**: Used throughout the app to identify the current user for data lookups and permission checks

#### `ix.getUserEmail()`
- **Purpose**: Returns the email address of the current user
- **Parameters**: None
- **Returns**: `String` - Email address, or `undefined` if not available
- **Behavior**: Safely accesses nested `Meteor.user().emails[0].address`
- **Usage**: Used for displaying user information and identifying tutors

#### `ix.isInstructorOrTutor()`
- **Purpose**: Checks if the current user is an instructor or tutor
- **Parameters**: None
- **Returns**: `Boolean` - `true` if user has either `instructor` or `seminar_tutor` profile flag
- **Usage**: Used to gate UI elements and features for instructors/tutors

#### `ix.userIsTutor()`
- **Purpose**: Checks if the current user is specifically a seminar tutor
- **Parameters**: None
- **Returns**: `Boolean` - `true` if `Meteor.user().profile.is_seminar_tutor` is set
- **Usage**: Used for tutor-specific features

#### `ix.userIsInstructor()`
- **Purpose**: Checks if the current user is an instructor
- **Parameters**: None
- **Returns**: `Boolean` - `true` if `Meteor.user().profile.is_instructor` is set
- **Usage**: Used for instructor-only features

---

### URL and Navigation Functions

#### `ix.url()`
- **Purpose**: Returns the current URL without the query string
- **Parameters**: None
- **Returns**: `String` - Decoded URL path (e.g., `/ex/proof/from/A/to/B`), or `undefined`
- **Behavior**: 
  - Gets current path from FlowRouter
  - Strips query parameters with `.split('?')[0]`
  - Decodes with `decodeURIComponent()`
  - Note: Can be made reactive by calling `FlowRouter.watchPathChange()`
- **Usage**: Used to determine current page location

#### `ix.extendUrl(extra)`
- **Purpose**: Adds additional path segments to the current URL (e.g., '/grade')
- **Parameters**: `extra` (String) - Additional path to append
- **Returns**: `String` - Extended URL with preserved query string
- **Behavior**: Handles special encoding for exercise URLs
- **Example**: `ix.extendUrl('/grade')` on `/ex/proof/from/A/to/B?user=123` returns `/ex/proof/from/A/to/B/grade?user=123`

#### `ix.contractUrl(toRemove)`
- **Purpose**: Removes a path segment from the end of the current URL
- **Parameters**: `toRemove` (String) - Path segment to remove (e.g., '/grade')
- **Returns**: `String` - Contracted URL with preserved query string
- **Behavior**: Uses regex to remove the specified suffix

#### `ix.queryString()`
- **Purpose**: Extracts just the query string portion of the current URL
- **Parameters**: None
- **Returns**: `String` - Query string (e.g., `user=123&variant=fast`), empty string if no query
- **Behavior**: Splits on `?` and returns everything after it
- **Note**: Can be made reactive by calling `FlowRouter.watchPathChange()`

#### `ix.isBrowserCompatible()`
- **Purpose**: Checks if the browser supports required CSS features (flexbox and blend modes)
- **Parameters**: None
- **Returns**: `Boolean` - `true` if browser has flexWrap and backgroundBlendMode support
- **Behavior**: Creates a test element and checks its style properties
- **Usage**: Used to prevent access from very old browsers

#### `ix.checkBrowserCompatible()`
- **Purpose**: Checks browser compatibility and redirects if incompatible (unless user dismissed warning)
- **Parameters**: None
- **Returns**: None (redirects on failure)
- **Behavior**: 
  - Checks `Session.get()` for dismissal flag per user
  - Redirects to `/oldBrowserSorry` if incompatible
- **Usage**: Called during app initialization

---

### Exercise-Related Functions

#### `ix.convertToExerciseId(exerciseLink)`
- **Purpose**: Converts a human-readable exercise URL to a properly encoded exercise ID
- **Parameters**: `exerciseLink` (String) - Exercise path (e.g., `/ex/proof/from/A or B/to/C`)
- **Returns**: `String` - Fully URI-encoded exercise ID
- **Behavior**: 
  - Removes trailing slashes
  - Decodes the input first (to avoid double encoding)
  - Encodes each path segment individually
  - Rejoins segments with `/`
- **Example**: `/ex/proof/from/A or B/to/C` becomes `/ex/proof/from/A%20or%20B/to/C`
- **Usage**: Used internally when storing or comparing exercise IDs

#### `ix.getExerciseId()`
- **Purpose**: Gets the exercise ID of the current page
- **Parameters**: None
- **Returns**: `String` - Properly encoded exercise ID, or `undefined`
- **Behavior**: 
  - Extracts from current URL
  - Removes `/grade` suffix if present (for grading pages)
  - Calls `ix.convertToExerciseId()` to normalize encoding
- **Usage**: Used throughout exercise pages to identify which exercise is being done

#### `ix.getExerciseType()`
- **Purpose**: Extracts the exercise type from the current URL
- **Parameters**: None
- **Returns**: `String` - Exercise type (e.g., 'proof', 'tt', 'trans', 'TorF')
- **Behavior**: Splits URL by `/` and returns the 3rd segment (index 2)
- **Example**: `/ex/proof/from/A/to/B` returns 'proof'

#### `ix.isSubmitted(exerciseLink?)`
- **Purpose**: Checks if the user has already submitted the specified exercise
- **Parameters**: `exerciseLink` (String, optional) - Exercise URL; uses current URL if omitted
- **Returns**: `Boolean` - `true` if exercise has been submitted
- **Behavior**: Queries `SubmittedExercises` collection with the exercise ID
- **Usage**: Used to show/hide resubmission UI

#### `ix.getGradeURL(exerciseId)`
- **Purpose**: Constructs the grading URL for an exercise
- **Parameters**: `exerciseId` (String) - The exercise ID
- **Returns**: `String` - Grade URL with `/grade` appended
- **Usage**: Used to generate links to grading pages

---

### Exercise Set Functions

#### `ix.getExerciseSet(options?)`
- **Purpose**: Retrieves the current exercise set document
- **Parameters**: `options` (Object, optional) - MongoDB query options
- **Returns**: `Object` - Exercise set document, or `undefined`
- **Behavior**: 
  - Makes path changes reactive with `FlowRouter.watchPathChange()`
  - Queries `ExerciseSets` collection by `courseName` and `variant`
  - Gets these from FlowRouter params or query params
- **Usage**: Used to access exercise metadata and course information

#### `ix.isExerciseSubtype(type, submittedAnswer?)`
- **Purpose**: Checks if an exercise is of a specific subtype
- **Parameters**: 
  - `type` (String) - Subtype to check (e.g., 'orValid')
  - `submittedAnswer` (Object, optional) - Data context with `exerciseId`; uses URL if omitted
- **Returns**: `Boolean` - `true` if the exercise matches the subtype
- **Behavior**: Compares the 4th path segment (index 3) of the URL
- **Example**: `/ex/proof/orValid/from/A/to/B` returns `true` for type='orValid'

---

### Dialect Management Functions

#### `ix.setDialectFromExerciseSet()`
- **Purpose**: Sets the FOL dialect based on the current exercise set
- **Parameters**: None
- **Returns**: None
- **Behavior**: 
  - Tries to get dialect from current unit first
  - Falls back to exercise set dialect
  - Calls `fol.setDialect()` with the dialect name
- **Usage**: Called when starting an exercise to ensure correct parser

#### `ix.setDialectFromCurrentAnswer()`
- **Purpose**: Sets the FOL dialect based on the user's saved answer
- **Parameters**: None
- **Returns**: None
- **Behavior**: 
  - Extracts `dialectName` and `dialectVersion` from saved answer
  - Calls `fol.setDialect()`
- **Usage**: Used when loading a saved answer to recreate the parsing context

#### `ix.setDialectFromThisAnswer(answer)`
- **Purpose**: Sets the FOL dialect based on a specific answer object
- **Parameters**: `answer` (Object, optional) - Answer with `content.dialectName` and `content.dialectVersion`
- **Returns**: None
- **Behavior**: 
  - Extracts dialect info from answer
  - Falls back to 'lpl' dialect if not specified
  - Calls `fol.setDialect()`
- **Note**: Designed to safely handle `undefined` answers

#### `ix.addDialectInfoToAnswerDoc(answerDoc)`
- **Purpose**: Adds dialect metadata to an answer document before submission
- **Parameters**: `answerDoc` (Object) - Answer document to modify
- **Returns**: None (modifies object in place)
- **Behavior**: 
  - Gets current dialect name and version from `fol.getCurrentDialectNameAndVersion()`
  - Adds `dialectName` and `dialectVersion` to `answerDoc.answer.content`
- **Usage**: Called before submitting exercises to record which dialect was used

---

### Hashing and Grading Functions

#### `ix.hash(text)`
- **Purpose**: Computes a fast hash of text for comparison and caching
- **Parameters**: `text` (String) - Text to hash
- **Returns**: `String` - Hash in base-36 format
- **Implementation**: Uses XXHash algorithm (xxhash.lmd.js library)
- **Behavior**: `return XXH(text, 0xFFFA).toString(36)`
- **Usage**: Fast hashing for answer caching without collision risk

#### `ix.hashAnswer(answerDoc)`
- **Purpose**: Computes a hash of an answer for comparison against graded answers
- **Parameters**: `answerDoc` (Object) - Answer document with `answer.content`
- **Returns**: `String` - Hash combining answer content and exercise ID
- **Behavior**: 
  - For string answers: Converts to lowercase, removes extra whitespace, trims
  - For FOL expressions: Preserves case (important for awFOL), normalizes whitespace
  - Appends the exercise ID to prevent collisions across exercises
  - Calls `ix.hash()` on the normalized content
- **Note**: Avoids using toLowerCase for awFOL since case matters for distinguishing predicates
- **Usage**: Used to quickly look up pre-graded answers

#### `ix.gradeUsingGradedAnswers(answerDoc?, options?)`
- **Purpose**: Grades an answer by comparing against pre-graded correct answers
- **Parameters**: 
  - `answerDoc` (Object, optional) - Answer to grade; uses current answer if omitted
  - `options` (Object, optional) - Options like `{uniqueAnswer: true}`
- **Returns**: `Object` - Grade result with `{isCorrect, comment}`; `undefined` if no graded answers exist
- **Behavior**: 
  1. Hashes the answer
  2. Looks up matching graded answers in the database
  3. If exact hash match found: uses stored grade
  4. If no match but answer has PNF form: grades by PNF equivalence
  5. If no match and no PNF: returns `undefined` (no automatic grading available)
  6. If `options.uniqueAnswer=true`: returns `false` if answer differs from unique correct answer
  7. Combines comments from multiple matching grades
  8. Detects conflicts if multiple grades disagree
- **Note**: Dialect differences are ignored (added after hashing)
- **Usage**: Main auto-grading mechanism for fast feedback

---

### Answer Storage Functions

#### `ix.getSessionKeyForUserExercise()`
- **Purpose**: Generates the Session key for storing an exercise's work-in-progress
- **Parameters**: None
- **Returns**: `String` - Session key (format: `{userId}/{exerciseId}`)
- **Usage**: Used internally by answer storage functions

#### `ix.getAnswer()`
- **Purpose**: Retrieves the user's current work-in-progress for the exercise
- **Parameters**: None
- **Returns**: `Object` - Answer object from Session, or `undefined`
- **Behavior**: Retrieves value from Session using the exercise's session key
- **Structure**: Answer object has keys for different answer types: `{sentence, proof, tt, world, TorF, ...}`

#### `ix.setAnswer(answer)`
- **Purpose**: Saves the entire work-in-progress answer
- **Parameters**: `answer` (Object) - Complete answer object
- **Returns**: None
- **Behavior**: Stores to Session with `setPersistent()` for cross-session persistence
- **Usage**: Used when completely replacing the answer

#### `ix.setAnswerKey(newValue, key?)`
- **Purpose**: Updates a specific component of the answer (e.g., just the sentence)
- **Parameters**: 
  - `newValue` (Any) - New value for this component
  - `key` (String, optional) - Answer key to update; defaults to exercise type if omitted
- **Returns**: None
- **Behavior**: 
  - Retrieves current answer
  - Updates the specified key
  - Saves back with `ix.setAnswer()`
- **Example**: `ix.setAnswerKey('P(a)', 'sentence')` updates answer.sentence

#### `ix.storeLastExercise()`
- **Purpose**: Records the current exercise URL in Session for resume functionality
- **Parameters**: None
- **Returns**: None
- **Behavior**: Stores full current path to `Session` with key `{userId}/lastExercise`
- **Usage**: Used to remember where user was last working

---

### Parameter Extraction Functions

These functions extract exercise parameters from the URL and convert them to awFOL objects.

#### `ix.getQuestion(self?)`
- **Purpose**: Extracts the question text from the URL
- **Parameters**: `self` (Object, optional) - Data context with `exerciseId`; uses URL param if omitted
- **Returns**: `String` - Question text
- **Behavior**: 
  - Tries to get from FlowRouter param `_question` first
  - Falls back to splitting `exerciseId` and finding the 'question' segment
- **Example**: `/ex/q/Define_counterexample` extracts "Define_counterexample"

#### `ix.getPremisesFromParams(self?)`
- **Purpose**: Extracts premises from the URL and parses them to awFOL
- **Parameters**: `self` (Object, optional) - Data context with `exerciseId`
- **Returns**: `Array` - Array of awFOL expression objects; empty array if no premises
- **Behavior**: 
  1. Gets `_premises` from FlowRouter param or extracts from exerciseId after 'from'
  2. Returns `[]` if premises are ` ` (space) or `-` (dash)
  3. Splits on `|` to get individual premise strings
  4. Attempts to parse each with `fol.parseUsingSystemParser()`
  5. On parse error: treats as English sentences and fixes them
  6. Filters out any premises that are literally `true`
- **Example**: `from/A or B|C and D` returns two parsed awFOL objects
- **Encoding**: Uses `decodeURIComponent()` to handle URL-encoded logic symbols

#### `ix.getConclusionFromParams(self?)`
- **Purpose**: Extracts the conclusion from the URL and parses it to awFOL
- **Parameters**: `self` (Object, optional) - Data context with `exerciseId`
- **Returns**: `Object` - Single awFOL expression object, or `undefined`
- **Behavior**: 
  1. Gets `_conclusion` from FlowRouter param or extracts from exerciseId after 'to'
  2. Parses with `fol.parseUsingSystemParser()`
  3. On parse error: treats as English sentence and fixes
  4. Returns `undefined` if no conclusion specified
- **Example**: `to/A and (B or C)` returns parsed awFOL object

#### `ix.getSentenceFromParam(self?)`
- **Purpose**: Extracts a single sentence from the URL
- **Parameters**: `self` (Object, optional) - Data context with `exerciseId`
- **Returns**: `String` - Sentence text (URL decoded), or `undefined`
- **Behavior**: 
  1. Gets from FlowRouter param `_sentence` first
  2. Falls back to extracting from exerciseId after 'sentence' segment
- **Example**: `sentence/Happy(a)` returns "Happy(a)"

#### `ix.getSentencesFromParam(self?)`
- **Purpose**: Extracts multiple sentences from the URL and parses them to awFOL
- **Parameters**: `self` (Object, optional) - Data context with `exerciseId`
- **Returns**: `Array` - Array of awFOL objects, or `undefined` if no sentences
- **Behavior**: 
  1. Tries FlowRouter param `_sentences` first
  2. Falls back to extracting from exerciseId after 'qq' segment
  3. Splits on `|` to get individual sentences
  4. Parses each with helper function `_sentencesToAwFOL()`
  5. Handles parse errors by treating as English
- **Example**: `qq/P(a)|Q(b)|R(a,b)` returns array of three awFOL objects

#### `ix.getSentencesOrPremisesAndConclusion(self?)`
- **Purpose**: Unified function to extract sentences or (premises+conclusion) from URL
- **Parameters**: `self` (Object, optional) - Data context with `exerciseId`
- **Returns**: `Array` - Array of awFOL objects
- **Behavior**: 
  1. Tries to get sentences first
  2. If no sentences: tries to get premises and conclusion
  3. Combines premises and conclusion into single array
  4. Returns `undefined` if neither approach yields results

#### `ix.getProofFromParams()`
- **Purpose**: Generates a template proof skeleton for the exercise
- **Parameters**: None
- **Returns**: `String` - Proof text with premises and conclusion, ready for user to fill in
- **Format**: 
  ```
  | premise1
  | premise2
  |---
  | [blank lines for user work]
  | conclusion
  ```
- **Behavior**: 
  - Gets premises and conclusion from params
  - Joins multiple premises with `\n| `
  - Converts awFOL to symbol notation with `toString({replaceSymbols:true})`
  - Returns `undefined` if no conclusion

#### `ix.getTTrowFromParam()`
- **Purpose**: Extracts a truth table row assignment from the URL
- **Parameters**: None
- **Returns**: `Object` - Object mapping variable names to true/false values (e.g., `{A: "T", B: "F"}`)
- **Behavior**: 
  1. Gets `_TTrow` FlowRouter param
  2. Decodes and splits on `|`
  3. For each assignment, splits on `:` to get key:value pair
- **Example**: `TTrow/A:T|B:F` returns `{A: "T", B: "F"}`

#### `ix.getWorldFromParam()`
- **Purpose**: Extracts and deserializes a possible world from the URL
- **Parameters**: None
- **Returns**: `Object` - Deserialized possible world object, or `undefined`
- **Behavior**: 
  1. Gets `_world` FlowRouter param
  2. Decodes from URL encoding
  3. Parses as JSON
- **Structure**: World is an array of objects with properties: `{x, y, width, height, name, colour, face, ...}`

---

### Proof Checking Functions

#### `ix.checkPremisesAndConclusionOfProof(theProof)`
- **Purpose**: Validates that a proof's premises and conclusion match the exercise requirements
- **Parameters**: `theProof` (Object) - Parsed proof object from proof.parse()
- **Returns**: `true` if valid, or `String` error message if invalid
- **Checks**: 
  1. Conclusion matches the required conclusion
  2. Premises only use allowed premises (no extra premises added)
- **Usage**: Called after proof is verified to ensure it solves the right problem

#### `ix.checkPremisesOfProofAreThePremisesAllowed(theProof, thePremises)`
- **Purpose**: Checks that proof doesn't use premises other than those provided
- **Parameters**: 
  - `theProof` (Object) - Parsed proof
  - `thePremises` (Array) - Array of allowed premise awFOL objects
- **Returns**: `true` if valid, or `String` error message if invalid
- **Behavior**: 
  1. Extracts premises used in proof
  2. Compares against allowed premises using string representation
  3. Detects any extra premises that weren't allowed
  4. Note: User doesn't have to use all allowed premises

---

### Helper Functions for String Sentences

#### `_fixEnglishSentence(sentence)`
- **Purpose**: Normalizes English text to proper sentence format
- **Parameters**: `sentence` (String) - English sentence text
- **Returns**: `String` - Fixed sentence
- **Behavior**: 
  - Adds period if not present
  - Capitalizes first letter
- **Usage**: Used internally when parsing fails and input is treated as English

#### `_sentencesToAwFOL(sentences)`
- **Purpose**: Converts an array of sentence strings to awFOL objects
- **Parameters**: `sentences` (Array) - Array of sentence strings
- **Returns**: `Array` - Array of awFOL objects or fixed English sentences
- **Behavior**: 
  1. For each sentence, tries to parse as awFOL
  2. On parse error: treats as English sentence and fixes
- **Usage**: Internal helper for parameter extraction

---

### Truth Table Utilities

`ix.truthTable` is an object containing utility functions for truth table exercises.

#### `ix.truthTable.checkAnswer(values?)`
- **Purpose**: Validates a complete truth table answer
- **Parameters**: `values` (Array, optional) - Array of rows; gets from table if omitted
- **Returns**: `Object` - `{isCorrect: boolean, message: string}`
- **Checks**:
  1. Correct number of rows (2^n where n = number of sentence letters)
  2. Correct row order (binary counting order from all-false to all-true)
  3. Correct truth values for all cells (using awFOL evaluation)
- **Behavior**: Returns early with error if rows are wrong, then checks each cell
- **Usage**: Main validation for truth table exercises

#### `ix.truthTable.checkAnswerCorrectNofRows(values)`
- **Purpose**: Checks only the number of rows in the truth table
- **Parameters**: `values` (Array) - Array of row arrays
- **Returns**: `Object` - `{isCorrect: boolean, message: string}`
- **Usage**: Called as part of `checkAnswer()`

#### `ix.truthTable.checkAnswerCorrectRowOrder(values)`
- **Purpose**: Checks that rows are in the correct binary order
- **Parameters**: `values` (Array) - Array of row arrays
- **Returns**: `Boolean` - `true` if correct order
- **Behavior**: 
  - Expects rows in order from all-false (0000...) to all-true (1111...)
  - Each row is expected to be binary values (true/false) followed by computed columns

#### `ix.truthTable.getReferenceRowValues()`
- **Purpose**: Generates the reference (correct) row assignments for the current exercise
- **Parameters**: None
- **Returns**: `Array` - Array of rows with correct binary assignments
- **Usage**: Used to auto-fill the first columns of the truth table

#### `ix.truthTable.getSentenceLetters(self?)`
- **Purpose**: Extracts all sentence letters (propositional variables) from the exercise
- **Parameters**: `self` (Object, optional) - Data context
- **Returns**: `Array` - Sorted array of unique sentence letters (e.g., `['A', 'B', 'P']`)
- **Behavior**: 
  1. Gets sentences/premises/conclusion from params
  2. Calls `getSentenceLetters()` on each awFOL object
  3. Flattens and deduplicates with `_.uniq()`
  4. Sorts alphabetically
- **Usage**: Used to determine table width

#### `ix.truthTable.getValuesFromTable()`
- **Purpose**: Reads the current truth table DOM and extracts values
- **Parameters**: None
- **Returns**: `Array` - Array of row arrays containing booleans or nulls
- **Behavior**: 
  1. Iterates through all `<tr>` elements in `.truthtable`
  2. For each cell `<input>`, reads the value
  3. Converts 'T', 't', '1' to `true`
  4. Converts 'F', 'f', '0' to `false`
  5. Converts anything else to `null`
- **Usage**: Gets user's input for validation

#### `ix.truthTable.pad0(n, len)`
- **Purpose**: Left-pads a binary string with zeros
- **Parameters**: 
  - `n` (String) - Binary string (e.g., "101")
  - `len` (Number) - Target length
- **Returns**: `String` - Padded string (e.g., "0101" for len=4)
- **Usage**: Helper for generating correct row values

---

### Possible World Utilities

`ix.possibleWorld` is an object containing utilities for creating and evaluating possible worlds.

#### `ix.possibleWorld.checkSentencesTrue($grid, giveFeedback?)`
- **Purpose**: Evaluates all exercise sentences in a possible world and provides feedback
- **Parameters**: 
  - `$grid` (jQuery) - GridStack element containing the possible world
  - `giveFeedback` (Function, optional) - Callback to display feedback
- **Returns**: `Boolean` - `true` if all sentences evaluate to true
- **Behavior**: 
  1. Serializes the grid to a possible world structure
  2. For each sentence from params, evaluates it in the world
  3. Calls feedback for any evaluation errors
  4. Updates DOM elements with truth values ('T' or 'F')
  5. Returns whether all sentences are true
- **Usage**: Real-time feedback for possible world exercises

#### `ix.possibleWorld.checkSentencesAreCounterexample($grid)`
- **Purpose**: Checks if a possible world is a valid counterexample to an argument
- **Parameters**: `$grid` (jQuery) - GridStack element with the world
- **Returns**: `Boolean` - `true` if premises are all true and conclusion is false
- **Behavior**: 
  1. Serializes world
  2. Evaluates all premises: must all be true
  3. Evaluates conclusion: must be false
  4. Returns true only if all conditions met
- **Usage**: Validation for counterexample exercises

#### `ix.possibleWorld.getSituationFromSerializedWord(data)`
- **Purpose**: Converts serialized possible world data to an awFOL situation object
- **Parameters**: `data` (Array) - Array of object items from serialized world
- **Returns**: `Object` - Situation object: `{domain, predicates, names}`
- **Behavior**: 
  1. Creates domain: array of indices (0, 1, 2, ...)
  2. Extracts monadic predicates from each object's face and color
  3. Extracts names from object.name (handles comma/space-separated lists)
  4. Handles all binary predicates (LeftOf, RightOf, Above, Below, Adjacent, etc.)
  5. Returns structure compatible with awFOL's `.evaluate()` method
- **Situation Structure**: 
  ```javascript
  {
    domain: [0, 1, 2, ...],
    predicates: {
      Happy: [[0], [2]],      // unary: indices that have property
      LeftOf: [[0,1], [1,2]], // binary: pairs of indices
      ...
    },
    names: {a: 0, b: 1, ...}  // name assignments
  }
  ```
- **Usage**: Internal helper for evaluation

#### `ix.possibleWorld.getPredicatesFromSerializedObject(object)`
- **Purpose**: Extracts monadic predicates from a single possible world object
- **Parameters**: `object` (Object) - Serialized world object with face, color, height, width
- **Returns**: `Array` - Array of predicate names (e.g., `['Happy', 'Red', 'Tall']`)
- **Behavior**: 
  1. Extracts mouth symbol and looks up predicates
  2. Extracts eye symbol and looks up predicates
  3. Extracts nose symbol and looks up predicates
  4. Looks up color predicate (capitalizes first letter)
  5. Determines Tall/Short from height
  6. Determines Wide/Narrow from width
  7. Flattens and filters out undefined values
- **Predicates Defined**: Happy, Smiling, Neutral, Sad, Laughing, Surprised, Angry, Frowning, Winking, Crying, Confused, HasLargeNose, Red, Blue, Green, etc.

#### `ix.possibleWorld.getNameFromDiv(el)`
- **Purpose**: Extracts the name assigned to an object
- **Parameters**: `el` (DOM element) - Grid stack item
- **Returns**: `String` - Name from input field, or empty string

#### `ix.possibleWorld.getColourFromDiv(el)`
- **Purpose**: Determines the color of an object from its CSS classes
- **Parameters**: `el` (DOM element) - Grid stack item
- **Returns**: `String` - Color name (e.g., 'red', 'blue', 'white'), or 'white' as default
- **Behavior**: Checks grid-stack-item-content classes against ELEMENT_COLOURS list

#### `ix.possibleWorld.serialize($grid)`
- **Purpose**: Serializes a GridStack-based possible world to JavaScript objects
- **Parameters**: `$grid` (jQuery) - GridStack element
- **Returns**: `Array` - Array of serialized objects: `{x, y, width, height, name, colour, face}`
- **Behavior**: 
  1. Maps over visible grid items
  2. Extracts node position/size data from GridStack
  3. Gets name, color, and face symbols
  4. Returns array of objects ready for storage or URL encoding
- **Usage**: Prepares world for saving or sending to server

#### `ix.possibleWorld.serializeAndAbbreviate($grid)`
- **Purpose**: Serializes the world and abbreviates property names for URL encoding
- **Parameters**: `$grid` (jQuery) - GridStack element
- **Returns**: `Array` - Array of abbreviated objects
- **Abbreviations**: 
  - width → w
  - height → h
  - name → n
  - colour → c
  - face → f
  - x, y stay the same
- **Purpose**: Reduces URL length when embedding worlds in exercise parameters

#### `ix.possibleWorld.abbreviate(dict)` and `ix.possibleWorld.unabbreviate(dict)`
- **Purpose**: Apply/reverse abbreviation mapping to objects
- **Parameters**: `dict` (Object or Array) - Objects to abbreviate/unabbreviate
- **Returns**: Transformed objects with abbreviated/full property names
- **Usage**: `ABBRV` and `UNABBRV` maps contain the mappings

#### Binary Predicate Testers
The `ix.possibleWorld.binaryPredicates` object contains functions for all spatial relationships:
- `LeftOf(a, b)`, `RightOf(a, b)`, `Above(a, b)`, `Below(a, b)`, `Adjacent(a, b)`
- `HorizontallyAdjacent(a, b)`, `VerticallyAdjacent(a, b)`, `NotAdjacent(a, b)`
- `WiderThan(a, b)`, `Wider(a, b)`, `NarrowerThan(a, b)`, `Narrower(a, b)`
- `TallerThan(a, b)`, `Taller(a, b)`, `ShorterThan(a, b)`, `Shorter(a, b)`
- `SameShape(a, b)`, `DifferentShape(a, b)`
- `LargerThan(a, b)`, `Larger(a, b)`, `SmallerThan(a, b)`, `Smaller(a, b)`
- `SameSize(a, b)`, `DifferentSize(a, b)`

#### Mouth, Eye, Nose Symbol Maps
- `ix.possibleWorld.mouths`: Array with symbols and associated predicates
  - `)` → Happy, Smiling
  - `|` → Neutral
  - `(` → Sad
  - `D` → Laughing, Happy
  - `()` → Surprised
  - `{}` → Angry
- `ix.possibleWorld.eyes`: Array with symbols and associated predicates
- `ix.possibleWorld.nose`: Array with symbols and associated predicates
- `ix.possibleWorld.ELEMENT_COLOURS`: Color list for objects

#### `ix.possibleWorld.getPredicate(symbol, type)`
- **Purpose**: Looks up which predicates correspond to a symbol
- **Parameters**: 
  - `symbol` (String) - Symbol to look up (e.g., ')')
  - `type` (Array) - Type array (mouths, eyes, or nose)
- **Returns**: `String` - Comma-separated predicate names, or `undefined` if not found

---

### Clipboard Utilities

`ix.clipboard` provides temporary storage for copy/paste operations.

#### `ix.clipboard.set(object, type)`
- **Purpose**: Stores an object in the clipboard
- **Parameters**: 
  - `object` (Object) - Object to store (e.g., exercise set)
  - `type` (String) - Type identifier (e.g., 'exerciseSet', 'lecture', 'unit')
- **Returns**: None
- **Behavior**: Clones and stores in Session
- **Usage**: Used for copy operations in exercise set editor

#### `ix.clipboard.get(type)`
- **Purpose**: Retrieves a stored object
- **Parameters**: `type` (String) - Type identifier
- **Returns**: `Object` - The stored object, or `undefined`
- **Usage**: Used for paste operations

---

### Exercise Submission

#### `ix.submitExercise(exercise, cb)`
- **Purpose**: Submits an exercise answer to the server
- **Parameters**: 
  - `exercise` (Object) - Answer data to submit
  - `cb` (Function) - Callback(error, result)
- **Returns**: None (uses callback)
- **Behavior**: 
  1. Adds current user agent to answer
  2. Adds dialect information via `ix.addDialectInfoToAnswerDoc()`
  3. Merges with default values (exerciseId from URL)
  4. Calls Meteor method `submitExercise` on server
- **Usage**: Called when user submits their answer

#### `ix.getExerciseContext()`
- **Purpose**: Gets metadata about the current exercise's position in the course
- **Parameters**: None
- **Returns**: `Object` with:
  - `lecture`: Current lecture object
  - `unit`: Current unit object
  - `nextExercise`: Next exercise URL, or undefined
  - `nextUnit`: Next unit object, or undefined
  - `nextLecture`: Next lecture object, or undefined
  - `exerciseSet`: The entire exercise set
- **Behavior**: 
  1. Extracts unitName and lectureName from query params
  2. Searches exercise set structure for current exercise
  3. Finds next exercise in unit, or first of next unit, or first of next lecture
  4. Returns complete navigation context
- **Usage**: Used by "next exercise" template to provide navigation

#### `ix.getReading(exerciseSet, unit)`
- **Purpose**: Formats reading assignments from a unit
- **Parameters**: 
  - `exerciseSet` (Object) - Exercise set containing textbook name
  - `unit` (Object) - Unit containing rawReading
- **Returns**: `String` - Formatted reading assignment, or `undefined`
- **Format**: "Sections §5.1, §6.1 of [textbook]; [other reading]"
- **Behavior**: 
  1. Gets textbook name from exercise set (defaults to "Language, Proof and Logic...")
  2. Parses rawReading array:
     - Numeric sections get prefixed with § and grouped
     - Other items are listed separately
  3. Combines into readable format
- **Usage**: Displays reading assignments in UI

---

### Helper Function: `radioToArray()`

#### `ix.radioToArray()`
- **Purpose**: Reads true/false radio button inputs from the DOM and converts to array
- **Parameters**: None
- **Returns**: `Array` - Array of booleans or `undefined` values
- **Behavior**: 
  1. Finds all `.trueOrFalseInputs` elements
  2. For each, checks which radio button is selected
  3. Converts selected value to boolean or `undefined`
  4. Validates that exactly one radio is selected per question
- **Conversions**: 
  - 'true', 'T', 't' → `true`
  - 'false', 'F', 'f' → `false`
  - other values → throws Meteor.Error
- **Usage**: Gets user's true/false answers from form

---

## Shared Utilities (wy.coffee)

The `lib/wy.coffee` file contains utilities that run on **both client and server**.

### `wy.getTuteeIds(tutor_email)`
- **Purpose**: Gets the list of student IDs who are tutored by a specific person
- **Parameters**: `tutor_email` (String) - Email address of the tutor
- **Returns**: `Array` - Array of user IDs (Meteor user ._id values)
- **Behavior**: 
  1. Logs error if tutor_email is falsy
  2. Queries Meteor.users collection for users with `profile.seminar_tutor` matching the email
  3. Returns array of their `_id` fields
  4. Returns empty array if no tutees found
- **Usage**: Used to restrict grading interface to a tutor's students

---

## Third-Party Libraries

### AWFOL (awfol.bundle.js)

**Purpose**: First-Order Logic parser and evaluator

**Location**: `/client/lib/awfol/awfol.bundle.js`

**Global Variable**: `fol`

**Key Methods Used**:
- `fol.setDialect(name, version)` - Sets which logic system to use
- `fol.getCurrentDialectNameAndVersion()` - Gets current dialect info
- `fol.parse(string)` - Parses a sentence/formula
- `fol.parseUsingSystemParser(string)` - Parses using current system parser
- `fol.getPredLanguageName()` - Gets name of current language

**Expression Objects** have methods:
- `.toString({replaceSymbols: boolean})` - Converts to string with symbol notation
- `.evaluate(situation)` - Evaluates in a possible world
- `.isPNFExpressionEquivalent(otherExpr)` - Checks logical equivalence
- `.getSentenceLetters()` - Extracts propositional variables
- `.walk(function)` - Traverses expression tree

**Usage**: All formula parsing and evaluation in the app

---

### CodeMirror

**Purpose**: Code editor with syntax highlighting and line numbers

**Location**: `/client/lib/codemirror/`

**Integration**: 
- `codemirror-compressed.js` - Main library
- `matchbrackets.js` - Bracket matching plugin
- `fol.mode.js` - Custom syntax highlighting for logic notation
- `meteor_component.coffee` - Meteor integration (see below)

**Key Files**:
- `Template.editSentence` - Single-line formula editor
- `Template.editProof` - Multi-line proof editor with line verification

**Features**:
- Line numbering for proofs
- Real-time syntax checking
- "Convert to symbols" button for formula transformation
- Proof line verification with color-coded feedback
- Auto-indentation

**Usage**: All formula and proof input

---

### GridStack (gridstack.js)

**Purpose**: Draggable/resizable grid layout system

**Location**: `/client/lib/gridstack/gridstack.js`

**Integration**: 
- jQuery-based drag-and-drop grid
- Requires jQuery UI (bundled in `/client/lib/jquery-ui-for-gridstack/`)
- Touch support via `jquery.ui.touch-punch.js`

**Usage in App**: 
- Possible world editor uses GridStack for placing objects
- Options configured with cell_height, width, vertical_margin, animate flags
- Events on 'change' trigger world serialization and sentence evaluation

**Key Methods** (from app):
- `$grid.gridstack(options)` - Initialize grid
- `theGrid.add_widget($html, x, y, width, height)` - Add object
- `theGrid.remove_widget(el)` - Remove object
- `theGrid.remove_all()` - Clear grid
- `$grid.on('change', callback)` - Listen for layout changes

**Data Structure**: Grid items have node data with properties: x, y, width, height, min_width, max_width, etc.

---

### Materialize CSS

**Purpose**: Material Design UI framework

**Files**:
- System Materialize CSS (via CDN or package)
- `/client/lib/materializecss_missing.js` - Custom extensions

**Components Used**:
- Input fields with floating labels (`.input-field`)
- Radio buttons and checkboxes (styled)
- Material icons (via Material Icons font)
- Toast notifications via `Materialize.toast()`
- Modal dialogs via `Materialize.modal()` (with custom MaterializeModal wrapper)
- Color classes for background colors (e.g., `.red.lighten-2`)
- Button styles

**Custom Extensions** (materializecss_missing.js):
- Additional styling and component enhancements
- Custom form controls

**Usage**: All UI styling and Material Design components throughout

---

### TreeViz / Treant (treant_dependencies/)

**Purpose**: Tree visualization library

**Location**: `/client/lib/treant_dependencies/`

**Dependencies**:
- `raphael.js` - Drawing library for visualization

**Usage**: Tree structure visualization (for proof trees or logic trees)

**Note**: Tree proof visualization appears to use custom implementation in AWFOL bundle

---

### TypeAhead (typeahead.bundle.js)

**Purpose**: Autocomplete suggestions

**Location**: `/client/lib/typeahead.bundle.js`

**Integration Notes**:
- Bundled with Bloodhound suggestion engine
- Used for autocomplete in form fields
- Code shows commented-out typeahead integration for truth table inputs
- Can suggest T/F/true/false values

**Current Usage**: Minimal active use (mostly disabled/commented out)

---

### Additional Libraries

#### String.prototype.endsWith (String.prototype.endsWith.js)
- **Purpose**: Polyfill for ES6 `.endsWith()` method
- **Usage**: Used in `ix.convertToExerciseId()` and elsewhere

#### MurmurHash3 (murmurhash3_gc.js)
- **Purpose**: Fast non-cryptographic hash function (reference implementation)
- **Note**: XXHash is actually used instead (xxhash.lmd.js)
- **Function**: `murmurhash3_32_gc(key, seed)`

#### XXHash (xxhash.lmd.js)
- **Purpose**: Very fast hash function for answer comparison
- **Function**: `XXH(text, seed)` - returns 32-bit integer
- **Usage**: Used by `ix.hash()` for answer caching

#### ES6 Shim (es6-shim.js)
- **Purpose**: Polyfills for ES6 features
- **Usage**: Provides modern JavaScript features on older browsers

#### jQuery UI (jquery-ui-for-gridstack/)
- **Purpose**: Draggable/resizable/sortable widgets
- **Includes**: 
  - Core widget system
  - Draggable widget (used by GridStack)
  - Resizable widget (used by GridStack)
  - Touch support via touch-punch plugin
- **Usage**: Foundation for GridStack's drag-drop functionality

---

## Logic Engine Components

### Truth Table Logic (client/lib/truth_table/)

**File**: `truth_table.coffee`

**Templates**: 
- `truth_table` - Editable truth table
- `truth_table_static` - Read-only display

**Key Functions**:
- `resetTruthTable()` - Clears table and adds empty row
- `addTrToTable($tr)` - Adds new row after specified row
- `makeTableFromValues(values)` - Populates table from data
- `getRowsFromValues(values)` - Converts data to display format
- `valueToText(v)` - Converts boolean to 'T'/'F'/'', or null to ''

**Data Structure**:
- Rows contain columns for: sentence letters (first n) then sentences (remaining)
- Each cell is a text input accepting T, F, t, f, 1, 0, or blank
- Last two columns are add/remove row buttons

**Reactivity**:
- Saves answer to Session on every change
- Auto-fills reference columns on render if answer not yet saved
- Condition: only auto-fill if more than 2 sentences or more than 5 symbols

**Integration with ix**:
- Uses `ix.getSentencesOrPremisesAndConclusion()` for sentences
- Uses `ix.truthTable.checkAnswer()` for grading
- Stores answer in `ix.getAnswer().tt`

---

### Possible World Editor (client/lib/possible_world/)

**File**: `possible_world.coffee`

**Templates**:
- `possible_world` - Interactive editor
- `possible_world_static` - Read-only display (for graded answers)
- `possible_world_from_param` - Display world from URL parameter

**Key Functions**:
- `deserializeAndRestore(data, $grid)` - Loads world from data
- `addElementToGrid(node, $grid)` - Adds one object to world
- `saveAndUpdate($grid)` - Serializes and evaluates
- `getNextSymbol(current, type)` - Cycles through symbol options
- `getRandomSymbol(type)` - Picks random symbol
- `defaultNode()` - Creates new object with random symbol, starting position

**Data Structure**:
- GridStack manages layout (position, size)
- Each node has: x, y, width, height, name, colour, face array
- Face = [eyes, nose, mouth] symbols
- 12 colors available: white, yellow, red, pink, purple, green, blue, indigo, cyan, teal, lime, orange

**Events**:
- Click mouth/eyes/nose to cycle symbols
- Blur on name input to save
- Add element button
- Delete element with trash icon (with validation that ≥1 object must exist)

**Integration with ix**:
- Uses `ix.possibleWorld.serialize()` to get current state
- Uses `ix.possibleWorld.checkSentencesTrue()` for feedback
- Uses `ix.possibleWorld.checkSentencesAreCounterexample()` for validation
- Stores answer in `ix.getAnswer().world`

---

### Formula Parsing and Evaluation

**Global Object**: `fol` (from AWFOL library)

**Key Entry Points**:
- Parse: `fol.parseUsingSystemParser(text)` or `fol.parse(text)`
- Evaluate: `parsedExpr.evaluate(situation)`
- Get sentence letters: `parsedExpr.getSentenceLetters()`
- Check equivalence: `exprA.isPNFExpressionEquivalent(exprB)`

**Situation Structure** (for evaluation):
```javascript
{
  domain: [0, 1, 2, ...],                    // indices of objects
  predicates: {
    HappyName: [[0], [2]],                   // unary predicates
    LeftOf: [[0,1], [1,2]],                  // binary predicates
    ...
  },
  names: {a: 0, b: 1, c: 2, ...}             // name assignments
}
```

**Dialectsupported**: 
- LPL (Language, Proof and Logic) - default
- Teller's system
- forallx
- The Logic Book

**Parser Variants**:
- awFOL parser - handles full first-order logic
- Various dialect-specific parsers for different notation styles

---

### Proof System

**Integration Point**: `proof` global object (from AWFOL bundle)

**Key Methods** (accessed via Template and ix functions):
- `proof.parse(proofText)` - Parses proof in Fitch format
- `theProof.verify()` - Validates entire proof
- `aLine = theProof.getLine(lineNumber)` - Gets specific line
- `aLine.verify()` - Validates one line
- `aLine.status.getMessage()` - Gets error message for invalid line
- `theProof.getConclusion()` - Gets conclusion statement
- `theProof.getPremises()` - Gets premise list

**Proof Format**:
```
| Premise 1
| Premise 2
|---
| Step 1, justification (rule)
| Step 2, justification (rule)
| Conclusion
```

**Rule Sets Supported**:
- Fitch notation (default for LPL)
- Teller's system
- forallx notation
- The Logic Book notation

---

## URL Encoding and Exercise Parameters

### URL Structure

Exercises are identified by URLs with this general pattern:

```
/ex/{exerciseType}/{exerciseSubtype?}/{parameterName1}/{parameterValue1}/{parameterName2}/{parameterValue2}
```

### Exercise Types

- `proof` - Formal proof construction
- `tt` - Truth table construction
- `TorF` - True or false questions
- `trans` - Translation (natural language to logic)
- `tree` - Proof tree construction
- `create` - Create a world/situation
- `q` - Short answer question
- `counter_ex` - Counterexample identification

### Common Parameters

All parameters use **URL encoding** via `encodeURIComponent()`:

1. **Premises and Conclusion**
   ```
   /ex/proof/from/{premise1}|{premise2}/to/{conclusion}
   ```
   - Multiple premises joined by `|` (pipe)
   - Each premise/conclusion URL-encoded
   - Examples:
     - `/ex/proof/from/A%20or%20B/to/C`
     - `/ex/proof/from/A%7CB%7CC/to/A%20and%20(B%20and%20C)`
     - Note: `%20` = space, `%7C` = pipe

2. **Sentences (for truth tables/create exercises)**
   ```
   /ex/tt/qq/{sentence1}|{sentence2}|{sentence3}
   ```
   - Join multiple sentences with `|`
   - URL-encoded
   - `qq` parameter stands for "Q's" (questions/sentences)

3. **Single Sentence**
   ```
   /ex/q/sentence/{sentence}
   /ex/trans/sentence/{sentence}
   ```
   - Single sentence URL-encoded

4. **Possible World (JSON)**
   ```
   /ex/TorF/world/{abbreviated-json}/qq/{sentences}
   ```
   - World is abbreviated JSON array
   - Entire JSON is URL-encoded
   - Abbreviations: w, h, n, c, f for width, height, name, colour, face
   - Example:
     ```
     /world/%5B%7B%22x%22%3A0%2C%22y%22%3A0%2C%22w%22%3A2%2C%22h%22%3A2%2C%22n%22%3A%22a%22%2C%22c%22%3A%22red%22%2C%22f%22%3A%5B%22%3A%22%2C%22-%22%2C%22)%22%5D%7D%5D
     ```

5. **Truth Table Row (for verification)**
   ```
   /TTrow/{var1}:{value1}|{var2}:{value2}
   ```
   - Assignments as `variable:T` or `variable:F`
   - Multiple joined by `|`
   - Example: `/TTrow/A:T|B:F`

6. **Other Parameters**
   - `exerciseSubtype` - e.g., 'orValid', 'orInvalid'
   - Query params: `?courseName=..&variant=..&lectureName=..&unitName=..`

### Encoding Rules

**Special Character Mapping**:
- Space → `%20`
- Pipe `|` → `%7C`
- Left paren `(` → `%28`
- Right paren `)` → `%29`
- Logical symbols usually written in ASCII:
  - `and`, `or`, `not`, `arrow`, `iff`, `forall`, `exists`
  - Or Unicode: `∧`, `∨`, `¬`, `→`, `↔`, `∀`, `∃`

**Double Encoding Prevention**:
- `ix.convertToExerciseId()` decodes first, then encodes each segment
- This prevents double-encoding when URLs are manipulated

### Example Exercise URLs

1. **Proof from premises to conclusion**:
   ```
   /ex/proof/from/A%20and%20B%7CB%20and%20C/to/A%20and%20C
   ```
   Decoded: `/ex/proof/from/A and B|B and C/to/A and C`

2. **Truth table with multiple sentences**:
   ```
   /ex/tt/qq/A%20or%20B%7CB%20and%20not%20A%7C(A%E2%88%A8B)%E2%88%A7%C2%AC(B%E2%88%A7%C2%ACA)
   ```
   Decoded: `/ex/tt/qq/A or B|B and not A|(A∨B)∧¬(B∧¬A)`

3. **Possible world with evaluation**:
   ```
   /ex/TorF/world/[...abbreviated json...]/qq/White(a)|Happy(b)
   ```

4. **With metadata**:
   ```
   /course/UK_W20_PH126/exerciseSet/normal/lecture/lecture_03/unit/Formal%20Proof/listExercises
   ```

### URL Query Parameters

Standard query parameters (not in path):

- `user={userId}` - Override current user (for testing)
- `courseName` - Course identifier
- `variant` - Course variant (e.g., 'normal', 'fast')
- `lectureName` - Lecture name for navigation
- `unitName` - Unit name for navigation

---

## Common Patterns and Functions

### Hashing for Answer Caching

**Purpose**: Enable efficient answer comparison without storing all submitted answers

**Process**:
1. User submits answer
2. Answer is hashed using `ix.hashAnswer()`
3. Hash is looked up in `GradedAnswers` collection
4. If found, use pre-computed grade

**Hash Generation**:
```coffeescript
ix.hashAnswer = (answerDoc) ->
  toHash = answerDoc.answer.content
  if _.isString(toHash)
    # Normalize: lowercase, remove extra whitespace
    toHash = toHash.toLowerCase().replace(/\s+/g,' ').trim()
  else
    if _.isString(toHash.sentence)
      # Don't lowercase FOL (case significant)
      toHash = _.clone(toHash)
      toHash.sentence = toHash.sentence.toLowerCase().replace(/\s+/g,' ').trim()
    toHash = JSON.stringify(toHash)
  
  # Append exercise ID to prevent collisions across exercises
  toHash += ix.getExerciseId()
  return ix.hash(toHash)
```

**Properties**:
- **Fast**: Uses XXHash for O(n) performance
- **Stable**: Same answer always produces same hash
- **Safe**: Exercise ID prevents collisions across different exercises
- **Lossy**: Case normalization for text (but preserves case for logic formulas)

---

### Answer Storage and Reactivity

**Session-Based Storage**:
```coffeescript
ix.getSessionKeyForUserExercise() # Returns "{userId}/{exerciseId}"
ix.getAnswer()                     # Get current answer object
ix.setAnswer(answer)               # Set entire answer object
ix.setAnswerKey(value, key)        # Update one component of answer
```

**Answer Object Structure**:
```javascript
{
  sentence: "P(a) or Q(b)",
  proof: "| P(a)or Q(b)\n|---\n| P(a) or Q(b)",
  tt: [[true, false, true], [false, true, false], ...],
  world: [{x:0, y:0, w:2, h:2, n:"a", c:"white", f:[":","−",")"]}, ...],
  TorF: [true, false, true, ...],
  question: "user typed answer here"
}
```

**Persistence**: 
- Uses `Session.setPersistent()` to survive browser refresh
- Each exercise has own session key to prevent conflicts
- Clears when user navigates to different exercise

---

### Dialect Management

**System Dialects**:
- **lpl** (Language, Proof and Logic) - default
- **teller** - Teller's formal system
- **forallx** - Magnus' forallx
- **logicbook** - The Logic Book

**Setting Dialect**:
```coffeescript
fol.setDialect('lpl')               # Set by dialect name
fol.setDialect('lpl', '0.1')        # Set with version
```

**Current Dialect**:
```coffeescript
info = fol.getCurrentDialectNameAndVersion()  # Returns {name, version}
parser = fol.getCurrentParser()               # Get parser object
rules = fol.getCurrentRules()                 # Get proof rules
```

**Dialect Info in Answers**:
```javascript
answer = {
  content: "P(a)",
  dialectName: "lpl",
  dialectVersion: "0.1"
}
```

**Why Track**: Different dialects use different symbols and proof rules; storing dialect ensures answers can be re-evaluated/re-graded with correct system.

---

### User Role Detection

**Properties in Meteor.user()** (from Accounts system):

```javascript
Meteor.user() = {
  _id: "...",
  emails: [{address: "user@example.com", verified: true}],
  profile: {
    name: "Full Name",
    instructor: true/false,
    seminar_tutor: "tutor@example.com", // email of their seminar tutor
    is_seminar_tutor: true/false,       // whether they ARE a tutor
    is_instructor: true/false
  }
}
```

**Role Checking Functions**:
```coffeescript
ix.isInstructorOrTutor()  # Has either role
ix.userIsTutor()          # Specifically a seminar tutor
ix.userIsInstructor()     # Specifically an instructor
wy.getTuteeIds(email)     # (server-side) Get students of a tutor
```

---

### Translation Between Representations

**awFOL Expression → String**:
```coffeescript
expr = fol.parse("P(a)")
str = expr.toString({replaceSymbols: true})  # "P(a)"
```

**String → awFOL Expression**:
```coffeescript
str = "P(a) and Q(b)"
expr = fol.parse(str)
expr = fol.parseUsingSystemParser(str)  # Uses current dialect parser
```

**Possible World Serialization**:
```coffeescript
# GridStack → Objects array
data = ix.possibleWorld.serialize($grid)           # Full form
data = ix.possibleWorld.serializeAndAbbreviate($grid)  # For URLs

# Objects array → awFOL Situation
situation = ix.possibleWorld.getSituationFromSerializedWord(data)

# Situation → Evaluation results
isTrue = expr.evaluate(situation)
```

---

### Answer Validation Pipeline

**General Flow**:
1. **Syntax Validation**: Parse answer
   - If parse fails: provide parse error message
   - Continue even if parse fails (for partially entered answers)

2. **Structure Validation**: Check format
   - Truth table: correct number of rows, correct order
   - Proof: correct premises and conclusion
   - Sentences: well-formed (may or may not require full parsing)

3. **Content Validation**: Check correctness
   - Truth table: each cell matches computed value
   - Proof: each line is justified by valid rule
   - Counterexample: premises true, conclusion false
   - Multiple choice: matches expected answer

4. **Grading**: Compare to known correct answers
   - Hash lookup for fast matching
   - PNF equivalence check for logical equivalence
   - Return `{isCorrect, comment}` or `undefined` (no grade available)

---

## Component-Specific Utilities

### CodeMirror Integration (meteor_component.coffee)

**Templates**:

#### `editSentence` Template
- **Purpose**: Edit single formula with real-time feedback
- **Options**:
  - `theme` - "blackboard" (dark) theme
  - `lineNumbers` - false (single line)
  - `autofocus` - true
  - `matchBrackets` - true
  - `tabSize` - 2
  
- **Features**:
  - Real-time Session update on every keystroke
  - "Convert to symbols" button to transform notation
  - Feedback line for error messages
  - Loads saved answer on render
  - Reactive to Session changes (e.g., when user hits "load answer")

- **Data Context**:
  ```javascript
  {{> editSentence 
    editorId="proof-editor"
    defaultContent="P(a)"
    sentenceIsAwFOL=true
  }}
  ```

#### `editProof` Template
- **Purpose**: Edit multi-line formal proof with line-by-line verification
- **Options**:
  - `theme` - "blackboard"
  - `lineNumbers` - true
  - `gutters` - ["error-light"] for error indicators
  - `tabSize` - 4
  - Custom Tab key to insert 4 spaces
  
- **Features**:
  - Real-time line verification on arrow keys
  - Color-coded dots (green/red) showing line validity
  - Auto-indentation on Enter
  - "Check proof" button for full verification
  - "Reset proof" button with confirmation
  - "Convert to symbols" button
  - Feedback line for detailed error messages
  - Loads from URL params if no saved answer

- **Key Functions**:
  - `checkLine(lineNumber)` - Verify single line
  - `addMarker(lineNumber, color, editor)` - Add indicator dot
  - `autoIndent(editor)` - Auto-indent new line
  - `getCurrentLineNumberInEditor(editor)` - Get cursor position

- **Keyboard Events**:
  - `Up`: Check line above, show feedback
  - `Down`: Check line below, show feedback
  - `Enter`: Auto-indent, check new line

---

### TorF Questions Template (TorF_questions.coffee)

**Template**: `TorF_questions`

**Purpose**: Display and capture true/false questions

**Features**:
- Radio buttons for each question (true/false)
- Saves answer array on click
- Reactive to Session (updates UI when answer changes elsewhere)
- Clears selections when no answer saved

**Helpers**:
- `isTrueChecked` - Returns true if this index is true
- `isFalseChecked` - Returns true if this index is false

**Key Functions**:
- `arrayToRadio(array)` - Sets which radios are checked
- `clearRadios()` - Clears all selections

**Answer Format**: `[true, false, true, false, ...]` array of booleans

---

### Exercise Schema (ex_builder/exercise_schema.coffee)

**Purpose**: Validates exercise/exercise set data structure

**Location**: `client/lib/ex_builder/exercise_schema.coffee`

**Usage**: Likely used in exercise creation/editing interface

**Related**: `jsoneditor.js` for JSON schema editor UI

---

### Routes Configuration (routes.coffee)

**Purpose**: Define all application routes

**Key Routes**:
- `/` - Home page
- `/courses` - List available courses
- `/course/:courseName` - Course details
- `/course/:courseName/exerciseSet/:variant` - Exercise set
- `/ex/:exerciseType/...` - Actual exercise pages
- `/mySubmittedExercises` - Student submission history
- `/feedbackToReview` - Tutor feedback interface

**Pattern**: Routes use FlowRouter and BlazeLayout to render templates

**Exercise Routes** (partial, shows pattern):
```coffeescript
FlowRouter.route '/ex/:exerciseType/:exerciseSubtype?/...',
  action: (params, queryParams) ->
    # Render appropriate exercise template
```

---

### Additional Helper Libraries

#### hint.css
- **Purpose**: CSS tooltips and hints
- **Location**: `/client/lib/hint.css`
- **Usage**: Visual hints in UI

#### site_style.css.styl
- **Purpose**: Custom CSS styles
- **Location**: `/client/lib/site_style.css.styl`
- **Format**: Stylus preprocessor syntax

---

## Summary

The love-logic-server project provides a comprehensive set of utilities for:

1. **UI Management**: URLs, navigation, templates, form input
2. **Logic Systems**: Parsing, evaluation, proof checking, grading
3. **Data Storage**: Session-based answer storage, hashing for efficient comparison
4. **User Management**: Role detection, tutor-student relationships
5. **Exercise Handling**: Parameter extraction, encoding/decoding, metadata management
6. **Component Integration**: GridStack for worlds, CodeMirror for editing, Materialize for UI

The two main utility libraries are:
- **ix** (client-only): Comprehensive utilities for UI, exercises, and user interaction
- **wy** (shared): Minimal shared utilities for grading roles

Together with third-party libraries like AWFOL, CodeMirror, and GridStack, they provide a complete system for interactive logic education exercises.

