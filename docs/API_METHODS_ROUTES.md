# Love Logic Server - API Methods, Routes, and Publications

**Last Updated:** 2025-11-23
**Project:** love-logic-server (Meteor.js + FlowRouter)

This document provides a comprehensive reference for all Meteor Methods (API endpoints), FlowRouter Routes (client-side navigation), and Meteor Publications (subscription channels) in the love-logic-server project.

---

## TABLE OF CONTENTS

1. [Meteor Methods (API Endpoints)](#part-1-meteor-methods)
2. [FlowRouter Routes](#part-2-flowrouter-routes)
3. [Meteor Publications (Subscriptions)](#part-3-meteor-publications)

---

# PART 1: METEOR METHODS

Meteor Methods are the equivalent of API endpoints in this application. They are RPC calls that can be invoked from the client and execute on the server. All methods include both client-side simulation and server-side verification.

## User Profile Management Methods

### Method: `seminarTutorExists`
**Location:** love-logic.coffee (line 29)

**Parameters:**
- `emailAddress` (String): Email address to check

**Authorization:** None required (public method)

**Purpose:** Check if a user with the given email address exists and is marked as a seminar tutor.

**Return Value:** Boolean - `true` if a seminar tutor with that email exists, `false` otherwise

**Business Logic:**
- Queries the Meteor.users collection
- Looks for users with matching email (case-sensitive)
- Checks if their profile has `is_seminar_tutor` set to true
- Uses a count check to return boolean

**Side Effects:** None (read-only)

**Error Conditions:** None

---

### Method: `updateSeminarTutor`
**Location:** love-logic.coffee (line 32)

**Parameters:**
- `emailAddress` (String): Email address of the seminar tutor to assign to the current user

**Authorization:** Requires authenticated user (`Meteor.user()`)

**Purpose:** Assign a seminar tutor to the currently logged-in user by email address.

**Return Value:** `undefined` on client simulation; nothing returned on server

**Business Logic:**
1. Gets the current user's ID
2. Validates that the user is authenticated
3. On client: returns undefined (no simulation)
4. On server:
   - Case-insensitive search for a registered seminar tutor with that email
   - Validates that exactly one tutor is found
   - Updates the current user's profile with `seminar_tutor` field set to the tutor's email
   - Preserves the original casing of the tutor's email from the database

**Side Effects:** Modifies the current user's `profile.seminar_tutor` field

**Error Conditions:**
- `not-authorized`: User is not logged in
- `No tutor is registered with that email address`: Email not found or user is not a seminar tutor

---

### Method: `updateInstructor`
**Location:** love-logic.coffee (line 47)

**Parameters:**
- `emailAddress` (String): Email address of the instructor to assign to the current user

**Authorization:** Requires authenticated user

**Purpose:** Assign an instructor to the currently logged-in user.

**Return Value:** `undefined` on client simulation; nothing returned on server

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. On client: returns undefined
4. On server:
   - Queries for users with the given email marked as instructors (`profile.is_instructor:true`)
   - Updates current user's profile with `instructor` field

**Side Effects:** Modifies the current user's `profile.instructor` field

**Error Conditions:**
- `not-authorized`: User is not logged in
- `No instructor is registered with that email address`: Email not found or user is not an instructor

---

### Method: `updateEmailAddress`
**Location:** love-logic.coffee (line 59)

**Parameters:**
- `emailAddress` (String): New email address for the user

**Authorization:** Requires authenticated user

**Purpose:** Update the current user's email address.

**Return Value:** `undefined` on client simulation; nothing returned on server

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. On client: returns undefined
4. On server:
   - Case-insensitive check that the new email is not already in use
   - Validates that no other user has this email
   - Updates the user's emails array with one entry containing the new address (marked as unverified)

**Side Effects:** Modifies the current user's `emails` array

**Error Conditions:**
- `not-authorized`: User is not logged in
- `That email address is already is use`: Email already exists for another user (note: typo "is use" in original code)

---

### Method: `makeMeATutor`
**Location:** love-logic.coffee (line 75)

**Parameters:** None

**Authorization:** Requires authenticated user

**Purpose:** Register the current user as a seminar tutor.

**Return Value:** Nothing

**Business Logic:**
- Sets `profile.is_seminar_tutor` to true on the current user

**Side Effects:** Modifies current user's `profile.is_seminar_tutor` to `true`

**Error Conditions:**
- `not-authorized`: User is not logged in

---

### Method: `makeMeNotATutor`
**Location:** love-logic.coffee (line 81)

**Parameters:** None

**Authorization:** Requires authenticated user

**Purpose:** Unregister the current user as a seminar tutor.

**Return Value:** Nothing

**Business Logic:**
- Sets `profile.is_seminar_tutor` to false

**Side Effects:** Modifies current user's `profile.is_seminar_tutor` to `false`

**Error Conditions:**
- `not-authorized`: User is not logged in

---

### Method: `makeMeAnInstructor`
**Location:** love-logic.coffee (line 87)

**Parameters:** None

**Authorization:** Requires authenticated user

**Purpose:** Register the current user as an instructor.

**Return Value:** Nothing

**Business Logic:**
- Sets `profile.is_instructor` to true

**Side Effects:** Modifies current user's `profile.is_instructor` to `true`

**Error Conditions:**
- `not-authorized`: User is not logged in

---

### Method: `makeMeNotAnInstructor`
**Location:** love-logic.coffee (line 93)

**Parameters:** None

**Authorization:** Requires authenticated user

**Purpose:** Unregister the current user as an instructor.

**Return Value:** Nothing

**Business Logic:**
- Sets `profile.is_instructor` to false

**Side Effects:** Modifies current user's `profile.is_instructor` to `false`

**Error Conditions:**
- `not-authorized`: User is not logged in

---

## Course Management Methods

### Method: `createNewCourse`
**Location:** love-logic.coffee (line 99)

**Parameters:**
- `name` (String): Course name (must be URL-encoded)
- `description` (String): Course description

**Authorization:** Requires authenticated user with valid email address

**Purpose:** Create a new course.

**Return Value:** Object with properties:
```coffeescript
{
  name: String (course name as stored)
  course: String (MongoDB _id of the created course)
}
```

**Business Logic:**
1. Validates that the course name is URL-encoded
2. Gets the current user's email domain (from email after @)
3. Creates a prefix from the email domain (URL-encoded)
4. Prepends the prefix to the course name if not already present
5. Checks that the course name doesn't already exist
6. Inserts new course document into Courses collection
7. Returns the generated course name and ID

**Side Effects:** 
- Inserts new document into Courses collection
- Course is created with the email domain as a prefix

**Error Conditions:**
- `illegal characters in name`: Course name contains characters that aren't URL-encoded
- `not-authorized`: User not logged in or has no email address
- `already exists`: A course with that name already exists

---

### Method: `deleteCourse`
**Location:** love-logic.coffee (line 116)

**Parameters:**
- `name` (String): Name of the course to delete

**Authorization:** Requires authenticated user

**Purpose:** Delete a course from the system.

**Return Value:** Nothing

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. Queries for the course by name
4. Validates exactly one course is found
5. Checks that the course has no associated exercise sets
6. Removes the course document

**Side Effects:** Removes course from Courses collection

**Error Conditions:**
- `not-authorized`: User is not logged in
- `cannot find it (count: X)`: Course not found or multiple matches
- `has exercise sets`: Course has associated exercise sets (must delete those first)

---

## Exercise Set Management Methods

### Method: `showExerciseSet`
**Location:** love-logic.coffee (line 129)

**Parameters:**
- `exerciseSetId` (String): MongoDB ID of the exercise set

**Authorization:** Requires authenticated user who owns the exercise set

**Purpose:** Make an exercise set visible to students.

**Return Value:** Nothing

**Business Logic:**
1. Gets current user's ID
2. Queries for the exercise set
3. Validates ownership (user must be the owner)
4. Sets `hidden: false`

**Side Effects:** Modifies exercise set's `hidden` field to `false`

**Error Conditions:**
- `not-authorized`: User is not logged in
- `cannot find it`: Exercise set not found
- `not-authorized: not yours`: User does not own the exercise set

---

### Method: `hideExerciseSet`
**Location:** love-logic.coffee (line 141)

**Parameters:**
- `exerciseSetId` (String): MongoDB ID of the exercise set

**Authorization:** Requires authenticated user who owns the exercise set

**Purpose:** Hide an exercise set from students.

**Return Value:** Nothing

**Business Logic:**
1. Gets current user's ID
2. Queries for the exercise set
3. Validates ownership
4. Sets `hidden: true`

**Side Effects:** Modifies exercise set's `hidden` field to `true`

**Error Conditions:**
- `not-authorized`: User is not logged in
- `cannot find it`: Exercise set not found
- `not-authorized: not yours`: User does not own the exercise set

---

### Method: `createNewExerciseSet`
**Location:** love-logic.coffee (line 153)

**Parameters:**
- `courseName` (String): Course name (URL-encoded)
- `variant` (String): Exercise set variant name (URL-encoded)
- `description` (String): Exercise set description

**Authorization:** Requires authenticated user

**Purpose:** Create a new exercise set within a course.

**Return Value:** Object with properties:
```coffeescript
{
  courseName: String
  exerciseSet: String (MongoDB _id of the created exercise set)
}
```

**Business Logic:**
1. Validates that both courseName and variant are URL-encoded
2. Gets current user's ID
3. Checks that no exercise set with this courseName + variant combination already exists
4. Creates new exercise set document with:
   - owner: current user's ID
   - courseName, variant, description
   - empty lectures array
   - created timestamp
5. Inserts into ExerciseSets collection

**Side Effects:** Inserts new document into ExerciseSets collection

**Error Conditions:**
- `illegal characters in name`: Name or variant not properly URL-encoded
- `not-authorized`: User is not logged in
- `already exists`: Exercise set with this courseName+variant already exists

---

### Method: `pasteExerciseSet`
**Location:** love-logic.coffee (line 172)

**Parameters:**
- `newExSet` (Object): Exercise set object containing:
  - `courseName` (String): URL-encoded course name
  - `variant` (String): URL-encoded variant name
  - `description` (String)
  - `lectures` (Array): Array of lectures to copy

**Authorization:** Requires authenticated user

**Purpose:** Create a new exercise set with copied lectures from another set.

**Return Value:** Object with properties:
```coffeescript
{
  courseName: String
  exerciseSet: String (MongoDB _id of the created exercise set)
}
```

**Business Logic:**
1. Validates URL encoding of courseName and variant
2. Gets current user's ID
3. Checks no existing exercise set with this courseName + variant
4. Creates new exercise set with provided lectures array (copies them)
5. Sets owner to current user and created timestamp
6. Inserts into ExerciseSets collection

**Side Effects:** Inserts new document into ExerciseSets collection with copied lectures

**Error Conditions:**
- `illegal characters in name`: Name or variant not properly URL-encoded
- `not-authorized`: User is not logged in
- `already exists`: Exercise set with this courseName+variant already exists

---

### Method: `deleteExerciseSet`
**Location:** love-logic.coffee (line 191)

**Parameters:**
- `courseName` (String): Course name
- `variant` (String): Variant name

**Authorization:** Requires authenticated user who owns the exercise set

**Purpose:** Delete an exercise set.

**Return Value:** Nothing

**Business Logic:**
1. Gets current user's ID
2. Queries for the exercise set by courseName + variant
3. Validates ownership
4. Checks that the exercise set has no lectures
5. Removes the exercise set

**Side Effects:** Removes document from ExerciseSets collection

**Error Conditions:**
- `not-authorized`: User is not logged in
- `cannot find it (count: X)`: Exercise set not found or multiple matches
- `not-authorized: not yours`: User does not own the exercise set
- `has lectures`: Exercise set contains lectures (must delete those first)

---

### Method: `upsertExerciseSet`
**Location:** love-logic.coffee (line 352)

**Parameters:**
- `exerciseSet` (Object): Exercise set object with properties:
  - `courseName` (String): Required
  - `variant` (String): Required
  - `description` (String)
  - `lectures` (Array): Array of lectures
  - `owner` (String): Optional, must match current user if provided

**Authorization:** Requires authenticated user. If owner is specified, must match current user.

**Purpose:** Create a new exercise set or update an existing one (insert or update).

**Return Value:** 
- For insert: MongoDB _id of the inserted document
- For update: result of the update operation

**Business Logic:**
1. Gets current user's ID
2. Validates that either no owner is specified or the owner matches the current user
3. Checks that courseName and variant are provided
4. Queries for an existing exercise set with this courseName + variant
5. If not found (INSERT case):
   - Sets owner to current user
   - Sets created timestamp
   - Inserts the document
6. If found (UPDATE case):
   - Validates that current user owns it
   - Updates only the description and lectures fields

**Side Effects:** 
- Inserts new document into ExerciseSets collection (if not exists)
- Updates existing exercise set (if exists)

**Error Conditions:**
- `not-authorized`: User is not logged in
- `not-authorized`: exerciseSet.owner specified and doesn't match current user
- `Exercise sets must have 'courseName' and 'variant' properties.`: Missing required fields
- `You cannot update this exercise set because you do not own it.`: Trying to update exercise set owned by another user

---

### Method: `updateExerciseSetField`
**Location:** love-logic.coffee (line 370)

**Parameters:**
- `exerciseSet` (Object): Exercise set object with `_id` property
- `toSet` (Object): Fields to update (MongoDB $set format)

**Authorization:** Requires authenticated user who owns the exercise set

**Purpose:** Update specific fields of an exercise set.

**Return Value:** Result of the update operation

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. Validates ownership (if owner field is specified in exerciseSet, it must match)
4. Updates the specified fields using MongoDB $set operator

**Side Effects:** Modifies exercise set document in ExerciseSets collection

**Error Conditions:**
- `not-authorized`: User is not logged in
- `not-authorized`: exerciseSet.owner specified and doesn't match current user

---

### Method: `exerciseSetHasFollowers`
**Location:** love-logic.coffee (line 376)

**Parameters:**
- `courseName` (String): Course name
- `variant` (String): Variant name

**Authorization:** None required (public method)

**Purpose:** Check if any students are subscribed to this exercise set.

**Return Value:** Boolean - `true` if followers exist, `false` otherwise

**Business Logic:**
- Queries the Subscriptions collection for entries matching courseName + variant
- Returns true if at least one subscription exists

**Side Effects:** None (read-only)

**Error Conditions:** None

---

## Exercise Submission and Grading Methods

### Method: `submitExercise`
**Location:** love-logic.coffee (line 205)

**Parameters:**
- `exercise` (Object): Exercise submission object containing:
  - `exerciseId` (String): ID of the exercise
  - `answer` (Object): The student's answer structure
    - `content` (Mixed): The actual answer data (string, object, etc.)
    - `dialectName` (String, Optional): The logic dialect (e.g., 'lpl') injected by the client
    - `dialectVersion` (String, Optional): Version of the dialect
  - `machineFeedback` (Object, Optional): Pre-calculated machine grading results
  - Must NOT contain `userId` field

**Authorization:** Requires authenticated user

**Purpose:** Submit a student's response to an exercise.

**Return Value:** `undefined` on client; nothing returned on server

**Business Logic:**
1. Gets current user's ID
2. Validates that the submission doesn't already contain a userId
3. On client: returns undefined (no optimistic update)
4. On server:
   - Adds userId (owner), ownerName (from profile), email, and created timestamp
   - Uses findAndModify for atomic upsert operation
   - Updates if owner + exerciseId match and human feedback doesn't exist
   - Creates new document otherwise

**Side Effects:** 
- Inserts or updates documents in SubmittedExercises collection
- Each student can only have one submission per exercise (unless already graded by human)

**Error Conditions:**
- `not-authorized`: User is not logged in
- `not-authorized`: Submission already contains userId field

**Notes:** 
- If an exercise has already been graded by a human, it won't be updated
- This allows students to improve answers before human grading
- The client injects dialect information into the answer object; this is critical for the logic engine to parse the answer correctly later.

---

### Method: `getCorrectAnswer`
**Location:** love-logic.coffee (line 231)

**Parameters:**
- `exerciseId` (String): ID of the exercise

**Authorization:** Requires authenticated user (implicitly, for context)

**Purpose:** Get a correctly-answered response to the same exercise from another student.

**Return Value:** 
- Object containing `answer` field from a correct submission
- `undefined` if no correct answer found

**Business Logic:**
1. Gets current user's ID
2. Queries for submitted exercises where:
   - exerciseId matches
   - Has either human feedback marked as correct OR machine feedback marked as correct
   - owner is NOT the current user (don't show own answers)
3. Returns only the answer field
4. Limits to 1 result

**Side Effects:** None (read-only)

**Error Conditions:** None

---

### Method: `addHumanFeedback`
**Location:** love-logic.coffee (line 268)

**Parameters:**
- `submission` (Object): The submitted exercise object (with _id and owner)
- `humanFeedback` (Object): Feedback object containing:
  - `isCorrect` (Boolean)
  - `comment` (String): Optional feedback/comments

**Authorization:** 
- Requires authenticated user
- User must be the seminar tutor of the student who submitted

**Purpose:** Add human (tutor) feedback/grading to a student submission.

**Return Value:** Result of the update operation

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. On server only:
   - Fetches the original submission from database
   - Validates the owner hasn't changed (security check)
   - Fetches the owner's profile to get their seminar_tutor email
   - Validates that the current user is that tutor
4. Sets `studentSeen: false` on the feedback (student hasn't seen it yet)
5. Updates the submission with the human feedback

**Side Effects:** 
- Modifies SubmittedExercises document
- Adds humanFeedback object with studentSeen flag

**Error Conditions:**
- `not-authorized`: User is not logged in
- `The owner (author) of a submitted exercise may not be changed.`: Document owner changed (tampering detection)
- `not-authorized (no supervisor for this student)`: Student has no assigned seminar tutor
- `not-authorized (not the supervisor of this student)`: Current user is not the student's tutor

---

### Method: `studentSeenFeedback`
**Location:** love-logic.coffee (line 287)

**Parameters:**
- `exercise` (Object): The submitted exercise object with owner and _id

**Authorization:** Requires authenticated user who owns the submission

**Purpose:** Mark feedback as seen by the student.

**Return Value:** Result of the update operation

**Business Logic:**
1. Gets current user's ID
2. Validates that current user is the owner of the submission
3. Sets `humanFeedback.studentSeen: true` and `humanFeedback.studentEverSeen: true`

**Side Effects:** Modifies SubmittedExercises document

**Error Conditions:**
- `not-authorized`: User is not logged in or doesn't own the submission

---

### Method: `addGradedExercise`
**Location:** love-logic.coffee (line 318)

**Parameters:**
- `exerciseId` (String): Exercise ID
- `ownerIdHash` (String): Hash of the owner's ID (for privacy/anonymity)
- `answerHash` (String): Hash of the answer
- `isCorrect` (Boolean): Whether the answer is correct
- `comment` (String): Optional grading comment
- `answerPNFsimplifiedSorted` (String): Optional processed answer representation
- `dialectName` (String, Optional): Logic dialect used
- `dialectVersion` (String, Optional): Dialect version

**Authorization:** Requires authenticated user

**Purpose:** Store grading results for an exercise answer so that other students with the same answer can be auto-graded.

**Return Value:** `undefined` on client; nothing returned on server

**Business Logic:**
1. Gets current user's ID (grader)
2. Validates authentication
3. Creates document with exercise, owner, and answer hashes
4. Includes grader ID for accountability
5. On client: returns undefined
6. On server:
   - Uses findAndModify for atomic upsert
   - Allows one graded result per unique exerciseId + ownerIdHash + answerHash combination
   - Auto-grading will match students against these stored results

**Side Effects:** Inserts or updates documents in GradedAnswers collection

**Error Conditions:**
- `not-authorized`: User is not logged in

**Notes:**
- The comment "TODO create unique composite index" indicates the system should have a compound unique index on (exerciseId, ownerIdHash, answerHash)

---

### Method: `_removeGradedExercises`
**Location:** love-logic.coffee (line 349)

**Parameters:**
- `exerciseId` (String): Exercise ID

**Authorization:** None explicitly checked (testing method)

**Purpose:** Remove all graded answers for an exercise (testing utility).

**Return Value:** Result of the remove operation

**Business Logic:**
- Removes all documents from GradedAnswers where exerciseId matches

**Side Effects:** Deletes documents from GradedAnswers collection

**Error Conditions:** None

**Notes:** This method is marked as "currently only used for testing" and should probably be restricted to admins

---

## Exercise Set Subscription Methods

### Method: `subscribeToExerciseSet`
**Location:** love-logic.coffee (line 244)

**Parameters:**
- `courseName` (String): Course name
- `variant` (String): Exercise set variant
- `exerciseSetId` (String): MongoDB ID of the exercise set

**Authorization:** Requires authenticated user

**Purpose:** Subscribe a student to an exercise set (start following it).

**Return Value:** Nothing

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. Checks if user is already subscribed to this courseName + variant combination
4. If already subscribed, throws error
5. Creates new subscription document with owner, courseName, variant, exerciseSetId, and created timestamp
6. Inserts into Subscriptions collection

**Side Effects:** Inserts new document into Subscriptions collection

**Error Conditions:**
- `not-authorized`: User is not logged in
- `You are already following 'variant' on courseName.`: User already subscribed

---

### Method: `unsubscribeToExerciseSet`
**Location:** love-logic.coffee (line 259)

**Parameters:**
- `courseName` (String): Course name
- `variant` (String): Exercise set variant

**Authorization:** Requires authenticated user

**Purpose:** Unsubscribe from an exercise set (stop following it).

**Return Value:** Nothing

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. Queries for subscription matching owner + courseName + variant
4. If no subscription found, throws error
5. Removes the subscription document

**Side Effects:** Removes document from Subscriptions collection

**Error Conditions:**
- `not-authorized`: User is not logged in
- `You aren't following 'variant' on courseName.`: No subscription found to remove

---

## Help Request Methods

### Method: `createHelpRequest`
**Location:** love-logic.coffee (line 300)

**Parameters:**
- `doc` (Object): Help request object containing:
  - `exerciseId` (String): ID of the exercise needing help
  - Other request details

**Authorization:** Requires authenticated user

**Purpose:** Submit a help request for an exercise.

**Return Value:** MongoDB _id of the created help request

**Business Logic:**
1. Gets current user's ID (requester)
2. Validates authentication
3. Adds requester ID to the request
4. If requester has a seminar tutor assigned, adds `requesterTutorEmail`
5. Sets created timestamp
6. Inserts into HelpRequest collection

**Side Effects:** Inserts new document into HelpRequest collection

**Error Conditions:**
- `not-authorized`: User is not logged in

---

### Method: `answerHelpRequest`
**Location:** love-logic.coffee (line 310)

**Parameters:**
- `helpReq` (Object): Help request object with _id
- `answer` (String): The answer/solution to the help request

**Authorization:** Requires authenticated user (anyone can answer)

**Purpose:** Provide an answer to a help request.

**Return Value:** Result of the update operation

**Business Logic:**
1. Gets current user's ID (answerer)
2. Validates authentication
3. Gets current user's name from profile
4. Updates the help request with:
   - dateAnswered: current timestamp
   - answererId: current user's ID
   - answer: the provided answer
   - answererName: user's name from profile

**Side Effects:** Modifies HelpRequest document

**Error Conditions:**
- `not-authorized`: User is not logged in

**Notes:** 
- Any authenticated user can answer (no tutor restriction)
- Previous answers would be overwritten if called multiple times

---

### Method: `studentSeenHelpRequestAnswer`
**Location:** love-logic.coffee (line 293)

**Parameters:**
- `helpReq` (Object): Help request object with requesterId and _id

**Authorization:** Requires authenticated user who created the help request

**Purpose:** Mark a help request answer as seen by the student.

**Return Value:** Result of the update operation

**Business Logic:**
1. Gets current user's ID
2. Validates that the current user is the requester
3. Sets `studentSeen` field to current timestamp

**Side Effects:** Modifies HelpRequest document

**Error Conditions:**
- `not-authorized`: User is not logged in or is not the requester

---

## Data Retrieval Methods (for Tutors/Instructors)

### Method: `getExercisesToGrade`
**Location:** love-logic.coffee (line 384)

**Parameters:**
- `limitToSubscribersToThisExerciseSet` (Object, optional): Object with `courseName` and `variant` properties
  - If provided, only returns exercises from students subscribed to this exercise set
  - If omitted, returns all exercises from the tutor's students

**Authorization:** Requires authenticated user

**Purpose:** Get a list of exercises that need grading for the tutor's students.

**Return Value:** Array of objects with `exerciseId` field

**Business Logic:**
1. Gets current user's ID
2. Validates authentication
3. On server only:
   - Gets the tutor's email address
   - Gets all student IDs who have this user as their seminar tutor
   - If `limitToSubscribersToThisExerciseSet` provided:
     - Gets the exercise set ID
     - Filters to only students subscribed to that exercise set
4. Uses MongoDB aggregation pipeline to find exercises needing feedback:
   - Matches submissions from the tutor's students
   - Filters to submissions where EITHER:
     - No human feedback AND no machine feedback (totally ungraded)
     - OR machine feedback says false AND no human feedback (auto-graded as wrong)
5. Groups by exerciseId and returns unique exercise IDs

**Side Effects:** None (read-only)

**Error Conditions:**
- `not-authorized`: User is not logged in
- Returns empty array if tutor has no email or no students

---

### Method: `nofHelpRequestsForTutor`
**Location:** love-logic.coffee (line 421)

**Parameters:** None

**Authorization:** Requires authenticated user

**Purpose:** Get count of unanswered help requests from the tutor's students.

**Return Value:** Integer count of unanswered help requests

**Business Logic:**
1. On client: returns 99 (hardcoded for UI simulation)
2. On server:
   - Gets tutor's email address
   - Gets IDs of all students with this tutor
   - Counts help requests where:
     - Requester is one of the tutor's students
     - No answer has been provided yet

**Side Effects:** None (read-only)

**Error Conditions:** Returns 0 if tutor has no email or no students

---

## Statistics Methods

### Method: `getNofUsers`
**Location:** love-logic.coffee (line 434)

**Parameters:** None

**Authorization:** Requires authenticated user (implicitly)

**Purpose:** Get total number of users in the system.

**Return Value:** Integer count of users

**Business Logic:**
- On client: returns undefined
- On server: returns count of all documents in Meteor.users collection

**Side Effects:** None (read-only)

---

### Method: `getNofUsersWithSeminarTutor`
**Location:** love-logic.coffee (line 438)

**Parameters:**
- `emailDomain` (String, optional): Email domain to filter by

**Authorization:** Requires authenticated user (implicitly)

**Purpose:** Count users who have a seminar tutor assigned, optionally filtered by domain.

**Return Value:** Integer count

**Business Logic:**
- On client: returns undefined
- On server:
  - If emailDomain provided: counts users where `profile.seminar_tutor` matches that domain as a regex
  - If emailDomain not provided: counts all users where `profile.seminar_tutor` is not null

**Side Effects:** None (read-only)

---

### Method: `getNofSubmittedExercises`
**Location:** love-logic.coffee (line 445)

**Parameters:** None

**Authorization:** Requires authenticated user (implicitly)

**Purpose:** Get total number of exercise submissions.

**Return Value:** Integer count

**Business Logic:**
- On client: returns undefined
- On server: returns count of all documents in SubmittedExercises collection

**Side Effects:** None (read-only)

---

### Method: `getNofSubmittedExercisesNoResubmits`
**Location:** love-logic.coffee (line 449)

**Parameters:** None

**Authorization:** Requires authenticated user (implicitly)

**Purpose:** Get count of unique student+exercise combinations (ignoring resubmissions).

**Return Value:** Integer count

**Business Logic:**
- On client: returns undefined
- On server:
  - Groups submissions by (exerciseId, owner) combination
  - Then groups to count unique combinations
  - Returns the total count

**Side Effects:** None (read-only)

---

### Method: `resetTester`
**Location:** love-logic.coffee (line 459)

**Parameters:** None

**Authorization:** Implicitly restricted (finds specific test user)

**Purpose:** Remove all test submissions for the 'tester' user account.

**Return Value:** `true` if successful

**Business Logic:**
1. On client: returns undefined
2. On server:
   - Finds the user with profile.name === 'tester'
   - Removes all SubmittedExercises owned by that user
   - Returns true

**Side Effects:** Deletes documents from SubmittedExercises collection

**Error Conditions:**
- `Could not find tester's id!`: The test user doesn't exist

---

# PART 2: FLOWROUTER ROUTES

FlowRouter provides client-side routing in the Meteor application. Each route renders a specific template and is typically backed by Meteor subscriptions and methods.

## Route Structure

Each route definition includes:
- **URL Pattern**: The URL path with optional parameters (prefixed with `:_`)
- **Template**: The Blaze template rendered
- **Layout**: ApplicationLayout (main wrapper)
- **Purpose**: What the page displays/does
- **Typical Subscriptions**: Data subscriptions needed (from publish.coffee)
- **Typical Methods**: Methods called on this route

---

## General/Administrative Routes

### Route: `/` (Root/Home)
- **URL Pattern:** `/`
- **Renders:** `main` template
- **Purpose:** Main dashboard/home page

---

### Route: `/termsOfUse`
- **URL Pattern:** `/termsOfUse`
- **Route Name:** `termsOfUse`
- **Renders:** `termsOfUse` template
- **Purpose:** Display terms of use/legal information

---

### Route: `/iAmATutor`
- **URL Pattern:** `/iAmATutor`
- **Route Name:** `iAmATutor`
- **Renders:** `iAmATutor` template
- **Purpose:** Page for users to register as tutors

---

### Route: `/iAmHonestlyReallyAndTrulyAnInstructor`
- **URL Pattern:** `/iAmHonestlyReallyAndTrulyAnInstructor`
- **Route Name:** `iAmHonestlyReallyAndTrulyAnInstructor`
- **Renders:** `iAmHonestlyReallyAndTrulyAnInstructor` template
- **Purpose:** Page for users to register as instructors

---

### Route: `/exploreZoxiy`
- **URL Pattern:** `/exploreZoxiy`
- **Route Name:** `exploreZoxiy`
- **Renders:** `exploreZoxiy` template
- **Purpose:** Explore/browse exercises

---

### Route: `/oldBrowserSorry`
- **URL Pattern:** `/oldBrowserSorry`
- **Route Name:** `oldBrowserSorry`
- **Renders:** `oldBrowserSorry` template
- **Purpose:** Message for users with old browsers

---

### Route: `/testThrowException`
- **URL Pattern:** `/testThrowException`
- **Renders:** `testThrowException` template
- **Purpose:** Testing route for exception handling

---

### Route: `/notFound` (Fallback)
- **Pattern:** Any unmatched route
- **Renders:** `routeNotFound` template
- **Purpose:** 404 error page for undefined routes

---

## Course Management Routes

### Route: `/courses`
- **URL Pattern:** `/courses`
- **Renders:** `courses` template
- **Purpose:** List available courses for the user
- **Typical Subscriptions:** 
  - `courses`: All non-hidden courses
- **Parameters:** None

---

### Route: `/course/:_courseName`
- **URL Pattern:** `/course/:_courseName`
- **Route Name:** `courseDetail`
- **Renders:** `exerciseSetsForCourse` template
- **Purpose:** Display exercise sets for a specific course
- **Parameters:**
  - `_courseName` (String): Name of the course (URL-encoded)
- **Typical Subscriptions:**
  - `course`: Single course data
  - `exercise_sets`: Exercise sets for this course

---

## Exercise Set Routes

### Route: `/course/:_courseName/exerciseSet/:_variant`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant`
- **Renders:** `exerciseSet` template
- **Purpose:** Browse exercises in an exercise set
- **Parameters:**
  - `_courseName` (String): Course name
  - `_variant` (String): Exercise set variant name
- **Typical Subscriptions:**
  - `exercise_set`: Specific exercise set details

---

### Route: `/course/:_courseName/exerciseSet/:_variant/edit`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/edit`
- **Renders:** `exerciseSetEdit` template
- **Purpose:** Edit an exercise set (add/modify lectures)
- **Parameters:**
  - `_courseName` (String): Course name
  - `_variant` (String): Variant name
- **Authorization:** Must be the owner of the exercise set

---

### Route: `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture`
- **Renders:** `exerciseSet` template
- **Purpose:** Browse a specific lecture within an exercise set
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String): Lecture name/ID

---

### Route: `/course/:_courseName/exerciseSet/:_variant/edit/lecture/:_lecture/`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/edit/lecture/:_lecture/`
- **Renders:** `exerciseSetEdit` template
- **Purpose:** Edit a specific lecture
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)

---

### Route: `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit`
- **Renders:** `exerciseSet` template
- **Purpose:** Browse a specific unit within a lecture
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)
  - `_unit` (String): Unit name/ID

---

### Route: `/course/:_courseName/exerciseSet/:_variant/edit/lecture/:_lecture/unit/:_unit`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/edit/lecture/:_lecture/unit/:_unit`
- **Renders:** `exerciseSetEdit` template
- **Purpose:** Edit a specific unit
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)
  - `_unit` (String)

---

### Route: `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/listExercises`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/listExercises`
- **Renders:** `listExercises` template
- **Purpose:** List all exercises in a lecture
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)

