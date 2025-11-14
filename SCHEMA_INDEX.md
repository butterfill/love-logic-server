# Love Logic Server - MongoDB Schema Documentation Index

This directory contains comprehensive documentation of all MongoDB collections, indexes, relationships, and schema information for the love-logic-server project.

## Documentation Files

### 1. MONGODB_SCHEMA.md (32 KB)
**Comprehensive technical reference** - Read this for complete details

- **Collections Overview Table** - All 6 collections at a glance
- **Collection Details** - Full documentation for each collection:
  - Fields with data types, requirements, and purposes
  - Sample documents showing real structure
  - Constraints and validation rules
  - Indexes and default values
  - Relationships to other collections
  - Denormalization patterns
  
- **Collections Documented:**
  - Courses (course definitions)
  - ExerciseSets (exercise groupings by variant)
  - SubmittedExercises (student submissions + feedback)
  - Subscriptions (student course enrollments)
  - GradedAnswers (cached grading for auto-grading)
  - HelpRequest (help Q&A system)
  - Meteor.users (authentication & profiles)

- **Advanced Topics:**
  - Collection relationship diagrams and cardinality
  - Complete index listing with purposes
  - Denormalization patterns and update strategies
  - Computed fields and virtual properties
  - Authorization and access control rules
  - Publishing/subscription restrictions by role
  - Schema validation and constraints
  - Query performance considerations
  - Data growth projections

### 2. SCHEMA_QUICK_REFERENCE.md (7 KB)
**Developer cheat sheet** - Start here for quick lookups

- **Collections at a Glance** - Table with size risk assessment
- **Critical Indexes** - Must-have indexes for performance
- **Core Relationships** - Tree showing how collections link together
- **Field Reference** - Key fields for most important collections
- **Common Query Patterns** - Copy-paste ready code snippets
- **Denormalized Fields** - What NOT to rely on for consistency
- **Authorization Quick Check** - Copy-paste authorization patterns
- **Update Strategy** - How each document type is modified
- **Backup Priority** - What to prioritize when backing up
- **Performance Issues & Fixes** - Common problems and solutions
- **Migration Checklist** - Steps when deploying schema changes

---

## Getting Started

### For Immediate Understanding:
1. Start with **SCHEMA_QUICK_REFERENCE.md**
2. Look at "Collections at a Glance" table
3. Check "Core Relationships Cheat Sheet"
4. Find your collection in "Field Reference Quick Lookup"

### For Complete Implementation:
1. Read the corresponding section in **MONGODB_SCHEMA.md**
2. Review constraints and validation rules
3. Check indexes and performance considerations
4. Study authorization patterns from "Authorization and Access Control Rules"

### For Debugging/Performance:
1. Consult **SCHEMA_QUICK_REFERENCE.md** "Common Performance Issues & Fixes"
2. Verify indexes are created with `db.collection.getIndexes()`
3. Check authorization rules in "Authorization Quick Check"
4. Review query patterns in "Common Query Patterns"

---

## Quick Facts

### Collection Sizes (Expected)
- **Courses:** ~10-50 documents (grows rarely)
- **ExerciseSets:** ~50-200 documents (controlled by instructors)
- **SubmittedExercises:** **High growth** (one per student submission)
- **Subscriptions:** ~1 per student per course variant
- **GradedAnswers:** Medium (capped by unique answers)
- **HelpRequest:** Medium (one per student question)

### Critical Data (Backup Priority)
1. **SubmittedExercises** - All student work
2. **HelpRequest** - Student interactions
3. **Subscriptions** - Enrollment records
4. **GradedAnswers** - Grading history
5. ExerciseSets - Course content
6. Courses - Reference data

### Key Relationships
- Every SubmittedExercise belongs to exactly one student (owner)
- Every HelpRequest belongs to exactly one student (requesterId)
- Every Subscription represents one student following one exercise set
- Every ExerciseSet belongs to exactly one course (courseName)
- GradedAnswers are indexed by exercise and answer hash

