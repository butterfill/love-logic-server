# Love Logic Server - MongoDB Collections Schema Documentation

This document provides a comprehensive overview of all MongoDB collections in the love-logic-server project, including their structure, fields, indexes, relationships, and usage patterns.

---

## Table of Contents
1. [Collections Overview](#collections-overview)
2. [Collection Details](#collection-details)
3. [Relationships Between Collections](#relationships-between-collections)
4. [Indexes](#indexes)
5. [Denormalized Data Patterns](#denormalized-data-patterns)
6. [User Collection](#user-collection)

---

## Collections Overview

The love-logic-server application uses **6 custom MongoDB collections** plus the built-in Meteor users collection:

| Collection Name | MongoDB Name | Purpose | Primary Keys |
|---|---|---|---|
| **Courses** | `courses` | Define available courses and their descriptions | `name` |
| **ExerciseSets** | `exercise_sets` | Group exercises by course and variant | `courseName`, `variant` |
| **SubmittedExercises** | `submitted_exercises` | Store student submissions and feedback | `_id`, `owner`, `exerciseId` |
| **Subscriptions** | `subscriptions` | Track which exercise sets students are enrolled in | `owner`, `courseName`, `variant` |
| **GradedAnswers** | `graded_answers` | Cache of graded answers for auto-grading | `exerciseId`, `ownerIdHash`, `answerHash` |
| **HelpRequest** | `help_request` | Student help requests and tutor responses | `_id`, `requesterId`, `exerciseId` |
| **Meteor.users** | `users` | User accounts and profiles (Meteor built-in) | `_id` |

---

## Collection Details

### 1. Courses Collection (`courses`)

**MongoDB Collection Name:** `courses`

**Purpose:** Defines available courses for the logic learning platform.

**Fields:**

| Field Name | Data Type | Required | Index | Purpose |
|---|---|---|---|---|
| `_id` | ObjectId | Yes | Primary | MongoDB auto-generated unique identifier |
| `name` | String | Yes | **Unique** | Course identifier (e.g., 'UK_W20_PH126') |
| `description` | String | Yes | No | Human-readable course description |
| `hidden` | Boolean | No | No | If true, course is not displayed in public course lists |
| `created` | Date | No | No | Timestamp when course was created |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439011"),
  name: "UK_W20_PH126",
  description: "Exercises for Logic I (PH126 and PH136) at the University of Warwick",
  hidden: false,
  created: ISODate("2015-11-01T10:00:00Z")
}
```

**Constraints:**
- Course names must be URL-encoded (no special characters)
- Course can only be deleted if it has no associated ExerciseSets

**Indexes:**
- `name` (ascending) - for finding courses by name

**Default Values:**
- None specified in code

---

### 2. ExerciseSets Collection (`exercise_sets`)

**MongoDB Collection Name:** `exercise_sets`

**Purpose:** Groups exercises by course and difficulty variant (e.g., normal, fast).

**Fields:**

| Field Name | Data Type | Required | Index | Purpose |
|---|---|---|---|---|
| `_id` | ObjectId | Yes | Primary | MongoDB auto-generated unique identifier |
| `courseName` | String | Yes | **Yes** | Reference to parent course |
| `variant` | String | Yes | **Yes** | Difficulty variant (e.g., 'normal', 'fast') |
| `description` | String | Yes | No | Description of this exercise set |
| `owner` | String (UserId) | Yes | **Yes** | ObjectId of the user who created this set |
| `lectures` | Array[Object] | Yes | No | Array of lecture objects containing exercises |
| `lectures[].type` | String | Yes | No | Always 'lecture' |
| `lectures[].name` | String | Yes | No | Lecture identifier (e.g., 'lecture_03') |
| `lectures[].slides` | String | Yes | No | URL to lecture slides |
| `lectures[].handout` | String | Yes | No | URL to lecture handout PDF |
| `lectures[].units` | Array[Object] | Yes | No | Array of unit objects |
| `lectures[].units[].type` | String | Yes | No | Always 'unit' |
| `lectures[].units[].name` | String | Yes | No | Unit name |
| `lectures[].units[].slides` | String | Yes | No | URL to unit slides/resources |
| `lectures[].units[].rawReading` | Array[String] | Yes | No | Section references for reading material |
| `lectures[].units[].rawExercises` | Array[String] | Yes | No | Array of exercise URLs/identifiers |
| `hidden` | Boolean | No | No | If true, exercise set is not visible to students |
| `created` | Date | No | No | Timestamp when exercise set was created |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439012"),
  courseName: "UK_W20_PH126",
  variant: "normal",
  description: "Exercises for students without A-Level maths",
  owner: ObjectId("507f1f77bcf86cd799439001"),
  created: ISODate("2015-11-01T10:00:00Z"),
  hidden: false,
  lectures: [
    {
      type: "lecture",
      name: "lecture_03",
      slides: "http://logic-1.butterfill.com/lecture_03.html",
      handout: "http://logic-1.butterfill.com/handouts/lecture_03.handout.pdf",
      units: [
        {
          type: "unit",
          name: "Formal Proof: ∧Elim and ∧Intro",
          slides: "http://logic-1.butterfill.com/units/unit_21.html",
          rawReading: ["5.1", "6.1"],
          rawExercises: [
            "/ex/proof/from/A and B/to/A",
            "/ex/proof/from/A|B/to/A and B"
          ]
        }
      ]
    }
  ]
}
```

**Constraints:**
- Unique constraint on (courseName, variant) combination
- Variant names must be URL-encoded
- ExerciseSet can only be deleted if it has no associated lectures

**Indexes:**
- `courseName` (ascending)
- `owner` (ascending)
- `courseName, variant` (composite ascending) - for finding specific exercise sets

**Default Values:**
- `hidden`: false (if not provided, courses are shown by default)

**Relationships:**
- Foreign key to `Courses` via `courseName`
- Foreign key to `Meteor.users` via `owner` (the instructor/tutor who created it)
- One ExerciseSet to Many SubmittedExercises (via exerciseId matching)
- One ExerciseSet to Many Subscriptions (via exerciseSetId)

---

### 3. SubmittedExercises Collection (`submitted_exercises`)

**MongoDB Collection Name:** `submitted_exercises`

**Purpose:** Stores student exercise submissions along with machine and human feedback/grading.

**Fields:**

| Field Name | Data Type | Required | Index | Purpose |
|---|---|---|---|---|
| `_id` | ObjectId | Yes | Primary | MongoDB auto-generated unique identifier |
| `owner` | String (UserId) | Yes | **Yes** | ObjectId of the student who submitted |
| `ownerName` | String | No | No | Display name of the student (denormalized) |
| `email` | String | No | No | Email of the student (denormalized) |
| `exerciseId` | String | Yes | **Yes** | URL-based exercise identifier |
| `answer` | Object | No | No | The submitted answer object |
| `answer.content` | Object | No | No | Content of the answer |
| `answer.content.proof` | String | No | No | For proof exercises: the proof text |
| `answer.content.TorF` | Array[Boolean] | No | No | For true/false exercises: [value] |
| `answer.content.dialectName` | String | No | No | Logic dialect used (e.g., 'PNF') |
| `answer.content.dialectVersion` | String | No | No | Version of the logic dialect |
| `created` | Date | Yes | No | Timestamp when answer was submitted |
| `humanFeedback` | Object | No | No | Feedback provided by a human tutor |
| `humanFeedback.isCorrect` | Boolean | No | No | Whether the answer is correct |
| `humanFeedback.comment` | String | No | No | Tutor's written feedback |
| `humanFeedback.studentSeen` | Boolean | No | No | Whether student has viewed the feedback |
| `humanFeedback.studentEverSeen` | Boolean | No | No | Whether student has ever viewed this feedback |
| `machineFeedback` | Object | No | No | Automatic feedback from the system |
| `machineFeedback.isCorrect` | Boolean | No | No | Whether machine determined answer is correct |
| `machineFeedback.comment` | String | No | No | Machine-generated feedback message |
| `answerPNFsimplifiedSorted` | String | No | No | Normalized form of answer for comparison |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439013"),
  owner: ObjectId("507f1f77bcf86cd799439002"),
  ownerName: "John Smith",
  email: "j.smith@example.com",
  exerciseId: "/ex/proof/from/A and B/to/A",
  created: ISODate("2015-11-15T14:30:00Z"),
  answer: {
    content: {
      proof: "1. A and B (assumption)\n2. A (∧Elim, 1)",
      dialectName: "PNF",
      dialectVersion: "1.0"
    }
  },
  humanFeedback: {
    isCorrect: true,
    comment: "Dr. Smith writes: Excellent work. Correct application of ∧Elim.",
    studentSeen: true,
    studentEverSeen: true
  },
  machineFeedback: {
    isCorrect: true,
    comment: "Automatically validated."
  },
  answerPNFsimplifiedSorted: "A\n∧Elim\nA∧B"
}
```

**Constraints:**
- Only one submission per (owner, exerciseId) pair active at a time (upserted, not inserted)
- `humanFeedback` cannot be added to submissions created by other users (authorization check)
- If a submission has human feedback, only tutors can add/modify it

**Indexes:**
- `owner` (ascending)
- `exerciseId` (ascending)
- `owner, exerciseId` (composite ascending) - for finding student's submission to specific exercise
- `owner, humanFeedback.studentSeen` (composite) - for finding unseen feedback
- `owner, exerciseId` (composite) - for grading flow

**Default Values:**
- None specified

**Relationships:**
- Foreign key to `Meteor.users` via `owner`
- Inverse relationship from ExerciseSets (exercises are referenced in ExerciseSet's `lectures[].units[].rawExercises`)
- One submission to Many HelpRequests (via `submittedExerciseId` in HelpRequest)
- One submission to Many GradedAnswers (via content hash matching)

**Denormalization:**
- `ownerName` and `email` are denormalized from Meteor.users profile
- `answerPNFsimplifiedSorted` is a pre-computed hash for quick comparison in auto-grading

---

### 4. Subscriptions Collection (`subscriptions`)

**MongoDB Collection Name:** `subscriptions`

**Purpose:** Tracks which exercise sets each student is enrolled in or following.

**Fields:**

| Field Name | Data Type | Required | Index | Purpose |
|---|---|---|---|---|
| `_id` | ObjectId | Yes | Primary | MongoDB auto-generated unique identifier |
| `owner` | String (UserId) | Yes | **Yes** | ObjectId of the student |
| `courseName` | String | Yes | No | Reference to the course |
| `variant` | String | Yes | No | Exercise set variant (e.g., 'normal', 'fast') |
| `exerciseSetId` | String (ExerciseSetId) | Yes | No | ObjectId of the ExerciseSet |
| `created` | Date | Yes | No | Timestamp when subscription was created |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439014"),
  owner: ObjectId("507f1f77bcf86cd799439002"),
  courseName: "UK_W20_PH126",
  variant: "normal",
  exerciseSetId: ObjectId("507f1f77bcf86cd799439012"),
  created: ISODate("2015-11-15T10:00:00Z")
}
```

**Constraints:**
- Unique constraint on (owner, courseName, variant) - student can only follow one variant of a course
- Cannot create duplicate subscriptions for the same student and exercise set

**Indexes:**
- `owner` (ascending) - for finding student's subscriptions
- Composite indexes for various queries: (owner, exerciseSetId), (owner, courseName, variant)

**Default Values:**
- None specified

**Relationships:**
- Foreign key to `Meteor.users` via `owner`
- Foreign key to ExerciseSet via `exerciseSetId`
- Foreign key to Courses via `courseName`

---

### 5. GradedAnswers Collection (`graded_answers`)

**MongoDB Collection Name:** `graded_answers`

**Purpose:** Cache of graded exercise answers used for auto-grading similar submissions. When a tutor grades an exercise, the result is stored here so students submitting the same answer can be automatically graded.

**Fields:**

| Field Name | Data Type | Required | Index | Purpose |
|---|---|---|---|---|
| `_id` | ObjectId | Yes | Primary | MongoDB auto-generated unique identifier |
| `exerciseId` | String | Yes | **Yes** | Reference to the exercise |
| `ownerIdHash` | String | Yes | No | Hash of the original grader's ID (for monitoring changes) |
| `answerHash` | String | Yes | No | Hash of the answer content for comparison |
| `isCorrect` | Boolean | No | No | Whether this answer was marked as correct |
| `comment` | String | No | No | Feedback/grading comment |
| `answerPNFsimplifiedSorted` | String | No | No | Normalized answer representation |
| `graderId` | String (UserId) | No | No | ObjectId of the user who graded this answer |
| `answer` | Object | No | No | Full answer object with metadata |
| `answer.content` | Object | No | No | Answer content |
| `answer.content.dialectName` | String | No | No | Logic dialect used |
| `answer.content.dialectVersion` | String | No | No | Dialect version |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439015"),
  exerciseId: "/ex/proof/from/A and B/to/A",
  ownerIdHash: "a1b2c3d4e5f6g7h8",
  answerHash: "f1e2d3c4b5a6979a",
  isCorrect: true,
  comment: "Dr. Smith writes: Correct use of ∧Elim.",
  graderId: ObjectId("507f1f77bcf86cd799439003"),
  answer: {
    content: {
      proof: "1. A and B (assumption)\n2. A (∧Elim, 1)",
      dialectName: "PNF",
      dialectVersion: "1.0"
    }
  },
  answerPNFsimplifiedSorted: "A\n∧Elim\nA∧B"
}
```

**Constraints:**
- Unique constraint on (exerciseId, ownerIdHash, answerHash) - can only have one graded version of each unique answer
- Should only be updated/uperted, not deleted (supports auto-grading feature)

**Indexes:**
- `exerciseId` (ascending) - for retrieving graded answers for an exercise

**Default Values:**
- `isCorrect`: undefined (may not be set)
- `comment`: undefined (may not be set)

**Relationships:**
- Foreign key to `Meteor.users` via `graderId`
- Matches against SubmittedExercises via answer hashes

**Purpose in Auto-Grading:**
When a student submits an answer:
1. System computes hash of the answer
2. Looks up this hash in GradedAnswers
3. If found, applies the cached grade automatically
4. This speeds up grading and ensures consistency

---

### 6. HelpRequest Collection (`help_request`)

**MongoDB Collection Name:** `help_request`

**Purpose:** Tracks student requests for help on exercises and tutor responses.

**Fields:**

| Field Name | Data Type | Required | Index | Purpose |
|---|---|---|---|---|
| `_id` | ObjectId | Yes | Primary | MongoDB auto-generated unique identifier |
| `requesterId` | String (UserId) | Yes | **Yes** | ObjectId of student requesting help |
| `exerciseId` | String | Yes | **Yes** | Reference to the exercise student needs help with |
| `submittedExerciseId` | String (SubmittedExerciseId) | Yes | No | ObjectId of the submitted exercise |
| `question` | String | Yes | No | Student's question/help request description |
| `reviewedLectureSlides` | Boolean | No | No | Whether student reviewed slides before asking |
| `readTextbook` | Boolean | No | No | Whether student read textbook before asking |
| `created` | Date | Yes | No | Timestamp when help was requested |
| `answer` | String | No | No | Tutor's response/answer |
| `dateAnswered` | Date | No | No | Timestamp when tutor answered the question |
| `answererId` | String (UserId) | No | No | ObjectId of the tutor who answered |
| `answererName` | String | No | No | Display name of answering tutor (denormalized) |
| `studentSeen` | Date | No | No | Timestamp when student viewed the answer |
| `requesterTutorEmail` | String | No | No | Email of student's assigned tutor (denormalized) |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439016"),
  requesterId: ObjectId("507f1f77bcf86cd799439002"),
  exerciseId: "/ex/proof/from/A and B/to/A",
  submittedExerciseId: ObjectId("507f1f77bcf86cd799439013"),
  question: "I'm not sure how to apply the ∧Elim rule correctly. Can you explain the syntax?",
  reviewedLectureSlides: true,
  readTextbook: false,
  created: ISODate("2015-11-16T10:30:00Z"),
  answer: "The ∧Elim rule allows you to extract components from a conjunction. From 'A and B', you can derive either A or B.",
  dateAnswered: ISODate("2015-11-16T14:00:00Z"),
  answererId: ObjectId("507f1f77bcf86cd799439003"),
  answererName: "Dr. Smith",
  studentSeen: ISODate("2015-11-16T15:00:00Z"),
  requesterTutorEmail: "tutor@example.com"
}
```

**Constraints:**
- Help requests can only be created by authenticated users
- Only tutors can answer help requests (but "anyone may answer")
- Once answered, students can see the answer

**Indexes:**
- `requesterId, exerciseId` (composite ascending)
- `exerciseId, requesterId` (composite ascending)
- `requesterId` (ascending)
- `requesterId, answer, studentSeen` (composite ascending) - for finding unseen answered requests

**Default Values:**
- None specified

**Relationships:**
- Foreign key to `Meteor.users` via `requesterId`
- Foreign key to SubmittedExercises via `submittedExerciseId`
- Foreign key to `Meteor.users` via `answererId`

**Denormalization:**
- `answererName` is denormalized from Meteor.users
- `requesterTutorEmail` is denormalized from student's profile

---

## Relationships Between Collections

### Collection Relationship Diagram

```
Meteor.users
├── is_id_in --> Courses (owned_by)
├── is_id_in --> ExerciseSets (owner)
├── is_id_in --> SubmittedExercises (owner)
├── is_id_in --> Subscriptions (owner)
├── is_id_in --> GradedAnswers (graderId)
├── is_id_in --> HelpRequest (requesterId or answererId)
└── has_profile --> (seminar_tutor, instructor, is_seminar_tutor, is_instructor)

Courses
├── name_in --> ExerciseSets (courseName)
└── name_in --> Subscriptions (courseName)

ExerciseSets
├── _id_in --> Subscriptions (exerciseSetId)
├── contains_references_to --> SubmittedExercises (via exerciseId in lectures[].units[].rawExercises)
├── contains_references_to --> GradedAnswers (via exerciseId in lectures[].units[].rawExercises)
└── contains_references_to --> HelpRequest (via exerciseId in lectures[].units[].rawExercises)

SubmittedExercises
├── _id_in --> HelpRequest (submittedExerciseId)
└── answer_hash_in --> GradedAnswers (answerHash for auto-grading)

Subscriptions
├── points_to --> ExerciseSets (exerciseSetId)
└── filters --> SubmittedExercises (for tutor views based on who they follow)
```

### Key Relationships:

1. **Courses → ExerciseSets**
   - One Courses has Many ExerciseSets
   - Relationship: Courses.name = ExerciseSets.courseName
   - Cardinality: 1:N

2. **ExerciseSets → SubmittedExercises**
   - Indirect: Via exerciseId matching
   - ExerciseSets contains rawExercises URLs in lectures[].units[]
   - These match the exerciseId in SubmittedExercises
   - Cardinality: 1:N

3. **Meteor.users → SubmittedExercises**
   - One User has Many SubmittedExercises (as student)
   - Relationship: Meteor.users._id = SubmittedExercises.owner
   - Cardinality: 1:N

4. **Meteor.users → HelpRequest**
   - One User has Many HelpRequests (as requester)
   - Relationship: Meteor.users._id = HelpRequest.requesterId
   - One User has Many HelpRequests (as answerer)
   - Relationship: Meteor.users._id = HelpRequest.answererId
   - Cardinality: 1:N

5. **SubmittedExercises → HelpRequest**
   - One SubmittedExercise has Many HelpRequests
   - Relationship: SubmittedExercises._id = HelpRequest.submittedExerciseId
   - Cardinality: 1:N

6. **Subscriptions → (Meteor.users, ExerciseSets)**
   - Junction/Bridge collection
   - Tracks many-to-many relationship: users follow exercise sets
   - Relationship: Meteor.users._id = Subscriptions.owner AND ExerciseSets._id = Subscriptions.exerciseSetId
   - Cardinality: N:N

7. **GradedAnswers** (Reference table)
   - Referenced by SubmittedExercises when auto-grading
   - Matched via exerciseId + answerHash
   - Used for consistency in grading similar submissions

---

## Indexes

Comprehensive list of all database indexes for query optimization:

### Courses Indexes
```javascript
Courses._ensureIndex({name:1})
```
- **Purpose:** Quick lookup of courses by name
- **Usage:** When displaying specific course or checking for duplicates

### ExerciseSets Indexes
```javascript
ExerciseSets._ensureIndex({courseName:1})
ExerciseSets._ensureIndex({owner:1})
ExerciseSets._ensureIndex({courseName:1, variant:1})
```
- **Purpose:** 
  - `courseName`: Find all exercises sets in a course
  - `owner`: Find all exercise sets owned by a user
  - `courseName, variant`: Find specific exercise set (unique lookup)

### SubmittedExercises Indexes
```javascript
SubmittedExercises._ensureIndex({owner:1})
SubmittedExercises._ensureIndex({owner:1, exerciseId:1})
SubmittedExercises._ensureIndex({owner:1, 'humanFeedback.studentSeen':1})
SubmittedExercises._ensureIndex({exerciseId:1})
SubmittedExercises._ensureIndex({owner:1, exerciseId:1}) // composite for progress tracking
```
- **Purpose:**
  - `owner`: Efficient filtering by student
  - `owner, exerciseId`: Finding student's response to specific exercise
  - `owner, humanFeedback.studentSeen`: Finding unseen feedback
  - `exerciseId`: Finding all submissions for an exercise

### Subscriptions Indexes
```javascript
Subscriptions._ensureIndex({owner:1})
```
- **Purpose:** Find all subscriptions for a user

### GradedAnswers Indexes
```javascript
GradedAnswers._ensureIndex({exerciseId:1})
```
- **Purpose:** Retrieve graded answers for an exercise (for auto-grading)
- **Note:** Comment in code suggests composite index on (exerciseId, ownerIdHash, answerHash) should be created for uniqueness constraint

### HelpRequest Indexes
```javascript
HelpRequest._ensureIndex({requesterId:1, exerciseId:1})
HelpRequest._ensureIndex({exerciseId:1, requesterId:1})
HelpRequest._ensureIndex({requesterId:1})
HelpRequest._ensureIndex({requesterId:1, answer:1, studentSeen:1})
HelpRequest._ensureIndex({exerciseId:1, requesterId:1})
HelpRequest._ensureIndex({requesterId:1})
```
- **Purpose:**
  - `requesterId, exerciseId`: Help request for specific student and exercise
  - `requesterId`: All help requests from a student
  - `requesterId, answer, studentSeen`: Find unanswered requests or unseen answers

### Meteor.users Indexes
```javascript
Meteor.users._ensureIndex({"profile.seminar_tutor":1})
Meteor.users._ensureIndex({'profile.is_seminar_tutor':1})
Meteor.users._ensureIndex({"profile.instructor":1})
```
- **Purpose:**
  - `profile.seminar_tutor`: Find students of a specific tutor
  - `profile.is_seminar_tutor`: Find all tutors
  - `profile.instructor`: Find tutors of a specific instructor

---

## Denormalized Data Patterns

The application uses selective denormalization to optimize common queries:

### 1. SubmittedExercises Collection
**Denormalized Fields:** `ownerName`, `email`, `answerPNFsimplifiedSorted`

```javascript
// From Meteor.users
ownerName: Meteor.user().profile?.name
email: Meteor.user().emails[0].address

// Computed field
answerPNFsimplifiedSorted: // normalized form of answer for fast comparison
```

**Reason:** Avoid repeated lookups to Meteor.users when displaying exercise submissions. Student name and email appear in feedback views frequently.

**Update Strategy:** Updated whenever student updates profile (not automatic)

### 2. HelpRequest Collection
**Denormalized Fields:** `answererName`, `requesterTutorEmail`

```javascript
// From Meteor.users
answererName: Meteor.user().profile?.name

// From requester's profile
requesterTutorEmail: Meteor.user().profile.seminar_tutor
```

**Reason:** Display tutor names without additional lookups when viewing help request answers. Store requester's assigned tutor for filtering/routing.

**Update Strategy:** Set at creation time, not updated

### 3. GradedAnswers Collection
**Denormalized Fields:** `answer.content.dialectName`, `answer.content.dialectVersion`

**Reason:** Preserve dialect information with graded answers for historical accuracy. Allows tracking which logic dialect version was used when answer was graded.

**Update Strategy:** Set when answer is graded, immutable

---

## Computed Fields and Virtual Properties

The application doesn't use traditional Mongoose virtuals, but computes several derived fields on the fly:

### In SubmittedExercises:
```javascript
// Computed on query/read:
isCorrectnessDetermined = humanFeedback?.isCorrect? || machineFeedback?.isCorrect?
rightOrWrong = (humanFeedback?.isCorrect) ? "correct" : "incorrect"
isAnswerComplete = answer?.content? && (answer.content.proof || answer.content.TorF)
```

### In HelpRequest:
```javascript
isAnswered = answer? // presence of answer field
isSeenByStudent = studentSeen? // presence of date field
```

### Aggregation Computations:
The application uses MongoDB aggregation pipeline in several methods:

1. **getExercisesToGrade()** - Uses `$match`, `$project`, `$group` to find exercises needing feedback
2. **getNofSubmittedExercisesNoResubmits()** - Groups by (exerciseId, owner) then counts unique students per exercise
3. **getTuteeIds()** - Fetches and transforms user data (not aggregation, but data transformation)

---

## User Collection (Meteor.users)

**MongoDB Collection Name:** `users`

**Purpose:** Built-in Meteor collection for user authentication and profiles. Used throughout the application for access control and user information.

**Key Fields Used in love-logic-server:**

| Field Name | Data Type | Purpose |
|---|---|---|
| `_id` | ObjectId | User unique identifier |
| `emails` | Array[Object] | User email addresses |
| `emails[].address` | String | Email address |
| `emails[].verified` | Boolean | Whether email is verified |
| `profile` | Object | User profile information |
| `profile.name` | String | User's display name |
| `profile.is_seminar_tutor` | Boolean | Whether user is a seminar tutor |
| `profile.seminar_tutor` | String | Email of user's assigned seminar tutor |
| `profile.is_instructor` | Boolean | Whether user is an instructor |
| `profile.instructor` | String | Email of user's instructor |

**Sample Document:**
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439002"),
  emails: [
    {
      address: "j.smith@example.com",
      verified: true
    }
  ],
  profile: {
    name: "John Smith",
    is_seminar_tutor: true,
    seminar_tutor: "tutor@example.com",
    is_instructor: false,
    instructor: null
  }
  // ... other Meteor-specific fields like createdAt, services, etc.
}
```

**Relationships with Other Collections:**
- Referenced by `owner` field in: ExerciseSets, SubmittedExercises, Subscriptions
- Referenced by `graderId` in GradedAnswers
- Referenced by `requesterId` and `answererId` in HelpRequest
- Referenced by `seminar_tutor` email matching for tutor-tutee relationships

---

## Authorization and Access Control Rules

The application enforces several important authorization rules through Meteor methods and publish functions:

### User Role Hierarchy
- **Student:** Base user role, can submit exercises and request help
- **Seminar Tutor:** Can grade exercises of assigned tutees, answer help requests
- **Instructor:** Can manage courses, exercise sets; view data of tutors' tutees

### Course and Exercise Set Authorization
- Only the owner of an ExerciseSet can modify it
- Only instructors/tutors can be owners
- Courses can be deleted only by their creator if they have no exercise sets

### SubmittedExercises Authorization
- Students can only see/submit their own exercises
- Tutors can see exercises of their assigned tutees
- Instructors can see exercises of tutees of tutors under their supervision
- Only tutors/instructors can add human feedback
- Student owner cannot change (checked in `addHumanFeedback`)

### Help Request Authorization  
- Students can only see/request help on their own exercises
- Anyone can answer help requests (system allows all users to respond)
- Students can only mark their own requests as seen

### Tutor-Tutee Relationship
- Stored via `profile.seminar_tutor` field (email-based)
- Enables filtering of submissions to only student's tutees
- Supports instructor→tutor→student hierarchical access

---

## Publishing/Subscription Rules

The application uses Meteor publish functions to control data access:

### Public Publications (Available to any authenticated user)
- `courses` - All non-hidden courses
- `course` (specific) - Specific course
- `exercise_sets` (for course) - Exercise sets in a course
- `exercise_sets_owned_by` (userId) - Exercise sets owned by user
- `exercise_set` (courseName, variant) - Specific exercise set
- `subscriptions` - User's own subscriptions

### Student Publications
- `submitted_exercises` (userId) - User's own submissions
- `submitted_exercise` (exerciseId) - User's submission for specific exercise
- `help_request` (exerciseId) - User's help requests for exercise
- `next_exercise_with_unseen_feedback` - Next exercise with unseen feedback
- `exercises_with_unseen_feedback` - All exercises with unseen feedback
- `next_help_request_with_unseen_answer` - Next unanswered help request
- `dates_exercises_submitted` (userId) - Progress tracking

### Tutor Publications
- `tutees` (tutorId, optional limit) - List of user's tutees
- `tutees_subscriptions` (tutorId) - Subscriptions of user's tutees
- `submitted_answers` (exerciseId, tuteeId) - Answers from tutees
- `help_requests_for_tutor` (exerciseId) - Help requests from tutees
- `all_unanswered_help_requests_for_tutor` () - All unanswered requests
- `tutees_progress` (tutorId, optional limit) - Progress of tutees
- `graded_answers` (exerciseId) - Cached graded answers

### Instructor Publications
- `tutors_for_instructor` (tutorId) - Tutors managed by instructor

---

## Schema Validation and Constraints

### Application-Level Validation

**Courses:**
- Name must be URL-encodable (checked with `encodeURIComponent`)
- Name must be unique
- Cannot delete if has associated ExerciseSets

**ExerciseSets:**
- courseName and variant must be URL-encodable
- (courseName, variant) must be unique
- Cannot delete if has associated lectures
- owner must match creator's userId

**SubmittedExercises:**
- Must have exerciseId and owner
- Cannot have userId in submitted exercise (security check)
- Only one active submission per (owner, exerciseId) due to upsert pattern

**Subscriptions:**
- owner and (courseName, variant) must be unique
- Cannot create duplicate subscriptions

**HelpRequest:**
- question cannot be empty string
- Must have exerciseId and requesterId
- Student must have submitted before requesting help

---

## Migration and Backup Considerations

### Important Fields for Backups
- All user-generated data: answers, feedback, help requests
- All user relationships: subscriptions, tutor assignments
- All instructor content: courses, exercise sets

### Immutable Fields (Should not be modified)
- `created` timestamps
- `_id` identifiers
- Exercise answers once submitted and graded

### Fields Safe to Modify
- `humanFeedback.comment` (if `studentEverSeen` is not true)
- `hidden` flags on Courses and ExerciseSets
- Profile information on Meteor.users

---

## Query Performance Considerations

### Heavy Query Patterns

1. **Finding student's progress** (Tutor view)
   ```
   Query: SubmittedExercises.find({owner:{$in:tuteeIds}})
   Indexes: owner
   Optimization: ExerciseSet subscription filtering reduces tuteeIds
   ```

2. **Auto-grading new submission**
   ```
   Query: GradedAnswers.find({exerciseId, answerHash})
   Indexes: exerciseId
   Optimization: Hash match quick comparison before lookup
   ```

3. **Finding exercises to grade**
   ```
   Aggregation with $match, $project, $group
   Indexes: owner, and nested field humanFeedback.isCorrect
   Optimization: Pipeline filters before grouping
   ```

4. **Tutor dashboard** (All tutees and their progress)
   ```
   Queries: 
   - SubmittedExercises.find({owner:{$in:tuteeIds}})
   - Subscriptions.find({owner:{$in:tuteeIds}})
   Indexes: owner (critical for both)
   ```

### Slow Query Risks
- Large $in queries on owner field without limit
- Aggregation without proper $match ordering
- Searching humanFeedback nested fields without index

---

## Data Growth Projections

Expected growth drivers:
- **SubmittedExercises:** Grows with student activity (one per submission per student)
- **GradedAnswers:** Grows as tutors grade, but slower than SubmittedExercises (cached)
- **HelpRequest:** One per student question (typically lower volume than submissions)
- **Subscriptions:** One per student per course variant (stable, not rapid growth)
- **Courses & ExerciseSets:** Controlled by instructors (slow growth)

Recommendation: Create regular indexes and consider archiving old submissions after course completion.