---

### Route: `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit/listExercises`
- **URL Pattern:** `/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit/listExercises`
- **Renders:** `listExercises` template
- **Purpose:** List all exercises in a unit
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)
  - `_unit` (String)

---

## Student Exercise Routes

### Route: `/feedbackToReview`
- **URL Pattern:** `/feedbackToReview`
- **Renders:** `feedbackToReview` template
- **Purpose:** Show submitted exercises with feedback to review
- **Typical Subscriptions:**
  - `exercises_with_unseen_feedback`: Student's exercises with unreviewed feedback

---

### Route: `/mySubmittedExercises`
- **URL Pattern:** `/mySubmittedExercises`
- **Renders:** `mySubmittedExercises` template
- **Purpose:** Show all exercises submitted by the current user
- **Typical Subscriptions:**
  - `submitted_exercises`: User's submitted exercises

---

### Route: `/upsertExerciseSet`
- **URL Pattern:** `/upsertExerciseSet`
- **Renders:** `upsertExerciseSet` template
- **Purpose:** Create or edit an exercise set
- **Methods Called:**
  - `createNewExerciseSet` or `upsertExerciseSet`

---

## Exercise (Problem) Routes

Routes for various types of logic exercises, all using parameter substitution to build custom problem URLs.

### Logic Tree Exercises

