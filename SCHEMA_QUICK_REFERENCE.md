# MongoDB Schema - Quick Reference Guide

## Collections at a Glance

| Collection | Key Fields | Main Purpose | Size Risk |
|---|---|---|---|
| **courses** | name, description | Define course catalog | Low - ~10-50 docs |
| **exercise_sets** | courseName, variant, owner | Group exercises by difficulty | Low - ~50-200 docs |
| **submitted_exercises** | owner, exerciseId, answer, humanFeedback | Track student work & grading | **High** - grows with each submission |
| **subscriptions** | owner, exerciseSetId | Student enrollments | Medium - 1 per student per set |
| **graded_answers** | exerciseId, answerHash | Cache auto-grading data | Medium - capped by unique answers |
| **help_request** | requesterId, exerciseId | Help Q&A tracking | Medium - 1 per student question |

---

## Critical Indexes

```javascript
// MUST HAVE for performance:
SubmittedExercises._ensureIndex({owner:1, exerciseId:1})
SubmittedExercises._ensureIndex({owner:1})
HelpRequest._ensureIndex({requesterId:1, exerciseId:1})
GradedAnswers._ensureIndex({exerciseId:1})
```

---

## Core Relationships Cheat Sheet

```
Meteor.users._id
  └─> SubmittedExercises.owner (student submissions)
  └─> Subscriptions.owner (course enrollments)
  └─> ExerciseSets.owner (who created it)
  └─> HelpRequest.requesterId (who asked)
  └─> HelpRequest.answererId (who answered)
  └─> GradedAnswers.graderId (who graded)

Courses.name
  └─> ExerciseSets.courseName
  └─> Subscriptions.courseName

ExerciseSets._id
  └─> Subscriptions.exerciseSetId

SubmittedExercises.exerciseId
  └─> Matches ExerciseSet.lectures[].units[].rawExercises
  └─> Matches GradedAnswers.exerciseId (for auto-grading)

SubmittedExercises._id
  └─> HelpRequest.submittedExerciseId
```

---

## Field Reference Quick Lookup

### Must Know: SubmittedExercises
```javascript
{
  owner: ObjectId,              // Student who submitted
  exerciseId: String,           // What exercise (URL)
  answer: {
    content: {
      proof: String,            // Proof text (if proof ex)
      TorF: [Boolean],          // True/false answer (if TorF ex)
      dialectName: String       // Logic dialect (e.g., "PNF")
    }
  },
  humanFeedback: {
    isCorrect: Boolean,         // Tutor's verdict
    comment: String,            // Tutor's written feedback
    studentSeen: Boolean        // Student viewed it?
  },
  machineFeedback: {
    isCorrect: Boolean,         // Auto-grader result
    comment: String
  },
  created: Date                 // When submitted
}
```

### Must Know: HelpRequest
```javascript
{
  requesterId: ObjectId,        // Student asking
  exerciseId: String,           // Which exercise
  submittedExerciseId: ObjectId,// Link to their submission
  question: String,             // What they asked
  created: Date,                // When asked
  answer: String,               // Tutor's response (if any)
  dateAnswered: Date,           // When answered (if any)
  answererId: ObjectId,         // Who answered (if any)
  studentSeen: Date             // When student saw answer (if any)
}
```

### Must Know: ExerciseSets
```javascript
{
  courseName: String,           // Parent course
  variant: String,              // Difficulty level (normal/fast)
  owner: ObjectId,              // Creator (instructor)
  lectures: [{
    type: "lecture",
    name: String,               // e.g., "lecture_03"
    slides: String,             // URL
    units: [{
      type: "unit",
      name: String,
      rawExercises: [String]    // Exercise URLs
    }]
  }]
}
```

---

## Common Query Patterns

### Find student's submissions
```javascript
SubmittedExercises.find({owner: studentId})
// Index: owner
```

### Find answers needing grading
```javascript
SubmittedExercises.find({
  owner: {$in: tuteeIds},
  humanFeedback: {$exists: false},
  machineFeedback: {$exists: false}
})
// Index: owner
```

### Auto-grade a submission
```javascript
GradedAnswers.findOne({
  exerciseId: exId,
  answerHash: hash
})
// Index: exerciseId
```

### Get student's tutor's other students
```javascript
Meteor.users.find({
  'profile.seminar_tutor': tutorEmail
})
// Index: profile.seminar_tutor
```

### Find unseen feedback
```javascript
SubmittedExercises.find({
  owner: studentId,
  'humanFeedback.studentSeen': false
})
// Index: owner, humanFeedback.studentSeen
```

---

## Denormalized Fields (don't rely on these for CRUD)

- `SubmittedExercises.ownerName` - from Meteor.users.profile.name
- `SubmittedExercises.email` - from Meteor.users.emails[0].address
- `SubmittedExercises.answerPNFsimplifiedSorted` - computed hash
- `HelpRequest.answererName` - from Meteor.users.profile.name
- `HelpRequest.requesterTutorEmail` - from Meteor.users.profile.seminar_tutor

---

## Authorization Quick Check

```javascript
// Student can only see/modify their own:
if (userId !== submission.owner) throw new Error("not-authorized")

// Tutor can see student only if:
let studentTutorEmail = student.profile.seminar_tutor
let tutorEmails = tutor.emails.map(e => e.address)
if (!tutorEmails.includes(studentTutorEmail)) throw new Error("not-authorized")

// Can add human feedback only if:
let tutorEmail = tutor.emails[0].address
let studentTutorEmail = student.profile.seminar_tutor
if (tutorEmail !== studentTutorEmail) throw new Error("not-authorized")
```

---

## Update Strategy for Documents

| Document Type | How Updated | Authorization |
|---|---|---|
| Course | Full replace (rare) | Course creator only |
| ExerciseSet | Field updates | Owner only |
| SubmittedExercise | Upsert pattern (one per owner/exId) | Owner submits |
| humanFeedback | Merge (new fields/values added) | Assigned tutor only |
| machineFeedback | Set once (auto-graded) | System only |
| HelpRequest | Answer field set | Any authenticated user |
| GradedAnswers | Upsert (idempotent caching) | System via tutor action |

---

## Backup Priority

1. **CRITICAL** - SubmittedExercises (all student work)
2. **CRITICAL** - HelpRequest (student interactions)
3. **HIGH** - Subscriptions (enrollment records)
4. **HIGH** - GradedAnswers (grading history)
5. **MEDIUM** - ExerciseSets (instructor content)
6. **LOW** - Courses (reference data)

---

## Common Performance Issues & Fixes

| Issue | Symptom | Fix |
|---|---|---|
| No owner index | Tutor view slow | Ensure `SubmittedExercises._ensureIndex({owner:1})` |
| No composite index | Finding answers for student on exercise slow | Create `{owner:1, exerciseId:1}` |
| Large $in on tutor view | Dashboard loads slowly | Limit tuteeIds or paginate results |
| Accessing humanFeedback fields | Query planning slow | Index nested field `{owner:1, 'humanFeedback.studentSeen':1}` |
| Auto-grading lookup | Submission grading delayed | Index `GradedAnswers.exerciseId` |

---

## Migration Checklist

When deploying schema changes:

- [ ] Back up SubmittedExercises (most critical)
- [ ] Back up HelpRequest
- [ ] Test indexes with: `db.collection.getIndexes()`
- [ ] Verify authorization checks still work
- [ ] Check denormalized fields sync correctly
- [ ] Validate relationships in related collections
- [ ] Test auto-grading with existing GradedAnswers
- [ ] Confirm all Meteor.publish functions still work