---

## Collection File Locations in Code

The collections are defined in these CoffeeScript files:

```
/home/user/love-logic-server/love-logic-server/
├── love-logic.coffee              # Main definitions: SubmittedExercises, Subscriptions, GradedAnswers, HelpRequest
├── lib/
│   └── exercise-collection.coffee # Courses and ExerciseSets definitions
└── server/
    └── publish.coffee             # All indexes and Meteor.publish definitions
```

---

## Key Methods by Purpose

### Student Submission
- `submitExercise()` - Student submits answer (uses upsert pattern)
- `subscribeToExerciseSet()` - Student enrolls in course variant
- `studentSeenFeedback()` - Mark feedback as viewed
- `createHelpRequest()` - Ask for help on exercise

### Tutor Grading
- `addHumanFeedback()` - Provide feedback (requires authorization check)
- `addGradedExercise()` - Cache answer for auto-grading (upsert)
- `answerHelpRequest()` - Answer student question
- `getExercisesToGrade()` - Get list of exercises needing attention

### Course/Exercise Management
- `createNewCourse()` - Create course
- `createNewExerciseSet()` - Create exercise set
- `upsertExerciseSet()` - Update exercise set (merge pattern)

### Instructor Operations
- `makeMeATutor()` / `makeMeNotATutor()` - Change role
- `updateSeminarTutor()` - Assign tutor to student
- `updateInstructor()` - Assign instructor to tutor

---

## Authorization Model

### Roles:
- **Student:** Can submit exercises, request help, view own progress
- **Seminar Tutor:** Can grade tutees' exercises, answer help requests, view tutees' progress
- **Instructor:** Can create courses/exercises, manage tutors under them

### Access Control Pattern:
```javascript
// Most operations check:
if (userId !== submission.owner) throw new Error("not-authorized")

// Tutor operations check:
let studentTutorEmail = student.profile.seminar_tutor
if (!tutor.emails.map(e => e.address).includes(studentTutorEmail)) 
  throw new Error("not-authorized")
```

---

## Important Notes

### Upsert vs Insert
- **SubmittedExercises:** Uses `findAndModify` with `upsert: true` - only ONE submission per (owner, exerciseId)
- **GradedAnswers:** Uses `findAndModify` with `upsert: true` - only ONE grade per (exerciseId, ownerIdHash, answerHash)
- **Other collections:** Use regular insert operations

### Denormalization
The system maintains several denormalized fields for performance:
- `SubmittedExercises.ownerName` and `.email` from Meteor.users
- `HelpRequest.answererName` and `.requesterTutorEmail` 
- `GradedAnswers.answer.content` with dialect info

These are **read-only** for consistency - don't update them directly.

### Email-based Relationships
Student-tutor relationships are tracked via email addresses:
- Student has `profile.seminar_tutor` = tutor's email
- Used to find all students of a tutor with query: `{profile.seminar_tutor: tutorEmail}`

---

## Schema Version Information

**Current Schema Version:** As of 2015 (from code copyright)

**Key Fields That May Evolve:**
- `answer.content` structure varies by exercise type (proof, TorF, etc.)
- `humanFeedback` and `machineFeedback` structures are flexible objects
- New dialect versions tracked in `answer.content.dialectVersion`

---

## Contact & Questions

For questions about:
- **Field meanings:** Check "Collection Details" in MONGODB_SCHEMA.md
- **Relationships:** See "Relationships Between Collections" section
- **Performance:** Check "Common Performance Issues & Fixes" in SCHEMA_QUICK_REFERENCE.md
- **Authorization:** See "Authorization and Access Control Rules" in MONGODB_SCHEMA.md
- **Indexes:** List in MONGODB_SCHEMA.md or create with `_ensureIndex()` calls from server/publish.coffee

---

**Documentation Generated:** November 14, 2025
**Project:** love-logic-server (Meteor.js + MongoDB)
**Status:** Complete coverage of all 6 custom collections + Meteor.users