#### Route: `/ex/tree/require/:_requirements/from/:_premises/to/:_conclusion`
- **Purpose:** Create a logical proof tree for an argument
- **Parameters:**
  - `_requirements`: Required transformations/rules
  - `_premises`: Starting propositions (URL-encoded, pipe-separated)
  - `_conclusion`: Target conclusion (URL-encoded)
- **Renders:** `tree_ex` template

#### Route: `/ex/tree/require/:_requirements/qq/:_sentences`
- **Purpose:** Create proof tree for a set of sentences
- **Parameters:**
  - `_requirements`: Required transformations
  - `_sentences`: Sentences to work with (URL-encoded, pipe-separated)
- **Renders:** `tree_ex` template

---

### Proof Exercises

#### Route: `/ex/proof/from/:_premises/to/:_conclusion`
- **Purpose:** Write a formal proof of an argument
- **Parameters:**
  - `_premises`: Starting propositions
  - `_conclusion`: Target conclusion
- **Renders:** `proof_ex` template

#### Route: `/ex/proof/orInvalid/from/:_premises/to/:_conclusion`
- **Purpose:** Either write a proof or declare argument invalid
- **Parameters:**
  - `_premises`: Starting propositions
  - `_conclusion`: Target conclusion
- **Renders:** `proof_ex` template

