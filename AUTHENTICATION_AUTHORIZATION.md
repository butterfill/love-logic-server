# Love Logic Server: Authentication & Authorization System

## Table of Contents
1. [User Account System](#user-account-system)
2. [User Roles](#user-roles)
3. [User Relationships](#user-relationships)
4. [Authorization Patterns](#authorization-patterns)
5. [Access Control Rules](#access-control-rules)
6. [Security Considerations](#security-considerations)
7. [Implementation Details](#implementation-details)

---

## User Account System

### Overview
The love-logic-server uses **Meteor's built-in accounts system** with the following packages:
- `accounts-password`: Provides password-based authentication
- `useraccounts:flow-routing`: Provides UI templates for sign-in, sign-up, and password management
- `useraccounts:materialize`: Material Design styling for account templates

### User Registration

#### Registration Process
New users register through the AccountsTemplates system (configured in `lib/config/at_config.coffee`).

**Required Fields:**
1. **Email** - User's email address (must be unique, case-insensitive)
2. **Password** - User's password for authentication
3. **Full Name** - User's display name (required field, plain text)
4. **Terms of Use** - Checkbox to accept terms of use (required)

**Optional Security:**
- **reCAPTCHA**: Configured in the system but disabled by default (`showReCaptcha: false`)
  - Site Key: `6Lc7Ew8TAAAAAE4stjjDQZj75lJr04uiVF4IY9EP`
  - Secret Key: Stored in `server/at_server_config.coffee`
  - Theme: Light
  - Can be enabled by setting `showReCaptcha: true`

#### Registration Flow
```
1. User visits /sign-up
2. AccountsTemplates presents form with fields:
   - Email (standard field, built-in)
   - Password (standard field, built-in)
   - Full Name (custom field)
   - Terms of Use checkbox (custom field)
3. System validates email is unique (case-insensitive via RegExp)
4. System validates terms checkbox is true
5. Account is created with Meteor.users collection
6. User can login with email/password
```

### User Login

**Sign-In Fields:**
- Email (case-insensitive)
- Password

**Sign-In Flow:**
```
1. User visits /sign-in
2. AccountsTemplates presents form
3. Meteor validates credentials against Meteor.users collection
4. On success: Session is established, user redirected to main app
5. On failure: Error message displayed
```

#### Password Management
- **Change Password**: Enabled via route `changePwd` using AccountsTemplates
- **Forgot Password**: Routes configured (`forgotPwd`, `resetPwd`)
- **Email Verification**: Routes exist (`verifyEmail`, `resendVerificationEmail`) but not enforced

### User Email Management

Users can update their email address via the Meteor method `updateEmailAddress`:

```coffeescript
updateEmailAddress : (emailAddress) ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  if Meteor.isClient
    return undefined
  
  # Validate no duplicate email (case-insensitive)
  matchEmail = new RegExp("^#{emailAddress}$", "i")
  test = Meteor.users.find({'emails.address':matchEmail}).count()
  if test isnt 0
    throw new Meteor.Error "That email address is already is use."
  
  # Update email and mark as unverified
  emails = [{ address : emailAddress, verified : false }]
  Meteor.users.update(userId, {$set: {'emails':emails}})
```

**Key Points:**
- Email must be unique across all users (case-insensitive)
- When updated, email is marked as unverified
- Only authenticated users can change their email

### User Profile Structure

All user accounts have a `profile` object stored in the Meteor.users collection:

```javascript
{
  _id: ObjectId,
  emails: [
    {
      address: "user@example.com",
      verified: false  // Email verification status
    }
  ],
  profile: {
    // Display name (set during registration)
    name: "John Smith",
    
    // Role flags
    is_seminar_tutor: false,    // User is authorized to tutor
    is_instructor: false,        // User is authorized to instruct
    
    // Relationship fields (email-based references)
    seminar_tutor: "tutor@example.com",    // User's assigned tutor
    instructor: "prof@example.com"         // User's assigned instructor
  },
  
  // Meteor-managed fields
  createdAt: ISODate("2015-11-01T10:00:00Z"),
  services: { password: {...}, resume: {...} }  // Authentication tokens
}
```

---

## User Roles

### Role System Overview

The system uses **three primary roles** defined by boolean flags in the user's profile:

1. **Student** - Base role for all registered users
2. **Seminar Tutor** - Can grade exercises and answer help requests
3. **Instructor** - Can create courses and manage tutors

### Role Definitions

#### Student Role
- **Flag:** None (default for all registered users)
- **Responsibilities:**
  - Submit exercises for grading
  - Request help on exercises
  - View their own submissions and feedback
  - Follow/subscribe to exercise sets
- **Permissions:**
  - Read only their own submissions
  - Create submissions and help requests
  - Can become a tutor or instructor (self-promotion)

#### Seminar Tutor Role
- **Flag:** `profile.is_seminar_tutor = true`
- **Responsibilities:**
  - Grade student exercises (human feedback)
  - Answer student help requests
  - View students assigned to them
  - Monitor student progress
- **Permissions:**
  - View all submissions from assigned students
  - View help requests from assigned students
  - Add human feedback to student submissions
  - Create exercise sets and courses
- **How Students Become Assigned:**
  - Students assign themselves via UI
  - They provide tutor's email address
  - System validates tutor exists with `profile.is_seminar_tutor = true`

#### Instructor Role
- **Flag:** `profile.is_instructor = true`
- **Responsibilities:**
  - Create and manage courses
  - Manage tutors and their students
  - View all data for tutors under their supervision
- **Permissions:**
  - Create courses (with naming restrictions)
  - Create and edit exercise sets
  - View all tutors assigned to them
  - View all submissions of their tutees' students
- **How Tutors Become Assigned to Instructors:**
  - Tutors assign themselves via UI
  - They provide instructor's email address
  - System validates instructor exists with `profile.is_instructor = true`

### Role Assignment Methods

Users can change their own roles using Meteor methods (any authenticated user can call these):

```coffeescript
makeMeATutor : () ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  Meteor.users.update(userId, {$set: {'profile.is_seminar_tutor':true}})

makeMeNotATutor : () ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  Meteor.users.update(userId, {$set: {'profile.is_seminar_tutor':false}})

makeMeAnInstructor : () ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  Meteor.users.update(userId, {$set: {'profile.is_instructor':true}})

makeMeNotAnInstructor : () ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  Meteor.users.update(userId, {$set: {'profile.is_instructor':false}})
```

**Security Note:** These methods check only that user is authenticated. There is no validation that user is qualified to be a tutor/instructor. Any authenticated user can self-promote to any role.

---

## User Relationships

### Relationship System Overview

The system uses an **email-based relationship model** to connect users across role hierarchies:

```
Instructor (has many Tutors)
    ↓
Tutor (teaches many Students)
    ↓
Student (has Tutor)
```

### Student-to-Tutor Relationship

#### Storage
Stored in `profile.seminar_tutor` field of student user profile:

```javascript
{
  profile: {
    seminar_tutor: "dr.smith@university.edu"  // Email of assigned tutor
  }
}
```

#### Assignment
Students assign themselves a tutor using the `updateSeminarTutor` method:

```coffeescript
updateSeminarTutor : (emailAddress) ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  
  # Validate tutor exists
  matchEmail = new RegExp("^#{emailAddress}$", "i")
  cursor = Meteor.users.find({'emails.address':matchEmail, 
                               'profile.is_seminar_tutor':true})
  if cursor.count() is 0
    throw new Meteor.Error "No tutor is registered with that email address."
  
  tutorEmailAddress = cursor.fetch()[0].emails[0].address
  Meteor.users.update(userId, {$set: {"profile.seminar_tutor":tutorEmailAddress}})
```

**Key Points:**
- Student provides tutor's email address
- System validates tutor exists and has `is_seminar_tutor = true`
- Email matching is case-insensitive
- Relationship is stored as email string (not user ID)

#### Usage
- **Tutor Access:** Tutors can query students via email:
  ```coffeescript
  wy.getTuteeIds = (tutor_email) ->
    tutees = Meteor.users.find({'profile.seminar_tutor':tutor_email}, 
                                {fields:{_id:1}}).fetch()
    return (x._id for x in tutees)
  ```

- **Publications:** Data filtered to tutor's students in publications:
  ```coffeescript
  Meteor.publish "submitted_answers", (exerciseId, tuteeId) ->
    if tuteeId?
      # Authorization check
      throw new Meteor.Error "not authorized" unless 
        checkIsTutee(@userId, tuteeId)
    else
      # Get all student IDs for this tutor
      tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
      tuteeIds = wy.getTuteeIds(tutorEmail)
      return SubmittedExercises.find({exerciseId:exerciseId, owner:{$in:tuteeIds}})
  ```

### Tutor-to-Instructor Relationship

#### Storage
Stored in `profile.instructor` field of tutor user profile:

```javascript
{
  profile: {
    instructor: "prof.jones@university.edu"  // Email of assigned instructor
  }
}
```

#### Assignment
Tutors assign themselves an instructor using the `updateInstructor` method:

```coffeescript
updateInstructor : (emailAddress) ->
  userId = Meteor.user()?._id
  if not userId 
    throw new Meteor.Error "not-authorized"
  
  # Validate instructor exists
  test = Meteor.users.find({'emails.address':emailAddress,  
                             'profile.is_instructor':true}).count()
  if test is 0
    throw new Meteor.Error "No instructor is registered with that email address."
  
  Meteor.users.update(userId, {$set: {"profile.instructor":emailAddress}})
```

#### Usage
- **Instructor Access:** Instructors can query their tutors:
  ```coffeescript
  Meteor.publish "tutors_for_instructor", (tutorId) ->
    instructorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    unless tutorId
      return Meteor.users.find({'profile.instructor':instructorEmail})
    else
      return Meteor.users.find({_id:tutorId, 'profile.instructor':instructorEmail})
  ```

- **Transitive Authorization:** Instructors can authorize access to their tutors' students:
  ```coffeescript
  checkIsTutee = (userId, studentId) ->
    # ... normal tutor check ...
    
    # Special case: user is an instructor
    instructorEmail = currentUserEmail
    tutorsOfInstructor = Meteor.users.find(
      {'profile.instructor':instructorEmail}).fetch()
    tutorEmails = (x.emails?[0]?.address for x in tutorsOfInstructor)
    isTutee = seminarTutorEmail in tutorEmails
  ```

### Relationship Hierarchy Diagram

```
Professor (is_instructor=true)
    |
    ├─ profile.instructor = "prof@uni.edu"
    |
    v
Tutor A (is_seminar_tutor=true, instructor="prof@uni.edu")
    |
    ├─ profile.seminar_tutor = "tutorA@uni.edu"
    |
    v
Students of Tutor A
    |
    ├─ profile.seminar_tutor = "tutorA@uni.edu"
    |
    v
Student Submissions (Exercise data)
```

---

## Authorization Patterns

### Overview
Authorization in love-logic-server follows these patterns:
1. **Method-level checks** - Verify user permission in Meteor.methods
2. **Publication-level checks** - Filter data in Meteor.publish
3. **Ownership checks** - Verify user owns the resource

### Method Authorization Pattern

All methods follow this pattern:

```coffeescript
Meteor.methods
  methodName : (params) ->
    # 1. Check user is authenticated
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    
    # 2. Check specific permission (if needed)
    # Example: verify user owns the resource
    document = Collection.findOne(_id)
    if document.owner isnt userId
      throw new Meteor.Error "not-authorized: not yours"
    
    # 3. Skip client-side simulation if needed
    if Meteor.isClient
      return undefined
    
    # 4. Perform the operation
    Collection.update(_id, {$set: newData})
```

### Publication Authorization Pattern

```coffeescript
Meteor.publish "publication_name", (param) ->
  # 1. Get current user ID
  @userId  # Current user ID, null if not authenticated
  
  # 2. Check authorization for specific data
  if isAuthorized(@userId, param)
    return Collection.find(query)
  else
    throw new Meteor.Error "not authorized"

# Authorization helper
checkIsTutee = (userId, studentId) ->
  student = Meteor.users.findOne(studentId)
  seminarTutorEmail = student?.profile?.seminar_tutor
  return false unless seminarTutorEmail?
  
  user = Meteor.users.findOne(userId)
  currentUserEmail = user?.emails?[0]?.address
  
  isTutee = (seminarTutorEmail is currentUserEmail)
  return isTutee unless user.profile?.is_instructor and not isTutee
  
  # Special case: user is an instructor, check if student is tutee of 
  # a tutor under their supervision
  instructorEmail = currentUserEmail
  tutorsOfInstructor = Meteor.users.find(
    {'profile.instructor':instructorEmail}).fetch()
  tutorEmails = (x.emails?[0]?.address for x in tutorsOfInstructor)
  isTutee = seminarTutorEmail in tutorEmails
```

### Ownership-Based Authorization

For resources owned by users (courses, exercise sets):

```coffeescript
Meteor.methods
  deleteExerciseSet : (courseName, variant) ->
    userId = Meteor.user()?._id
    if not userId
      throw new Meteor.Error "not-authorized"
    
    exSet = ExerciseSets.findOne({variant, courseName})
    if exSet.owner isnt userId
      throw new Meteor.Error "not-authorized: not yours"
    
    ExerciseSets.remove(exSet._id)
```

---

## Access Control Rules

### Courses

#### View
- **Public** - All authenticated users can view non-hidden courses
- **Publication:** `courses` (shows only where `hidden != true`)

#### Create
- **Who:** Any authenticated user can create a course
- **Naming:** Course name must start with email domain (auto-prefixed)
  ```coffeescript
  email = Meteor.user()?.emails?[0]?.address
  emailDomain = email.split('@')[1]
  prefix = encodeURIComponent(emailDomain)
  unless name.startsWith(prefix)
    name = "#{prefix}-#{name}"
  ```
- **Example:** User with email `tutor@university.edu` creates course `logic101`
  - Course created as: `university.edu-logic101`

#### Delete
- **Who:** User who created it (owner)
- **Restrictions:** Can only delete if it has no associated exercise sets

### Exercise Sets

#### View
- **Owner:** Owner can see all their exercise sets
- **Public:** Non-hidden exercise sets visible to all authenticated users
- **Publication:** `exercise_sets` and `exercise_sets_owned_by`

#### Create
- **Who:** Any authenticated user can create
- **Ownership:** Current user becomes the owner
- **Naming:** (courseName, variant) must be unique
  ```coffeescript
  createNewExerciseSet : (courseName, variant, description) ->
    userId = Meteor.user()?._id
    newExSet = 
      courseName : courseName
      variant : variant
      owner : userId
      # ... other fields ...
  ```

#### Edit
- **Who:** Owner only
- **Fields:** Can update `description` and `lectures`
  ```coffeescript
  upsertExerciseSet : (exerciseSet) ->
    userId = Meteor.user()._id
    oldExerciseSet = ExerciseSets.findOne({...})
    if oldExerciseSet.owner isnt userId
      throw new Meteor.Error "You cannot update this exercise set 
        because you do not own it."
  ```

#### Show/Hide
- **Who:** Owner only
- **Methods:** `showExerciseSet` and `hideExerciseSet`
  ```coffeescript
  showExerciseSet : (exerciseSetId) ->
    userId = Meteor.user()?._id
    exSet = ExerciseSets.findOne({_id:exerciseSetId})
    if exSet.owner isnt userId
      throw new Meteor.Error "not-authorized: not yours"
    ExerciseSets.update({_id:exerciseSetId}, {$set:{hidden:false}})
  ```

#### Delete
- **Who:** Owner only
- **Restrictions:** Can only delete if it has no lectures

### Student Submissions (SubmittedExercises)

#### View
- **Student:** Can view only their own submissions
  - Own submissions: `SubmittedExercises.find({owner:@userId})`
  
- **Tutor:** Can view submissions from their assigned students
  - Authorization via `checkIsTutee` function
  - Gets student IDs via: `wy.getTuteeIds(tutorEmail)`
  
- **Instructor:** Can view submissions from tutees of their tutors
  - Transitive authorization through `checkIsTutee`

#### Submit
- **Who:** Only students can submit
- **Restrictions:**
  - Cannot include a `userId` field (security check)
  - Cannot have human feedback already (only one active submission)
  ```coffeescript
  submitExercise : (exercise) ->
    userId = Meteor.user()?._id
    if not userId or 'userId' of exercise
      throw new Meteor.Error "not-authorized"
  ```

#### Grade (Add Human Feedback)
- **Who:** Student's assigned tutor or an instructor managing that tutor
- **Authorization:**
  ```coffeescript
  addHumanFeedback : (submission, humanFeedback) ->
    # Check tutor is assigned to student
    tutorEmail = Meteor.users.findOne(submission.owner)?.profile?.seminar_tutor
    userEmails = (x.address for x in Meteor.user().emails)
    if not( tutorEmail in userEmails )
      throw new Meteor.Error "not-authorized (not the supervisor)"
  ```
- **Restrictions:**
  - Owner cannot change
  - Student must exist for grader

### Help Requests

#### View
- **Student:** Can view their own help requests
  - Publication: `help_request` (filters by `requesterId:@userId`)
  
- **Tutor:** Can view help requests from assigned students
  - Publication: `help_requests_for_tutor`
  - Gets tutee IDs via `wy.getTuteeIds(tutorEmail)`

#### Create
- **Who:** Any authenticated student
- **Fields:** 
  - `requesterId` - Set to current user
  - `exerciseId` - Provided by caller
  - `question` - Student's question
  - `created` - Set to current timestamp

#### Answer
- **Who:** Anyone can answer (no authorization check)
  ```coffeescript
  answerHelpRequest : (helpReq, answer) ->
    answererId = Meteor.user()?._id
    if not answererId
      throw new Meteor.Error "not-authorized"
    # No additional checks - any authenticated user can answer
    HelpRequest.update(helpReq, {$set:{dateAnswered, answererId, answer}})
  ```

#### Mark as Seen
- **Who:** Student who requested help
- **Authorization:**
  ```coffeescript
  studentSeenHelpRequestAnswer : (helpReq) ->
    userId = Meteor.user()._id
    if not userId or helpReq.requesterId isnt userId
      throw new Meteor.Error "not-authorized"
  ```

---

## Security Considerations

### Input Validation

#### Email Validation
- **Uniqueness:** Emails must be unique (case-insensitive)
  ```coffeescript
  matchEmail = new RegExp("^#{emailAddress}$", "i")
  if Meteor.users.find({'emails.address':matchEmail}).count() isnt 0
    throw new Meteor.Error "That email address is already in use."
  ```

#### Course and Exercise Set Names
- **URL Encoding:** Names must be URL-encodable
  ```coffeescript
  unless name is encodeURIComponent(name)
    throw new Meteor.Error "illegal characters in name"
  ```
- **Uniqueness:** 
  - Courses: `name` must be unique
  - Exercise Sets: `(courseName, variant)` must be unique

#### Required Fields
- **User Registration:**
  - Email (required, unique)
  - Password (required)
  - Name (required, custom field)
  - Terms of Use (required, must be true)

### Protection Against Unauthorized Access

#### Method-Level Protection

1. **User Authentication Check**
   ```coffeescript
   userId = Meteor.user()?._id
   if not userId 
     throw new Meteor.Error "not-authorized"
   ```

2. **Ownership Verification**
   ```coffeescript
   if resource.owner isnt userId
     throw new Meteor.Error "not-authorized: not yours"
   ```

3. **Relationship Verification**
   ```coffeescript
   throw new Meteor.Error "not authorized" unless checkIsTutee(@userId, studentId)
   ```

#### Publication-Level Protection

- Publications only send data to authorized users
- Tutors cannot see submissions outside their tutee list
- Students cannot see other students' work
- Instructors see only their hierarchy

#### Submission Protection

- **Prevent Impersonation:** Cannot specify owner or userId in submission
  ```coffeescript
  if 'userId' of exercise
    throw new Meteor.Error "not-authorized"
  # Owner always set to current user
  newDoc = _.defaults(exercise, {owner : userId, ...})
  ```

- **Prevent Owner Change:** 
  ```coffeescript
  oldOwner = SubmittedExercises.findOne({_id:submission._id})?.owner
  if oldOwner isnt submission.owner
    throw new Meteor.Error "The owner of a submitted exercise may not be changed."
  ```

### Data Privacy Controls

#### Denormalization for Privacy
The system denormalizes some data but protects sensitive information:

```coffeescript
# Allowed denormalization (necessary for display):
newDoc = _.defaults(exercise, {
  owner : userId,
  ownerName : Meteor.user().profile?.name,
  email : Meteor.user().emails[0].address,
  created : new Date()
})

# Fields NOT denormalized:
# - Password hashes (stored in services, not accessible)
# - Tutor assignments (stored as relationship fields, not broadcast)
# - Instructor assignments (stored as relationship fields)
```

#### Publication Field Limiting
Publications limit exposed fields:

```coffeescript
# Only expose necessary fields
Meteor.publish "exercise_sets", (courseName) ->
  return ExerciseSets.find({courseName}, 
    {fields:{courseName:1, variant:1, description:1}})

# Exclude sensitive fields like owner when not needed
```

#### Client-Side Simulations
Some operations skip client simulation (can only run on server):

```coffeescript
if Meteor.isClient
  return undefined

# Server-only operations:
# - Email validation (accesses all users)
# - Tutor/Instructor verification
# - Student access checks
```

### Protection Against Common Attacks

#### SQL Injection (N/A)
- Uses MongoDB, not SQL
- All queries use prepared operators ($in, $set, etc.)

#### Cross-Site Request Forgery (CSRF)
- Meteor's built-in DDP protocol prevents CSRF attacks
- Each connection is authenticated with unique tokens

#### Brute Force
- No built-in rate limiting visible in code
- **Recommendation:** Implement rate limiting on login attempts

#### Role Elevation
- Users can self-promote to tutor/instructor
- **Risk:** Any user can claim to be a tutor
- **Mitigation:** Admin verification needed in production (code comment suggests this was noted)

#### Data Exposure
- Publications return only necessary fields
- Client-side code uses reactive filters
- Server-side authorization on all data access

### Indexes for Security
Indexes support authorization checks:

```coffeescript
# User lookups by relationship fields
Meteor.users._ensureIndex({"profile.seminar_tutor":1})
Meteor.users._ensureIndex({"profile.instructor":1})
Meteor.users._ensureIndex({'profile.is_seminar_tutor':1})

# Exercise data lookups by owner
ExerciseSets._ensureIndex({owner:1})
SubmittedExercises._ensureIndex({owner:1})
SubmittedExercises._ensureIndex({owner:1, exerciseId:1})
```

---

## Implementation Details

### Key Files

| File | Purpose |
|------|---------|
| `server/at_server_config.coffee` | Accounts configuration (reCAPTCHA keys) |
| `lib/config/at_config.coffee` | Registration form fields and routes |
| `lib/wy.coffee` | Authorization helper functions |
| `server/publish.coffee` | Data publications with authorization |
| `love-logic.coffee` | Methods with authorization checks |
| `client/lib/ix.coffee` | Client-side role checking functions |

### Client-Side Role Detection

```coffeescript
# In client/lib/ix.coffee

ix.userIsTutor = () ->
  Meteor.user()?.profile?.is_seminar_tutor

ix.userIsInstructor = () ->
  Meteor.user()?.profile?.is_instructor

ix.isInstructorOrTutor = () ->
  (Meteor.user()?.profile?.instructor) or 
  (Meteor.user()?.profile?.seminar_tutor)
```

### Server-Side Authorization

#### Helper Functions

```coffeescript
# In lib/wy.coffee
wy.getTuteeIds = (tutor_email) ->
  if not tutor_email
    return [] 
  tutees = Meteor.users.find(
    {'profile.seminar_tutor':tutor_email}, 
    {fields:{_id:1}}).fetch()
  return (x._id for x in tutees)

# In server/publish.coffee
checkIsTutee = (userId, studentId) ->
  student = Meteor.users.findOne(studentId)
  seminarTutorEmail = student?.profile?.seminar_tutor
  return false unless seminarTutorEmail?

  user = Meteor.users.findOne(userId)
  currentUserEmail = user?.emails?[0]?.address
  
  isTutee = (seminarTutorEmail is currentUserEmail)
  return isTutee unless user.profile?.is_instructor and not isTutee
  
  # Special case: instructor can access tutee's tutees
  instructorEmail = currentUserEmail
  tutorsOfInstructor = Meteor.users.find(
    {'profile.instructor':instructorEmail}).fetch()
  tutorEmails = (x.emails?[0]?.address for x in tutorsOfInstructor)
  isTutee = seminarTutorEmail in tutorEmails
```

### Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Registration                       │
├─────────────────────────────────────────────────────────────┤
│ 1. User submits sign-up form with:                          │
│    - Email (unique, case-insensitive)                       │
│    - Password                                               │
│    - Full Name                                              │
│    - Terms of Use acceptance                                │
│ 2. System validates input                                   │
│ 3. Meteor.Accounts.createUser() called                      │
│ 4. User document created in Meteor.users                    │
│ 5. User redirected to /sign-in                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      User Login                             │
├─────────────────────────────────────────────────────────────┤
│ 1. User submits email + password                            │
│ 2. Meteor.loginWithPassword() called                        │
│ 3. Server validates credentials                             │
│ 4. On success:                                              │
│    - Session established with token                         │
│    - DDP connection authenticated                           │
│    - Meteor.user() returns user object                      │
│    - Publications subscribe based on @userId                │
│ 5. User can access main app                                 │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                  Method Call Authorization                   │
├──────────────────────────────────────────────────────────────┤
│ 1. Client calls Meteor.call('methodName', params)           │
│ 2. Method runs with this context = {userId: current user}   │
│ 3. Server checks:                                            │
│    - Is userId set (user authenticated)?                    │
│    - Does user own the resource?                            │
│    - Does user have correct role?                           │
│    - Are parameters valid?                                  │
│ 4. On authorization failure:                                │
│    - Meteor.Error thrown                                    │
│    - Client receives error                                  │
│ 5. On authorization success:                                │
│    - Operation performed                                    │
│    - Changes published to subscribed clients                │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                Publication Authorization                     │
├──────────────────────────────────────────────────────────────┤
│ 1. Client subscribes: this.subscribe('tutees', tutorId)     │
│ 2. Server's publish function receives:                       │
│    - this.userId: current user ID                            │
│    - tutorId: subscription parameter                        │
│ 3. Server checks authorization:                             │
│    - Does user own this data?                               │
│    - Is user tutor of this student?                         │
│    - Is user instructor of this tutor?                      │
│ 4. On failure: returns empty cursor or throws error         │
│ 5. On success: returns filtered Mongo cursor                │
│ 6. Only data matching user's permission level sent to client │
└──────────────────────────────────────────────────────────────┘
```

### Session and Token Management

- **DDP Tokens:** Meteor maintains DDP connection tokens
- **Stored in:** Browser's localStorage (connection token)
- **Validation:** Server validates token on each request
- **Expiration:** Token remains valid until user logs out
- **Refresh:** Automatic token refresh before expiration

### Logout

```coffeescript
Meteor.logout()
```

- Clears localStorage token
- Closes DDP connection
- Server invalidates session
- User returned to /sign-in

---

## Summary

The love-logic-server uses a **relationship-based authorization model** with three roles (Student, Tutor, Instructor) and email-based relationship tracking. Authorization is enforced at both the method and publication levels, with careful ownership verification and input validation. The system prioritizes privacy through publication field limiting and prevents unauthorized access through comprehensive checks throughout the codebase.

Key security strengths:
- Ownership verification on all methods
- Email-based relationship system prevents impersonation
- Publication-level filtering
- Role-based access control

Areas for improvement:
- Rate limiting on authentication attempts
- Admin verification for role elevation
- More explicit input sanitization