---

### Translation Exercises

#### Route: `/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence`
- **Purpose:** Translate between natural language and formal logic notation
- **Parameters:**
  - `_domain`: Domain objects available
  - `_names`: Available constant names (URL-encoded)
  - `_predicates`: Available predicates with arities (URL-encoded)
  - `_sentence`: Sentence to translate (auto-detects direction)
- **Renders:** `trans_ex` template

---

### Model/Situation Creation Exercises

#### Route: `/ex/create/qq/:_sentences`
- **Purpose:** Create a possible situation where all sentences are true
- **Parameters:**
  - `_sentences`: Sentences to satisfy (URL-encoded, pipe-separated)
- **Renders:** `create_ex` template

#### Route: `/ex/counter/qq/:_sentences`
- **Purpose:** Create a counterexample/model (with explicit details)
- **Parameters:**
  - `_sentences`: Sentences to satisfy
- **Renders:** `counter_ex` template

#### Route: `/ex/create/orInconsistent/qq/:_sentences`
- **Purpose:** Either create a model or declare sentences inconsistent
- **Parameters:**
  - `_sentences`: Sentences to evaluate
- **Renders:** `create_ex` template

#### Route: `/ex/counter/orInconsistent/qq/:_sentences`
- **Purpose:** Either create counterexample or declare sentences inconsistent
- **Parameters:**
  - `_sentences`: Sentences to evaluate
- **Renders:** `counter_ex` template

#### Route: `/ex/create/from/:_premises/to/:_conclusion`
- **Purpose:** Create a counterexample to an argument
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
- **Renders:** `create_ex` template

#### Route: `/ex/counter/from/:_premises/to/:_conclusion`
- **Purpose:** Create a counterexample (with details)
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
- **Renders:** `counter_ex` template

#### Route: `/ex/create/orValid/from/:_premises/to/:_conclusion`
- **Purpose:** Either prove argument valid or provide counterexample
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
- **Renders:** `create_ex` template

#### Route: `/ex/counter/orValid/from/:_premises/to/:_conclusion`
- **Purpose:** Either prove valid or provide counterexample (detailed)
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
- **Renders:** `counter_ex` template

---

### Truth Table Exercises

#### Route: `/ex/tt/qq/:_sentences`
- **Purpose:** Construct truth tables for sentences and answer questions
- **Parameters:**
  - `_sentences`: Sentences to analyze (URL-encoded, pipe-separated)
- **Renders:** `tt_ex` template

#### Route: `/ex/tt/noQ/qq/:_sentences`
- **Purpose:** Construct truth tables (no comprehension questions)
- **Parameters:**
  - `_sentences`: Sentences to analyze
- **Renders:** `tt_ex` template

#### Route: `/ex/tt/from/:_premises/to/:_conclusion`
- **Purpose:** Construct truth table for argument validity evaluation
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
- **Renders:** `tt_ex` template

#### Route: `/ex/tt/noQ/from/:_premises/to/:_conclusion`
- **Purpose:** Construct truth table (no questions)
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
- **Renders:** `tt_ex` template

---

### Scope Exercises

#### Route: `/ex/scope/qq/:_sentences/`
- **Purpose:** Identify scope of quantifiers in sentences
- **Parameters:**
  - `_sentences`: Sentences to analyze (URL-encoded, pipe-separated)
- **Renders:** `scope_ex` template

---

### Short Answer/Question Exercises

#### Route: `/ex/q/:_question/`
- **Purpose:** Answer a question in free text
- **Parameters:**
  - `_question`: The question to answer (URL-encoded)
- **Renders:** `q_ex` template

---

### True/False Evaluation Exercises

#### Route: `/ex/TorF/from/:_premises/to/:_conclusion/world/:_world/qq/:_sentences`
- **Purpose:** Answer T/F questions about argument and a specific model (world)
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
  - `_world`: Model specification (JSON)
  - `_sentences`: Questions to answer (URL-encoded, pipe-separated)
- **Renders:** `TorF_ex` template

#### Route: `/ex/TorF/from/:_premises/to/:_conclusion/TTrow/:_TTrow/qq/:_sentences`
- **Purpose:** Answer T/F questions about argument and a truth table row
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
  - `_TTrow`: Truth table row assignment (e.g., "A:T|B:F")
  - `_sentences`: Questions (URL-encoded, pipe-separated)
- **Renders:** `TorF_ex` template

#### Route: `/ex/TorF/from/:_premises/to/:_conclusion/qq/:_sentences`
- **Purpose:** Answer T/F questions about argument only
- **Parameters:**
  - `_premises`: Argument premises
  - `_conclusion`: Argument conclusion
  - `_sentences`: Questions
- **Renders:** `TorF_ex` template

#### Route: `/ex/TorF/world/:_world/qq/:_sentences`
- **Purpose:** Answer T/F questions about a model/world
- **Parameters:**
  - `_world`: Model specification
  - `_sentences`: Questions
- **Renders:** `TorF_ex` template

#### Route: `/ex/TorF/TTrow/:_TTrow/qq/:_sentences`
- **Purpose:** Answer T/F questions about a truth table row
- **Parameters:**
  - `_TTrow`: Truth table row assignment
  - `_sentences`: Questions
- **Renders:** `TorF_ex` template

#### Route: `/ex/TorF/qq/:_sentences`
- **Purpose:** Answer T/F questions (general)
- **Parameters:**
  - `_sentences`: Questions to answer
- **Renders:** `TorF_ex` template

---

### Exercise Grading Route Pattern

**All exercise routes have a companion grading route:**
- Append `/grade` to any exercise route
- Renders: `GradeLayout` template
- Purpose: Display grading interface for the exercise
- Examples:
  - `/ex/proof/from/:_premises/to/:_conclusion/grade`
  - `/ex/create/qq/:_sentences/grade`
  - `/ex/tt/qq/:_sentences/grade`

---

## Tutor/Instructor Routes

### Route: `/myTutees`
- **URL Pattern:** `/myTutees`
- **Renders:** `myTutees` template
- **Purpose:** Show list of students being tutored by the current user
- **Authorization:** User must be a seminar tutor
- **Typical Subscriptions:**
  - `tutees`: Students with current user as tutor
  - `tutee_user_info`: Details about tutees

---

### Route: `/myTutors`
- **URL Pattern:** `/myTutors`
- **Renders:** `myTutors` template
- **Purpose:** Show list of tutors assigned to current user
- **Typical Subscriptions:**
  - `tutees` or user profile showing seminar_tutor assignment

---

### Route: `/exercisesToGrade`
- **URL Pattern:** `/exercisesToGrade`
- **Renders:** `exercisesToGrade` template
- **Purpose:** Dashboard showing exercises that need grading
- **Authorization:** User must be a tutor
- **Typical Methods:**
  - `getExercisesToGrade()`: Gets list of exercises needing feedback
- **Typical Subscriptions:**
  - `submitted_answers`: Submissions from tutee students

---

### Route: `/exercisesToGrade/course/:_courseName/exerciseSet/:_variant`
- **URL Pattern:** `/exercisesToGrade/course/:_courseName/exerciseSet/:_variant`
- **Renders:** `exercisesToGradeForExerciseSet` template
- **Purpose:** Exercises to grade for a specific exercise set
- **Parameters:**
  - `_courseName` (String): Course name
  - `_variant` (String): Exercise set variant

---

### Route: `/exercisesToGrade/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture`
- **URL Pattern:** `/exercisesToGrade/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture`
- **Renders:** `exercisesToGradeForExerciseSet` template
- **Purpose:** Exercises to grade for a specific lecture
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)

---

### Route: `/exercisesToGrade/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit`
- **URL Pattern:** `/exercisesToGrade/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit`
- **Renders:** `exercisesToGradeForExerciseSet` template
- **Purpose:** Exercises to grade for a specific unit
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)
  - `_unit` (String)

---

### Route: `/helpRequestsToAnswer`
- **URL Pattern:** `/helpRequestsToAnswer`
- **Renders:** `helpRequestsToAnswer` template
- **Purpose:** Show unanswered help requests from tutees
- **Typical Methods:**
  - `nofHelpRequestsForTutor()`: Get count of unanswered requests
- **Typical Subscriptions:**
  - `all_unanswered_help_requests_for_tutor`: Help requests needing answers

---

### Route: `/myTuteesProgress`
- **URL Pattern:** `/myTuteesProgress`
- **Renders:** `myTuteesProgress` template
- **Purpose:** Track overall progress of tutee students
- **Typical Subscriptions:**
  - `tutees_progress`: Progress data for all tutees

---

### Route: `/myTuteesProgress/course/:_courseName/exerciseSet/:_variant`
- **URL Pattern:** `/myTuteesProgress/course/:_courseName/exerciseSet/:_variant`
- **Renders:** `myTuteesProgress` template
- **Purpose:** Progress for specific exercise set
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)

---

### Route: `/myTuteesProgress/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture`
- **URL Pattern:** `/myTuteesProgress/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture`
- **Renders:** `myTuteesProgress` template
- **Purpose:** Progress for specific lecture
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)

---

### Route: `/myTuteesProgress/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit`
- **URL Pattern:** `/myTuteesProgress/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit`
- **Renders:** `myTuteesProgress` template
- **Purpose:** Progress for specific unit
- **Parameters:**
  - `_courseName` (String)
  - `_variant` (String)
  - `_lecture` (String)
  - `_unit` (String)

---

## Statistics and Admin Routes

### Route: `/stats`
- **URL Pattern:** `/stats`
- **Renders:** `stats` template
- **Purpose:** Display system statistics (user counts, exercise counts, etc.)
- **Typical Methods:**
  - `getNofUsers()`
  - `getNofUsersWithSeminarTutor()`
  - `getNofSubmittedExercises()`
  - `getNofSubmittedExercisesNoResubmits()`

---

### Route: `/resetTester`
- **URL Pattern:** `/resetTester`
- **Renders:** `resetTester` template
- **Purpose:** Admin utility to reset test user data
- **Typical Methods:**
  - `resetTester()`: Clear all test submissions

---

# PART 3: METEOR PUBLICATIONS

Meteor Publications define data subscriptions that push collections from the server to the client. These are typically subscribed to on routes to load necessary data.

## General Course and Exercise Set Publications

### Publication: `courses`
**Location:** server/publish.coffee (line 1)

**Parameters:** None

**Purpose:** Publish all non-hidden courses to the client.

**Returns:** Cursor to Courses collection

**Query:** `{hidden:{$ne:true}}`

**Authorization:** Public (no authorization check)

**Data Sent:** All course fields (name, description, etc.)

**Client-Side:** Typically subscribed on `/courses` route

---

### Publication: `course`
**Location:** server/publish.coffee (line 4)

**Parameters:**
- `courseName` (String): Name of the course to fetch

**Purpose:** Publish a single course by name.

**Returns:** Cursor to Courses collection

**Query:** `{name:courseName}`

**Authorization:** Public

**Data Sent:** All fields of the matching course

---

### Publication: `exercise_sets`
**Location:** server/publish.coffee (line 9)

**Parameters:**
- `courseName` (String): Course name to filter by

**Purpose:** Publish exercise sets for a course (non-hidden only).

**Returns:** Cursor to ExerciseSets collection

**Query:** `{courseName, hidden:{$ne:true}}`

**Fields Published:** `courseName`, `variant`, `description`

**Authorization:** Public

**Notes:** Only non-hidden exercise sets are published

---

### Publication: `exercise_sets_owned_by`
**Location:** server/publish.coffee (line 14)

**Parameters:**
- `userId` (String): User ID who owns the exercise sets

**Purpose:** Publish exercise sets owned by a specific user.

**Returns:** Cursor to ExerciseSets collection

**Query:** `{owner:userId}`

**Fields Published:** `courseName`, `variant`, `description`, `owner`

**Authorization:** Public (but typically called for own user)

---

### Publication: `exercise_set`
**Location:** server/publish.coffee (line 19)

**Parameters:**
- `courseName` (String): Course name
- `variant` (String): Exercise set variant

**Purpose:** Publish a specific exercise set with full details.

**Returns:** Cursor to ExerciseSets collection

**Query:** `{courseName, variant}`

**Authorization:** Public

**Data Sent:** All fields including lectures and structure

---

## Student Exercise Submission Publications

### Publication: `submitted_exercises`
**Location:** server/publish.coffee (line 43)

**Parameters:**
- `userId` (String, optional): Student ID to view. Defaults to current user.

**Purpose:** Publish all exercise submissions for a student.

**Authorization:**
- If userId matches current user: Always allowed
- If userId is different: Only allowed if current user is a tutor of that student

**Returns:** Cursor to SubmittedExercises collection

**Query:** `{owner:userId}`

**Data Sent:** All fields of each submission

**Notes:** 
- Used for student to see their own submissions
- Used for tutors to see their tutees' submissions

---

### Publication: `dates_exercises_submitted`
**Location:** server/publish.coffee (line 31)

**Parameters:**
- `userId` (String, optional): Student ID. Defaults to current user.

**Purpose:** Publish summary of when exercises were submitted and feedback status.

**Authorization:** Same as `submitted_exercises` (current user or tutor of student)

**Returns:** Cursor to SubmittedExercises collection

**Query:** `{owner:userId}`

**Fields Published:** `created`, `owner`, `exerciseId`, `humanFeedback.isCorrect`, `machineFeedback.isCorrect`

**Data Sent:** Date submitted, exercise ID, and whether it's been graded

---

### Publication: `submitted_exercise`
**Location:** server/publish.coffee (line 70)

**Parameters:**
- `exerciseId` (String): Exercise ID

**Purpose:** Publish submissions for a specific exercise from the current user.

**Authorization:** Only for current user's submissions

**Returns:** Cursor to SubmittedExercises collection

**Query:** `{owner:@userId, exerciseId:exerciseId}`

**Data Sent:** All fields of matching submissions

---

### Publication: `submitted_answers`
**Location:** server/publish.coffee (line 171)

**Parameters:**
- `exerciseId` (String): Exercise ID
- `tuteeId` (String, optional): Specific student ID

**Purpose:** Publish student answers to an exercise for tutor grading.

**Authorization:**
- If tuteeId specified: Must be tutor of that student
- If tuteeId not specified: Only returns submissions from current user's tutees

**Returns:** Cursor to SubmittedExercises collection

**Query:** 
- With tuteeId: `{exerciseId:exerciseId, owner:tuteeId}`
- Without tuteeId: `{exerciseId:exerciseId, owner:{$in:tuteeIds}}`

**Data Sent:** All submission fields (including answers)

**Notes:** Used by tutors to see student responses for grading

---

## Help Request Publications

### Publication: `help_request`
**Location:** server/publish.coffee (line 77)

**Parameters:**
- `exerciseId` (String): Exercise ID

**Purpose:** Publish help requests from the current user for a specific exercise.

**Authorization:** Only for current user's requests

**Returns:** Cursor to HelpRequest collection

**Query:** `{requesterId:@userId, exerciseId:exerciseId}`

**Data Sent:** All fields of matching help requests

---

### Publication: `help_requests_for_tutor`
**Location:** server/publish.coffee (line 185)

**Parameters:**
- `exerciseId` (String): Exercise ID

**Purpose:** Publish help requests from the tutor's students for an exercise.

**Authorization:** Must be a tutor

**Returns:** Cursor to HelpRequest collection

**Query:** `{exerciseId:exerciseId, requesterId:{$in:tuteeIds}}`

**Data Sent:** All help request fields

**Notes:** Used by tutors to see all help requests they need to answer

---

### Publication: `all_unanswered_help_requests_for_tutor`
**Location:** server/publish.coffee (line 193)

**Parameters:** None

**Purpose:** Publish all unanswered help requests from the tutor's students.

**Authorization:** Must be a tutor

**Returns:** Cursor to HelpRequest collection

**Query:** `{requesterId:{$in:tuteeIds}, answer:{$exists:false}}`

**Data Sent:** All fields of unanswered requests

**Notes:** Used on `/helpRequestsToAnswer` route

---

### Publication: `next_help_request_with_unseen_answer`
**Location:** server/publish.coffee (line 98)

**Parameters:** None

**Purpose:** Get the next help request the student hasn't seen the answer to.

**Authorization:** Only for current user

**Returns:** Cursor to HelpRequest collection

**Query:** `{requesterId:@userId, answer:{$exists:true}, studentSeen:{$exists:false}}`

**Limit:** 1 result

**Data Sent:** The oldest unanswered help request

---

## Feedback Publications

### Publication: `exercises_with_unseen_feedback`
**Location:** server/publish.coffee (line 94)

**Parameters:** None

**Purpose:** Publish all exercises where the student hasn't seen the feedback yet.

**Authorization:** Only for current user

**Returns:** Cursor to SubmittedExercises collection

**Query:** `{owner:@userId, 'humanFeedback.studentSeen':false}`

**Data Sent:** All fields of exercises with unseen feedback

**Notes:** Used on `/feedbackToReview` route

---

### Publication: `next_exercise_with_unseen_feedback`
**Location:** server/publish.coffee (line 89)

**Parameters:** None

**Purpose:** Get the next exercise with unseen feedback.

**Authorization:** Only for current user

**Returns:** Cursor to SubmittedExercises collection

**Query:** `{owner:@userId, 'humanFeedback.studentSeen':false}`

**Limit:** 1 result

**Data Sent:** Single exercise with the oldest unseen feedback

---

## Graded Answers Publication

### Publication: `graded_answers`
**Location:** server/publish.coffee (line 84)

**Parameters:**
- `exerciseId` (String): Exercise ID

**Purpose:** Publish previously graded answers for an exercise (for auto-grading).

**Authorization:** Public (any user can see graded answers)

**Returns:** Cursor to GradedAnswers collection

**Query:** `{exerciseId}`

**Data Sent:** All grading results (isCorrect, comments, answer hashes)

**Notes:** Used for auto-grading student responses against previously graded answers

---

## Subscription Management Publications

### Publication: `subscriptions`
**Location:** server/publish.coffee (line 24)

**Parameters:** None

**Purpose:** Publish the current user's exercise set subscriptions.

**Authorization:** Only for current user (`@userId`)

**Returns:** Cursor to Subscriptions collection

**Query:** `{owner:@userId}`

**Data Sent:** All subscription documents (courseName, variant, exerciseSetId, created date)

---

### Publication: `tutees_subscriptions`
**Location:** server/publish.coffee (line 141)

**Parameters:**
- `tutorId` (String, optional): Specific tutor ID. If omitted, uses current user.

**Purpose:** Publish all exercise set subscriptions for a tutor's students.

**Authorization:**
- If tutorId omitted: Current user must be a tutor
- If tutorId specified: Current user must be the instructor of that tutor

**Returns:** Cursor to Subscriptions collection

**Query:** `{owner:{$in:tuteeIds}}`

**Data Sent:** All subscription records for the tutor's students

**Notes:** Used to see which students are following which exercise sets

---

## User/Tutor Publications

### Publication: `tutee_user_info`
**Location:** server/publish.coffee (line 109)

**Parameters:**
- `userId` (String): Student ID to get info for

**Purpose:** Publish name and email of a tutee student.

**Authorization:**
- If userId matches current user: Always allowed
- Otherwise: Only allowed if current user is a tutor of that student

**Returns:** Cursor to Meteor.users collection

**Query:** `userId`

**Fields Published:** `emails`, `profile.name`

**Data Sent:** User's email and name only (privacy-limited)

---

### Publication: `tutees`
**Location:** server/publish.coffee (line 116)

**Parameters:**
- `tutorId` (String, optional): Specific tutor. Omit to get current user's tutees.
- `limitToSubscribersToThisExerciseSet` (Object, optional): 
  - `courseName` (String)
  - `variant` (String)

**Purpose:** Publish all students being tutored by a tutor.

**Authorization:**
- If tutorId omitted: Current user must be a tutor
- If tutorId specified: Current user must be the instructor of that tutor

**Returns:** Cursor to Meteor.users collection

**Query:** 
- `{'profile.seminar_tutor':tutorEmail}`
- Optionally filtered to only those subscribed to an exercise set

**Data Sent:** Full user profiles of tutees

**Notes:** 
- Can optionally limit to only tutees subscribed to a specific exercise set
- Used on `/myTutees` route

---

### Publication: `tutors_for_instructor`
**Location:** server/publish.coffee (line 156)

**Parameters:**
- `tutorId` (String, optional): Specific tutor ID. Omit to get all.

**Purpose:** Publish tutors under an instructor's supervision.

**Authorization:** Current user must be an instructor

**Returns:** Cursor to Meteor.users collection

**Query:** 
- All: `{'profile.instructor':instructorEmail}`
- Specific: `{_id:tutorId, 'profile.instructor':instructorEmail}`

**Data Sent:** Full user profiles of tutors

**Notes:** Used when instructor manages multiple tutors

---

## Progress Tracking Publications

### Publication: `tutees_progress`
**Location:** server/publish.coffee (line 202)

**Parameters:**
- `tutorId` (String, optional): Specific tutor. Omit for current user.
- `limitToSubscribersToThisExerciseSet` (Object, optional):
  - `courseName` (String)
  - `variant` (String)

**Purpose:** Publish exercise submission data for tracking tutee progress.

**Authorization:** Same as `tutees` publication

**Returns:** Cursor to SubmittedExercises collection

**Query:** `{owner:{$in:tuteeIds}}`

**Fields Published:** `owner`, `exerciseId`, `humanFeedback.isCorrect`, `machineFeedback.isCorrect`, `created`

**Optional Filter:** If limitToSubscribersToThisExerciseSet provided, only includes students subscribed to that exercise set

**Data Sent:** Exercise completion and correctness status per student

**Notes:** Used on `/myTuteesProgress` route to show progress charts

---

## Search/Discovery Publication

### Search Source: `tutors`
**Location:** server/publish.coffee (line 235)

**Purpose:** Provide search results for finding tutors (not a traditional Meteor publication).

**Parameters:**
- `searchText` (String): Search query
- `options` (Object): Query options

**Returns:** Array of user documents (not a cursor)

**Search Logic:**
- If searchText provided:
  - Case-insensitive regex search on:
    - `emails.address`: Email addresses
    - `profile.name`: User names
  - Filtered to users with `profile.is_seminar_tutor:true`
- If no searchText:
  - Returns all seminar tutors

**Sorting:** By `isoScore` descending, limit 20 results

**Notes:** 
- Uses meteorhacks SearchSource for instant search
- Returns up to 20 matches

---

## Database Indices

The publications file also includes Meteor startup code to create database indices for query performance:

```
Collection                              Index
Courses                                 {name:1}
ExerciseSets                            {courseName:1}
ExerciseSets                            {owner:1}
ExerciseSets                            {courseName:1, variant:1}
Subscriptions                           {owner:1}
SubmittedExercises                      {owner:1}
SubmittedExercises                      {owner:1, exerciseId:1}
SubmittedExercises                      {owner:1, 'humanFeedback.studentSeen':1}
SubmittedExercises                      {owner:1, exerciseId:1}
HelpRequest                             {requesterId:1, exerciseId:1}
HelpRequest                             {requesterId:1, answer:1, studentSeen:1}
HelpRequest                             {requesterId:1}
GradedAnswers                           {exerciseId:1}
Meteor.users                            {'profile.seminar_tutor':1}
Meteor.users                            {'profile.instructor':1}
Meteor.users                            {'profile.is_seminar_tutor':1}
```

---

## Summary: Subscription Patterns

### For Students
- `subscriptions`: See what exercise sets they're following
- `exercise_sets`: Browse available exercise sets
- `exercise_set`: View specific exercise set
- `submitted_exercises` (own): See their own submissions
- `dates_exercises_submitted`: Quick view of progress
- `next_exercise_with_unseen_feedback`: See latest feedback
- `exercises_with_unseen_feedback`: Review all unreviewed feedback

### For Tutors  
- `tutees`: List of their students
- `submitted_answers`: Student responses for an exercise
- `help_requests_for_tutor`: Help requests from students
- `all_unanswered_help_requests_for_tutor`: Unanswered help requests
- `tutees_progress`: Overall student progress
- `tutees_subscriptions`: Which students follow which exercise sets

### For Instructors
- `tutors_for_instructor`: Tutors under their supervision
- `tutees` (with tutorId): Students of a specific tutor
- `tutees_progress` (with tutorId): Progress for a tutor's students

### Public
- `courses`: All published courses
- `exercise_sets`: Non-hidden exercise sets
- `graded_answers`: Previously graded answers (for auto-grading)

---

## Helper Function

**Location:** server/publish.coffee (lines 51-68)

### Function: `checkIsTutee`
**Parameters:**
- `userId` (String): User to check as potential tutor
- `studentId` (String): User to check as potential student

**Purpose:** Verify that userId is a tutor of studentId.

**Business Logic:**
1. Fetches student profile
2. Gets student's assigned tutor email
3. Checks if current user's email matches
4. Special case for instructors:
   - If current user is an instructor, checks if student's tutor is under that instructor
   - Gets list of tutors assigned to the instructor
   - Checks if student's tutor is one of them

**Returns:** Boolean - true if userId is a tutor/instructor of studentId

**Notes:** Supports both direct tutor relationships and instructor-tutor-student hierarchies

---

# APPENDIX: Error Codes Reference

Common Meteor.Error codes used throughout the API:

| Error | Meaning | Context |
|-------|---------|---------|
| `not-authorized` | User not logged in or lacks required role | Used in ~30+ methods |
| `not-authorized: not yours` | User doesn't own the resource | Exercise sets, courses |
| `already exists` | Resource with that name already exists | Courses, exercise sets |
| `cannot find it` | Resource not found | Courses, exercise sets |
| `illegal characters in name` | Name contains non-URL-encoded characters | Courses, exercise sets |
| `not authorized` | Authorization failed (alternate format) | Publications |
| `has exercise sets` | Course still has exercise sets | Delete course |
| `has lectures` | Exercise set still has lectures | Delete exercise set |
| `Exercise sets must have 'courseName' and 'variant' properties.` | Missing required fields | upsertExerciseSet |
| `You cannot update this exercise set because you do not own it.` | Ownership mismatch | upsertExerciseSet |
| `You are already following 'variant' on courseName.` | Already subscribed | subscribeToExerciseSet |
| `You aren't following 'variant' on courseName.` | No subscription to remove | unsubscribeToExerciseSet |
| `No tutor is registered with that email address.` | Tutor not found | updateSeminarTutor |
| `No instructor is registered with that email address.` | Instructor not found | updateInstructor |
| `That email address is already is use.` | Email taken | updateEmailAddress |
| `The owner (author) of a submitted exercise may not be changed.` | Tampering detected | addHumanFeedback |
| `not-authorized (no supervisor for this student)` | Student has no tutor | addHumanFeedback |
| `not-authorized (not the supervisor of this student)` | Current user not the tutor | addHumanFeedback |
| `Could not find tester's id!` | Test user doesn't exist | resetTester |

---

# IMPLEMENTATION NOTES

## Collections Structure

The system uses these main collections (defined in love-logic.coffee):
- **Meteor.users**: Standard Meteor user collection
- **Courses**: Course definitions
- **ExerciseSets**: Exercise sets with lectures
- **SubmittedExercises**: Student submissions and feedback
- **Subscriptions**: Student-to-exercise-set subscriptions
- **GradedAnswers**: Cached grading results for auto-grading
- **HelpRequest**: Help request messages

## Security Patterns

1. **Authorization**: Most methods require `Meteor.user()` check
2. **Ownership verification**: Methods check that user owns resources
3. **Tutor hierarchy**: Tutors can only see their students' data
4. **Email matching**: Careful case-handling for email lookups
5. **Atomic operations**: Uses findAndModify for upserts

## Performance Considerations

1. Database indices are created for common query patterns
2. Publications often limit returned fields for privacy
3. Aggregation pipeline used for complex queries (getExercisesToGrade)
4. Limit 1 used for single-result queries
5. SearchSource for instant tutor search

## Missing/TODO Items

Based on code comments:
- Unique composite index needed for GradedAnswers
- Could implement optimistic updates for exercise submission
- Instructor can monitor all students' progress (TODO)
- Allow non-logged-in access with restrictions (TODO)

---

**End of Document**

Generated: 2025-11-14  
Total Methods: 33  
Total Routes: 80+  
Total Publications: 25+
