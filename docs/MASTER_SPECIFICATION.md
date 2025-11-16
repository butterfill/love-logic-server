# MASTER SPECIFICATION: Love Logic Server

**Project Name:** Love Logic Server  
**Version:** 1.0  
**Author:** Stephen A. Butterfill (Original), Project Documentation  
**Last Updated:** November 14, 2025  
**Framework:** Meteor.js 1.2.1  
**Classification:** Complete Application Specification & Recreation Guide

---

## EXECUTIVE SUMMARY

### What is Love Logic Server?

Love Logic Server is a sophisticated web-based **automated logic exercise grading platform** designed for university-level logic education. It enables instructors and tutors to:

1. **Deploy Logic Exercises** through simple URL-based exercise definitions
2. **Track Student Progress** across multiple course variants and exercise types
3. **Provide Immediate Feedback** via machine grading or cached human grading
4. **Support Tutoring Workflows** with help request systems and human feedback mechanisms

The platform serves three core user groups:

- **Students**: Submit logic exercises, track progress, request help
- **Tutors/Seminar Leaders**: Grade student work, provide feedback, manage help requests
- **Instructors**: Manage courses, exercise sets, oversee tutor hierarchies

### Key Features & Capabilities

**Exercise Types (9 Total):**
- Truth Table exercises (evaluate validity, equivalence, tautology)
- Formal Proof exercises (natural deduction proofs)
- Translation exercises (natural language ↔ formal logic)
- Create exercises (construct possible worlds)
- Counterexample exercises (find situations violating arguments)
- True/False exercises
- Scope exercises
- Tree exercises (parse trees, syntax trees)
- Question exercises

**Smart Grading System:**
- Automatic machine grading with real-time feedback
- Answer caching system for consistent grading
- Tutor-provided feedback storage and reuse
- Hybrid human + machine feedback

**Progress Tracking:**
- Per-student exercise submission history
- Visual progress indicators across course variants
- Unseen feedback notifications
- Help request tracking

**Help Request System:**
- Students request help with specific exercises
- Tutors answer questions asynchronously
- Caching of answers for learning community
- Tracking of student engagement with help responses

### Target Users

**Students (Undergraduates & Graduates)**
- Logic course enrollment (PH126, PH136 at Warwick)
- Self-paced learning with online feedback
- 1-3 tutors support structure

**Tutors/Seminar Leaders**
- Manage assigned student groups (tutees)
- Grade non-automatable exercises
- Provide written feedback and help answers
- Monitor student progress

**Instructors (Faculty)**
- Create and manage course curricula
- Define exercise sets with difficulty variants
- Oversee tutor assignments and performance
- View institutional-level analytics

### Business Value & Use Cases

**Value Proposition:**
1. **Scalability** - One instructor can reach hundreds of students via automated feedback
2. **Immediate Feedback** - Students don't wait for grading; learn instantly
3. **Consistency** - Machine grading eliminates human bias; tutor answers cached for consistency
4. **Efficiency** - Tutors focus on complex questions; simple exercises auto-graded
5. **Flexibility** - URL-based exercises enable easy content updates and variants

**Key Use Cases:**
- Large lecture courses with logic component (100+ students)
- Self-paced online courses
- Variant-based instruction (normal vs. accelerated paths)
- Mixed-mode tutoring (automated + human support)

---

## PROJECT OVERVIEW

### Application Architecture (High-Level)

```
┌─────────────────────────────────────────────────────────────┐
│                     WEB BROWSER (Client)                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  FlowRouter (Client-Side Routing)                      │ │
│  │  ├─ Exercise Pages (Jade Templates)                    │ │
│  │  ├─ Dashboard & Course Navigation                      │ │
│  │  ├─ Tutor Grading Interface                            │ │
│  │  └─ Help Request Interface                             │ │
│  │                                                         │ │
│  │  Client Logic Engines:                                 │ │
│  │  ├─ Truth Table Evaluator                              │ │
│  │  ├─ Proof Validator (AWFOL)                            │ │
│  │  ├─ First-Order Logic Parser                           │ │
│  │  └─ Possible Worlds Creator                            │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                          ↕ (DDP Protocol)
┌──────────────────────────────────────────────────────────────┐
│               Meteor Server (Node.js Backend)                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Meteor Methods (RPC Endpoints)                        │ │
│  │  ├─ User Management (profile, roles)                   │ │
│  │  ├─ Course/ExerciseSet Management                      │ │
│  │  ├─ Exercise Submission                                │ │
│  │  ├─ Grading Operations                                 │ │
│  │  └─ Help Request System                                │ │
│  │                                                         │ │
│  │  Meteor Publications (Data Subscriptions)              │ │
│  │  ├─ Course & Exercise Set Data                         │ │
│  │  ├─ Student Progress (personalized)                    │ │
│  │  ├─ Tutor Feedback Queues                              │ │
│  │  └─ Help Request Management                            │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                          ↕ (MongoDB Protocol)
┌──────────────────────────────────────────────────────────────┐
│                  MongoDB Database                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Collections:                                           │ │
│  │  ├─ users (Meteor built-in)                            │ │
│  │  ├─ courses                                             │ │
│  │  ├─ exercise_sets                                       │ │
│  │  ├─ submitted_exercises                                 │ │
│  │  ├─ subscriptions                                       │ │
│  │  ├─ graded_answers (cache)                              │ │
│  │  └─ help_request                                        │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### Technology Stack Summary

**Backend Framework**
- Meteor 1.2.1 (Node.js-based, isomorphic)
- Node.js 0.10.40 (as deployed)

**Frontend**
- CoffeeScript (primary language)
- Jade Templates (HTML templating)
- Materialize CSS (Material Design framework)
- jQuery 1.11.4 (DOM manipulation)
- Blaze + Spacebars (reactive templating)

**Routing & Navigation**
- FlowRouter 2.10.1 (client-side routing)
- Kadira Blaze Layout (template management)

**Styling**
- Stylus (CSS preprocessor)
- SCSS (CSS preprocessing)
- Font Awesome 4.5.0 (icons)
- Material Design Icons

**Authentication & Accounts**
- Accounts-password (built-in Meteor)
- UserAccounts:Core + UserAccounts:FlowRouting
- UserAccounts:Materialize UI

**Database**
- MongoDB (3.2+, Replica Set)
- Minimongo (client-side sync)

**Logic Libraries** (Client-Side)
- AWFOL (First-Order Logic parsing & evaluation)
- Truth Table Engine
- Possible Worlds / Situation Creator
- jQuery-UI for Gridstack

**Development Tools**
- CoffeeScript Compiler
- Jade Compiler
- Babel 5.8.24 (ECMAScript transpilation)

### Key Design Decisions

1. **URL-Based Exercise Definition**
   - Exercises defined as URL paths, not database documents
   - Example: `/ex/proof/from/A∧B/to/A` defines a proof exercise
   - Enables versioning through URL parameters (variant, encoding)
   - Simplifies exercise sharing and linking

2. **Hybrid Grading Model**
   - **Machine grading**: Real-time feedback for exercises with definitive answers
   - **Answer caching**: Tutor grades cached by answer hash for reuse
   - **Human grading**: Complex exercises require human tutor judgment
   - **Fallback**: Cached grades auto-apply when identical answer submitted

3. **Hierarchical Access Control**
   - **Instructor** → manages **Tutors** → manages **Students** (tutees)
   - Email-based tutor assignment (profile.seminar_tutor field)
   - Publications enforce access at subscription layer

4. **Upsert Pattern for Submissions**
   - Only one submission per student per exercise
   - Prevents duplicate submissions
   - Enables tracking of latest answer

5. **Denormalized Data for Performance**
   - Student name/email denormalized in submissions (avoid user lookups)
   - Tutor names cached in help requests
   - Pre-computed answer hashes for quick comparison

### System Requirements

**Server Requirements (Minimal)**
- CPU: 1-2 cores (scales with concurrent users)
- RAM: 2GB minimum (4GB+ recommended)
- MongoDB: 20GB+ storage (grows with student submissions)
- Network: 1Mbps+ (for real-time DDP sync)

**Database Requirements**
- MongoDB 3.2+ (supports replica sets)
- Replica Set configuration (for redundancy)
- Indexes on critical fields (see MONGODB_SCHEMA.md)

**Browser Requirements**
- Modern browser with CSS Flexbox support
- Modern browser with CSS Background-Blend-Mode support
- JavaScript enabled (no graceful degradation)
- TLS/SSL for password transmission

**Recommended Deployment**
- Production: Meteor Up (mup) on dedicated server
- Database: MongoDB Atlas or self-managed replica set
- SSL: Let's Encrypt or commercial certificate

---

## FUNCTIONAL REQUIREMENTS

### User Roles & Permissions Matrix

| Feature | Student | Seminar Tutor | Instructor |
|---------|---------|---------------|------------|
| Submit exercises | ✓ | ✓ | ✓ |
| View own submissions | ✓ | ✓ | ✓ |
| View tutee submissions | ✗ | ✓ | ✓ (via tutor) |
| Grade exercises | ✗ | ✓ (tutees) | ✓ (all) |
| Manage courses | ✗ | ✗ | ✓ |
| Create exercise sets | ✗ | ✓ | ✓ |
| Manage tutees | ✗ | ✓ | ✓ (via tutor) |
| Request help | ✓ | ✓ | ✓ |
| Answer help requests | ✗ | ✓ | ✓ |
| View help request queue | ✗ | ✓ | ✓ |
| Set profile to tutor | ✓ | N/A | ✓ |
| Set profile to instructor | ✗ | ✓ | N/A |

### Core Features by User Type

#### Student Features
1. **Exercise Submission**
   - Browse enrolled exercise sets
   - Submit answers to exercises
   - Receive immediate machine feedback (if available)
   - Resubmit with updated answers
   - Receive human feedback notifications

2. **Progress Tracking**
   - View all submitted exercises
   - See completion status (submitted, graded)
   - Track feedback (unseen feedback notifications)
   - Resume from last exercise

3. **Help Request System**
   - Create help requests on specific exercises
   - Provide context (reviewed slides? read book?)
   - View tutor answers asynchronously
   - Get notifications when answers available

4. **Account Management**
   - Register with email/password
   - Update profile (name, email)
   - Assign seminar tutor
   - Change password

#### Tutor Features
1. **Student Management**
   - View list of assigned tutees
   - View tutees' exercise submissions
   - Filter by exercise set variant
   - Track tutees' progress

2. **Grading & Feedback**
   - Queue of exercises needing grading
   - View student answers
   - Provide correctness assessment
   - Write feedback comments
   - Cache graded answers for consistency

3. **Help Request Management**
   - View help requests from tutees
   - Answer questions asynchronously
   - See which students have viewed answers
   - Queue of unanswered requests

4. **Exercise Set Management**
   - Edit exercise sets they created
   - Add/remove lectures and units
   - Update descriptions and resources
   - Hide/show exercise sets

#### Instructor Features
1. **Course Management**
   - Create new courses
   - Define course descriptions
   - Delete courses (if empty)
   - Hide/show courses

2. **Exercise Set Management**
   - Create exercise sets with variants (normal, fast, slow)
   - Organize by lectures and units
   - Link to external resources (slides, handouts)
   - Define exercises by URL
   - Manage multiple variants

3. **Tutor Oversight**
   - View tutors under supervision
   - Monitor overall progress
   - Access grading interface
   - See all submissions

4. **Platform Administration**
   - Set other users to tutor role
   - Set own role to instructor
   - Access testing/development methods

### Exercise Types & Capabilities

#### 1. Truth Table Exercises (`/ex/tt/...`)
**Purpose**: Evaluate logical validity, equivalence, and semantic properties

**URL Structure**:
- Single sentence: `/ex/tt/qq/A∧B`
- Multiple sentences: `/ex/tt/qq/A|B|A∧B`
- Argument: `/ex/tt/from/A∧B|C/to/A`

**Student Task**: Construct truth table, determine:
- Tautology / Contradiction / Contingency
- Logical equivalence
- Argument validity

**Auto-Grading**: ✓ Yes (machine evaluates logical properties)

#### 2. Proof Exercises (`/ex/proof/...`)
**Purpose**: Write formal proofs in natural deduction

**URL Structure**: `/ex/proof/from/{premises}/to/{conclusion}`

**Student Task**: Write proof using logical rules (∧Intro, ∧Elim, ∨Intro, ∨Elim, →Intro, →Elim, ¬Elim, RAA, etc.)

**Auto-Grading**: ✓ Yes (validates proof structure and rule application)

**Dialect Support**: Proof Notation Format (PNF), other dialects possible

#### 3. Translation Exercises (`/ex/trans/...`)
**Purpose**: Translate between natural language and first-order logic

**URL Structure**: 
- NL to FOL: `/ex/trans/from/all dogs bark/to/`
- FOL to NL: `/ex/trans/from/to/∀x(Dog(x)→Barks(x))/`

**Student Task**: Provide correct translation

**Auto-Grading**: ✓ Yes (semantic equivalence checking)

#### 4. Create World Exercises (`/ex/create/...`)
**Purpose**: Construct possible worlds/situations satisfying constraints

**URL Structure**: 
- Create situation: `/ex/create/qq/Happy(a)|¬Happy(a)`
- Create counterexample: `/ex/create/from/{premises}/to/{conclusion}`

**Student Task**: Define predicates, specify extensions for predicates, assign properties

**Auto-Grading**: ✓ Yes (checks constraints satisfied)

#### 5. Counterexample Exercises (`/ex/counter/...`)
**Purpose**: Find situations making premises true but conclusion false

**URL Structure**: `/ex/counter/from/A|B|C/to/D`

**Student Task**: Create world where premises true but conclusion false

**Auto-Grading**: ✓ Yes (automated world evaluation)

#### 6. True/False Exercises (`/ex/TorF/...`)
**Purpose**: Quick assessment of logical understanding

**URL Structure**: `/ex/TorF/{sentence}`

**Student Task**: Determine truth value in context

**Auto-Grading**: ✓ Yes (simple boolean check)

#### 7. Scope Exercises (`/ex/scope/...`)
**Purpose**: Understand quantifier scope and binding

**URL Structure**: `/ex/scope/{formula}`

**Student Task**: Identify variable binding, scope relationships

**Auto-Grading**: ✓ Yes (formula analysis)

#### 8. Tree Exercises (`/ex/tree/...`)
**Purpose**: Parse trees, syntax trees, proof trees

**URL Structure**: `/ex/tree/{formula or proof}`

**Student Task**: Construct tree representation

**Auto-Grading**: ✓ Yes (tree validation)

#### 9. Question Exercises (`/ex/q/...`)
**Purpose**: Short-answer questions (free form)

**URL Structure**: `/ex/q/{question}`

**Student Task**: Text response

**Auto-Grading**: ✗ No (requires human grading)

### Grading & Feedback System

#### Machine Grading Process
1. **Client-side evaluation** (in browser, real-time)
   - Exercise system validates answer syntax
   - Evaluates truth tables
   - Checks proof rules
   - Generates machine feedback

2. **Hash computation**
   - Answer normalized to canonical form
   - Hash computed for comparison

3. **Cache lookup**
   - Check GradedAnswers collection
   - If matching answer exists and was graded by human: apply cached grade

4. **Server submission**
   - Send submission to server
   - Persist to SubmittedExercises collection
   - Auto-apply feedback if cache hit

#### Human Grading Process
1. **Tutor views submission**
   - Exercise, student answer, machine feedback

2. **Tutor provides feedback**
   - Correctness assessment (true/false)
   - Written feedback comment

3. **Feedback storage**
   - Stored in SubmittedExercises.humanFeedback
   - Also cached in GradedAnswers by answer hash

4. **Future submissions**
   - When student/other submits identical answer
   - Cached grade auto-applied
   - Consistent evaluation, faster grading

#### Feedback Types
- **Machine Feedback**: Automatic, immediate (truth tables, proofs, translations)
- **Human Feedback**: Tutor-provided, cached for reuse (complex exercises, short answers)
- **Unseen Feedback**: Notifications when feedback available

### Progress Tracking System

#### Submission Records
- One document per student per exercise
- Upsert pattern (latest submission overwrites)
- Tracks answer submission time
- Records machine feedback
- Tracks human feedback review status

#### Progress Queries
1. **Student's progress** → Submissions for student across all exercises
2. **Exercise progress** → All submissions for specific exercise
3. **Unseen feedback** → Submissions with feedback not yet reviewed by student
4. **Ungraded exercises** → Submissions without human feedback

#### Progress Display
- Dashboard shows enrolled exercise sets
- List of exercises with status (not submitted / submitted / graded)
- "Resume from last exercise" button
- Unseen feedback notifications

### Help Request System

#### Request Creation
1. Student submits help request on specific exercise
2. Includes:
   - Question/help description
   - Exercise reference
   - Whether student reviewed slides (checkbox)
   - Whether student read textbook (checkbox)
   - Links to student's submitted answer

#### Tutor Workflow
1. View queue of unanswered help requests
2. Read student question in context
3. Provide written answer
4. Mark request as answered

#### Student Workflow
1. View own help requests
2. See tutor answers
3. Mark as read when viewed
4. Can resubmit help request if needed

#### Data Persistence
- Requests stored with question, answer, timestamps
- Tutor name cached (denormalized)
- Student's assigned tutor email cached
- Enables filtering/routing

---

## TECHNICAL ARCHITECTURE

### Client-Server Architecture

#### Client (Browser)

**Responsibilities:**
- User interface rendering (Jade templates)
- User interaction handling
- Exercise completion (answering exercises)
- Machine grading of supported exercise types
- Routing (FlowRouter)
- Real-time data synchronization (Meteor DDP)

**Key Components:**
- `ApplicationLayout` - Root template
- Exercise templates: `exerciseSets.html.jade`, exercise type templates in `client/ex/`
- Grading interface: `exercisesToGrade.html.jade`
- Help system: `helpRequestsToAnswer.html.jade`
- Dashboard: `main.html.jade`

**Libraries:**
- AWFOL (first-order logic)
- Truth Table Engine
- Possible Worlds Creator
- jQuery, Materialize CSS

#### Server (Meteor + Node.js)

**Responsibilities:**
- Authentication & authorization
- Meteor method execution
- Data publication/subscription
- Business logic enforcement
- Database operations
- Help request routing

**Key Components:**
- `love-logic.coffee` - Core methods (33 total)
- `server/publish.coffee` - Data publications (25+ total)
- `server/at_server_config.coffee` - Account configuration

**Data Access Control:**
- Publish functions filter data per user role
- Methods check authorization before operations
- Denormalized fields prevent unauthorized access

### Database Design Overview

#### Collections (7 Total)

| Collection | Purpose | Growth | Documents |
|------------|---------|--------|-----------|
| users | Authentication, profiles | Slow | 100s-1000s |
| courses | Course catalog | Slow | 10s-100s |
| exercise_sets | Exercise grouping | Slow | 100s |
| submitted_exercises | Student work | Fast | 1000s-100000s |
| subscriptions | Enrollments | Medium | 100s-1000s |
| graded_answers | Grading cache | Medium | 100s-10000s |
| help_request | Help Q&A | Medium | 100s-10000s |

#### Key Relationships

```
users (1) ──── (M) submitted_exercises
         ├──── (M) exercise_sets (owner)
         ├──── (M) subscriptions
         ├──── (M) graded_answers
         ├──── (M) help_request (requester)
         └──── (M) help_request (answerer)

courses (1) ──── (M) exercise_sets
        └──── (M) subscriptions

exercise_sets (1) ──── (M) subscriptions
              ├──── (M) submitted_exercises (via exerciseId)
              ├──── (M) help_request (via exerciseId)
              └──── (M) graded_answers (via exerciseId)

submitted_exercises (1) ──── (M) help_request
                     └──── (M) graded_answers (via answerHash)
```

### API Design Overview

#### Meteor Methods (33 Total)

**User Management (7 methods)**
- `seminarTutorExists(email)` - Check if tutor exists
- `updateSeminarTutor(email)` - Assign tutor to self
- `updateInstructor(email)` - Assign instructor to self
- `updateEmailAddress(email)` - Change email
- `makeMeATutor()` - Opt into tutor role
- `makeMeNotATutor()` - Opt out of tutor role
- `makeMeAnInstructor()` / `makeMeNotAnInstructor()`

**Course Management (2 methods)**
- `createNewCourse(name, description)` - Create course
- `deleteCourse(name)` - Delete course (if empty)

**Exercise Set Management (8 methods)**
- `createNewExerciseSet(courseName, variant, description)` - Create set
- `pasteExerciseSet(newExSet)` - Duplicate set
- `deleteExerciseSet(courseName, variant)` - Delete set
- `showExerciseSet(exerciseSetId)` / `hideExerciseSet(exerciseSetId)` - Toggle visibility
- `upsertExerciseSet(exerciseSet)` - Save full set
- `updateExerciseSetField(exerciseSet, toSet)` - Update field
- `exerciseSetHasFollowers(courseName, variant)` - Check enrollment

**Exercise Submission (3 methods)**
- `submitExercise(exercise)` - Submit answer
- `getCorrectAnswer(exerciseId)` - Get answer key (for instructors)
- `subscribeToExerciseSet(courseName, variant, exerciseSetId)` - Enroll in set
- `unsubscribeToExerciseSet(courseName, variant)` - Unenroll

**Grading (6 methods)**
- `addHumanFeedback(submission, feedback)` - Grade exercise
- `addGradedExercise(...)` - Cache graded answer
- `_removeGradedExercises(exerciseId)` - Delete cache (admin)
- `studentSeenFeedback(exercise)` - Mark feedback as seen
- `getExercisesToGrade(limitToSubscribers)` - Get grading queue

**Help Requests (4 methods)**
- `createHelpRequest(doc)` - Student asks for help
- `answerHelpRequest(helpReq, answer)` - Tutor answers
- `studentSeenHelpRequestAnswer(helpReq)` - Mark answer as seen

**Analytics (3 methods)**
- `getNofUsers()` - Total user count
- `getNofUsersWithSeminarTutor(domain)` - Count users by tutor domain
- `getNofSubmittedExercises()` - Total submissions
- `getNofSubmittedExercisesNoResubmits()` - Unique student submissions

### Authentication System Overview

#### Registration Flow
1. User visits `/sign-up`
2. Enters: email, password, full name, accepts terms
3. Email uniqueness validated (case-insensitive)
4. Account created in `users` collection
5. User profile initialized with name

#### Login Flow
1. User visits `/sign-in`
2. Enters email (case-insensitive) and password
3. Meteor validates credentials
4. Session established
5. Redirect to home dashboard

#### Role Assignment
- By default: user is student
- `makeMeATutor()` method: user opts in as tutor
- Admin sets `profile.is_tutor` or assigns via email-based lookup
- Instructor role similarly managed

#### Authorization Strategy
- Publish functions filter data per user role
- Methods check user ID matches before operations
- Tutor-tutee relationship via email matching
- Instructor-tutor relationship via email matching

### UI/UX Overview

#### Main Pages/Templates

**Public Pages (Unauthenticated)**
- `/sign-up` - Registration form (AccountsTemplates)
- `/sign-in` - Login form (AccountsTemplates)
- `/forgotPassword` - Password reset (AccountsTemplates)
- `/verify-email` - Email verification (optional)

**Student Pages (Authenticated)**
- `/` (home) - Dashboard with enrolled exercise sets
- `/ex/{type}/{params}` - Exercise pages
- `/explore` - Browse available courses
- `/my-progress` - View all submissions
- `/help-requests` - Manage help requests

**Tutor Pages**
- `/grade/{exerciseId}` - Grade submissions for exercise
- `/exercisesToGrade` - Queue of exercises needing grades
- `/my-tutees` - View assigned students
- `/help-requests-to-answer` - Queue of help requests
- `/tutee-progress` - Monitor tutee progress

**Instructor Pages**
- `/exercise-sets` - Manage exercise sets
- `/exercise-sets/{courseId}` - Edit specific set
- `/courses` - Manage courses
- `/all-users` - User administration

#### Design System
- **Framework**: Materialize CSS (Material Design)
- **Icons**: Font Awesome + Material Design Icons
- **Responsive**: Mobile-first design (Materialize grid)
- **Components**: Cards, modals, collections, navigation

#### Browser Compatibility
- Requires CSS Flexbox support (flexWrap)
- Requires CSS Background-Blend-Mode support
- Fallback: `/oldBrowserSorry` page

---

## IMPLEMENTATION ROADMAP

### Phase 1: Setup & Infrastructure

**Duration**: 1-2 weeks  
**Deliverables**: Development environment, deployment infrastructure

**Tasks:**
1. Set up development environment
   - Install Node.js 0.10.40 (or use nvm)
   - Install Meteor 1.2.1
   - Clone repository

2. Configure local MongoDB
   - Install MongoDB 3.2+
   - Configure replica set (local: `rs0`)
   - Verify connection

3. Install Meteor packages
   - Run `meteor install`
   - All 105 packages from `.meteor/versions`

4. Configure environment variables
   - Create `.env` or config files
   - Set `MONGO_URL` for development
   - Set `ROOT_URL` for Meteor
   - reCAPTCHA keys (optional)

5. Set up deployment infrastructure (production)
   - Choose hosting: AWS, DigitalOcean, etc.
   - Set up MongoDB Atlas or self-managed replica set
   - Configure SSL/TLS certificates
   - Set up deployment process (Meteor Up)

**Validation:**
- `meteor` starts without errors
- Database connection successful
- DDP sync working (Meteor messages in console)

### Phase 2: Data Models & Authentication

**Duration**: 1-2 weeks  
**Deliverables**: Database schema, user authentication system

**Tasks:**
1. Create MongoDB collections
   - `Courses` with unique index on name
   - `ExerciseSets` with composite index on (courseName, variant)
   - `SubmittedExercises` with indexes on (owner, exerciseId)
   - `Subscriptions` with index on owner
   - `GradedAnswers` with index on exerciseId
   - `HelpRequest` with indexes on requesterId, exerciseId
   - Indexes documented in MONGODB_SCHEMA.md

2. Implement authentication
   - Configure `accounts-password`
   - Set up AccountsTemplates configuration
   - Routes: `/sign-up`, `/sign-in`, `/reset-password`
   - User profile fields: name, email, is_seminar_tutor, is_instructor

3. Create user role system
   - Student (default)
   - Seminar tutor (profile.is_seminar_tutor)
   - Instructor (profile.is_instructor)
   - Implement role checking helpers

4. Set up authorization layer
   - Publish functions filtering by role
   - Method authorization checks
   - Tutor-tutee relationship via email matching

**Validation:**
- Can register new user
- Can login with email/password
- User profile created with fields
- Role assignment works

### Phase 3: Core Exercise Types

**Duration**: 3-4 weeks  
**Deliverables**: Exercise engines for all 9 types, submission handling

**Tasks:**
1. Implement truth table exercise engine
   - UI for creating truth tables
   - Parser for table completion
   - Validation of logical properties
   - Machine grading logic

2. Implement proof exercise engine
   - Proof editor interface
   - Rule validation
   - Line numbering and references
   - Proof correctness checking

3. Implement translation exercises
   - NL to FOL converter interface
   - FOL to NL converter interface
   - Semantic equivalence checking
   - Machine grading

4. Implement create world exercises
   - Possible world builder interface
   - Predicate extension definition
   - World visualization
   - Constraint satisfaction checking

5. Implement counterexample exercises
   - Build on world creation
   - Argument validation
   - Counterexample detection

6. Implement other exercise types
   - True/False (simple boolean)
   - Scope (formula analysis)
   - Trees (tree construction)
   - Questions (text answer)

7. Create exercise submission system
   - `submitExercise()` method
   - Answer persistence
   - Machine feedback generation
   - Hash computation for caching

**Validation:**
- Each exercise type accessible via URL
- Submissions stored in database
- Machine feedback displays
- Hashes computed and cached

### Phase 4: UI & User Workflows

**Duration**: 2-3 weeks  
**Deliverables**: Complete user interfaces, navigation flows

**Tasks:**
1. Build student interface
   - Home dashboard showing enrolled exercises
   - Exercise browsing and completion flow
   - Progress tracking view
   - Help request interface
   - Profile settings

2. Build tutor interface
   - Tutee list and management
   - Exercises to grade queue
   - Grading interface with feedback entry
   - Help request answer queue
   - Tutee progress monitoring

3. Build instructor interface
   - Course management (create, edit, delete)
   - Exercise set management
   - Variant management (normal, fast, slow)
   - User management (promote tutors)
   - Analytics/overview

4. Implement navigation system
   - FlowRouter routes for all pages
   - Navigation menu based on role
   - Breadcrumb navigation
   - Login/logout flows

5. Create responsive design
   - Materialize grid system
   - Mobile-friendly layouts
   - Accessible components
   - Browser compatibility testing

**Validation:**
- All pages accessible via proper URLs
- Navigation between pages works
- Role-based menus correct
- Mobile view acceptable

### Phase 5: Advanced Features

**Duration**: 2-3 weeks  
**Deliverables**: Grading cache, help system, analytics

**Tasks:**
1. Implement grading cache system
   - `GradedAnswers` collection management
   - Answer hash matching
   - Cache hit detection
   - Auto-apply cached grades

2. Implement human feedback system
   - `addHumanFeedback()` method
   - Feedback storage
   - Cache population
   - Feedback notifications

3. Implement help request system
   - `createHelpRequest()` method
   - Help answer interface
   - Answer caching
   - Notification system

4. Build analytics & reporting
   - Exercise to grade queue
   - Student progress summaries
   - Tutor workload analysis
   - Help request tracking

5. Implement notification system
   - Unseen feedback alerts
   - Unanswered help request notifications
   - Grading queue management

**Validation:**
- Grading cache working (cached grades applied)
- Help requests answerable and cached
- Notifications displaying correctly
- Analytics queries performant

### Phase 6: Deployment & Optimization

**Duration**: 1-2 weeks  
**Deliverables**: Production deployment, performance tuning

**Tasks:**
1. Optimize database
   - Verify all indexes created
   - Test query performance
   - Implement query optimization
   - Monitor slow queries

2. Optimize client/server
   - Minification and bundling
   - Lazy loading where appropriate
   - Connection pooling
   - Cache headers

3. Set up monitoring
   - Error tracking (Sentry or similar)
   - Performance monitoring (APM)
   - Database monitoring
   - User analytics

4. Deploy to production
   - Set up deployment pipeline (Meteor Up)
   - Configure SSL certificates
   - Set up database backups
   - Configure log aggregation

5. Load testing
   - Test with expected user load
   - Stress test database
   - Monitor server resources
   - Identify bottlenecks

6. Documentation & runbooks
   - Deployment documentation
   - Troubleshooting guides
   - Scaling procedures
   - Backup/restore procedures

**Validation:**
- Production site accessible
- Performance metrics acceptable
- Backups working
- Monitoring alerts functional

---

## DOCUMENTATION INDEX

This section provides an overview and guide to all supporting documentation files. Read these files in order for increasing levels of detail.

### Quick Start Documents

**1. README.md** (in `love-logic-server/` directory)
- Overview of exercise types with URL examples
- Quick links to external resources
- Copyright and contact information

### Core Technical Documentation

**2. MONGODB_SCHEMA.md** (Comprehensive Database Reference)
- **Size**: 33 KB, 872 lines
- **Purpose**: Complete database schema specification
- **Contents**:
  - Overview of all 7 collections
  - Detailed field documentation with data types
  - Sample documents for each collection
  - Relationship diagrams and cardinality
  - Complete index listing with purposes
  - Authorization and access control rules
  - Denormalization patterns
  - Query performance considerations
- **Best for**: Database designers, backend developers, DBAs

**3. SCHEMA_QUICK_REFERENCE.md** (Developer Cheat Sheet)
- **Size**: 5.1 KB
- **Purpose**: Quick lookup for common tasks
- **Contents**:
  - Collections at a glance
  - Field reference quick lookup
  - Common query patterns
  - Authorization quick checks
  - Performance issues and fixes
  - Migration checklist
- **Best for**: Developers during coding, quick lookups

**4. SCHEMA_INDEX.md** (Navigation Guide)
- **Size**: 7.8 KB
- **Purpose**: Index and cross-reference guide
- **Contents**:
  - Quick facts about each collection
  - Key methods organized by purpose
  - Collection file locations in codebase
  - Important notes about upserts
- **Best for**: Navigation, finding information

**5. API_METHODS_ROUTES.md** (API Reference)
- **Size**: 69 KB
- **Purpose**: Complete API documentation
- **Contents**:
  - All 33 Meteor methods with signatures
  - Parameters, return values, authorization requirements
  - Business logic for each method
  - All FlowRouter routes
  - 25+ Meteor publications with subscription requirements
  - Client-side helper methods
- **Best for**: Backend developers, API integration

**6. AUTHENTICATION_AUTHORIZATION.md** (Security & Access Control)
- **Size**: 32 KB
- **Purpose**: Complete auth system documentation
- **Contents**:
  - User account system and registration
  - User roles and permissions
  - User relationships (tutor-tutee, instructor-tutor)
  - Authorization patterns and rules
  - Access control implementation
  - Security considerations
- **Best for**: Security engineers, role-based access implementation

**7. UI_COMPONENTS_FLOWS.md** (Frontend Reference)
- **Size**: 54 KB
- **Purpose**: UI components and user workflows
- **Contents**:
  - Application layout and structure
  - Key pages and templates
  - Exercise types and interfaces
  - Reusable UI components
  - User workflows (student, tutor, instructor)
  - UI libraries and styling
  - Client-side state management
  - Directory structure
- **Best for**: Frontend developers, UI designers

**8. EXERCISE_GRADING_LOGIC.md** (Core Intellectual Property)
- **Size**: 59 KB
- **Purpose**: Complete grading system specification
- **Classification**: Core IP (automated grading algorithms)
- **Contents**:
  - Architecture overview of grading system
  - 9 exercise types with URLs and grading logic
  - Answer submission and grading flow
  - GradedAnswers cache system
  - Core algorithms and validation
  - Exercise metadata and collection structure
  - Dialect support and versioning
- **Best for**: Exercise type developers, grading logic implementers

**9. UTILITIES_AND_HELPERS.md** (Helper Functions Reference)
- **Size**: 57 KB
- **Purpose**: Utility functions and helper libraries
- **Contents**:
  - Client-side utilities (ix.coffee)
  - Shared utilities (wy.coffee)
  - Third-party libraries documentation
  - Logic engine components
  - URL encoding and exercise parameters
  - Common patterns and functions
  - Component-specific utilities
- **Best for**: Frontend developers, library documentation

**10. DEPLOYMENT_CONFIGURATION.md** (Infrastructure & DevOps)
- **Size**: 33 KB
- **Purpose**: Deployment and infrastructure guide
- **Contents**:
  - Technology stack (105 packages)
  - Meteor packages with versions
  - Environment variables
  - Database configuration (MongoDB replica sets)
  - Deployment configurations (Meteor Up)
  - Server and client configuration
  - Static assets and build process
  - Development setup guide
  - Quick start guides for common tasks
- **Best for**: DevOps engineers, system administrators, deployment

### Summary Documents

**11. DOCUMENTATION_SUMMARY.txt** (This directory)
- Summary of all documentation created
- Key metrics (7 collections, 33 methods, etc.)
- Completeness assessment
- Where to find information

**12. AUTHENTICATION_AUTHORIZATION_SUMMARY.txt** (This directory)
- Summary of authentication system
- User roles and relationships
- Key authorization patterns

### Special Documentation

**13. Record of Invention.docx** (Business/Legal)
- Original project documentation
- Invention record and claims
- Business context

---

## KEY SPECIFICATIONS SUMMARY

### Database Specifications

- **7 MongoDB Collections** (6 custom + 1 Meteor built-in)
  - Courses (slow growth, ~10s-100s)
  - ExerciseSets (slow growth, ~100s)
  - SubmittedExercises (fast growth, ~1000s-100000s)
  - Subscriptions (medium growth, ~100s-1000s)
  - GradedAnswers (medium growth, capped by unique answers)
  - HelpRequest (medium growth, ~100s-10000s)
  - users (Meteor, slow growth, ~100s-1000s)

- **20+ Indexes** for query optimization
  - Unique indexes on: Courses.name, ExerciseSets.(courseName,variant)
  - Performance-critical indexes on: owner, exerciseId
  - Composite indexes for complex queries

- **Advanced Patterns**:
  - Upsert pattern (one submission per student per exercise)
  - Denormalization for performance (name, email, tutor info)
  - Hash-based caching (answer deduplication)
  - Email-based relationships (tutor-tutee assignments)

### API Specifications

- **33 Meteor Methods** (RPC endpoints)
  - 7 user management methods
  - 2 course management methods
  - 8 exercise set management methods
  - 3 submission methods
  - 6 grading methods
  - 4 help request methods
  - 3 analytics methods

- **80+ FlowRouter Routes** (client-side navigation)
  - Public routes: sign-up, sign-in, verify-email
  - Student routes: exercises, progress, help requests
  - Tutor routes: grading, tutee management
  - Instructor routes: course management, user administration

- **25+ Meteor Publications** (subscription channels)
  - Public: courses, exercise sets
  - Student: own submissions, progress data
  - Tutor: tutee data, help requests, grading queues
  - Instructor: all administrative data

### Exercise Type Specifications

- **9 Exercise Types**:
  1. Truth Table (tt) - Logical validity
  2. Proof (proof) - Natural deduction
  3. Translation (trans) - NL ↔ FOL
  4. Create (create) - Possible worlds
  5. Counterexample (counter) - Find violations
  6. True/False (TorF) - Boolean assessment
  7. Scope (scope) - Quantifier analysis
  8. Tree (tree) - Parse/proof trees
  9. Question (q) - Free-form answers

- **Auto-Grading Support**: 8 types (all except questions)
- **Machine Feedback**: Immediate for auto-gradable types
- **Human Feedback**: For all types, cached for reuse

### User Role Specifications

- **3 User Roles**:
  1. **Student** (default)
     - Submit exercises, request help, track progress
  2. **Seminar Tutor**
     - Grade exercises, answer help requests
     - Manage assigned tutees
  3. **Instructor**
     - Manage courses, exercise sets, tutors
     - Create variants and content

- **Hierarchical Relationships**:
  - Instructor → manages → Tutors
  - Tutor → manages → Students (tutees)
  - Relationships stored as email-based profile fields

---

## CRITICAL COMPONENTS

### 1. Automated Grading Algorithms (IP)

**Location**: `EXERCISE_GRADING_LOGIC.md`, `client/ex/` directories

**Complexity**: HIGH (core intellectual property)

**Components**:
- **Truth Table Evaluator** - Evaluates tautology, contradiction, equivalence
- **Proof Validator** - Validates natural deduction proofs
- **FOL Parser** - Parses first-order logic formulas
- **World Evaluator** - Checks formula truth in possible worlds

**Performance**: Real-time on client, cached on server

**Criticality**: CRITICAL - Core feature, proprietary technology

### 2. Answer Caching System

**Location**: `GradedAnswers` collection, `addGradedExercise()` method

**Complexity**: MEDIUM

**Purpose**: Enable auto-grading of identical answers after human grading

**Flow**:
1. Tutor grades answer, marks correctness
2. Answer hash computed and cached
3. New submission: hash computed
4. Cache lookup: if match found, apply cached grade
5. No lookup match: mark for human grading

**Benefit**: Consistency, speed, reduced tutor workload

**Criticality**: HIGH - Enables scalability

### 3. Authorization Hierarchy

**Location**: Publish functions, method authorization checks

**Complexity**: MEDIUM

**Structure**:
```
Instructor
  ├─ view tutors under supervision
  ├─ view all student data
  └─ manage course content
     
Tutor
  ├─ view assigned tutees (via email match)
  ├─ view tutee submissions
  ├─ grade tutee exercises
  ├─ answer tutee help requests
  └─ manage own exercise sets
     
Student
  ├─ view own submissions
  ├─ submit exercises
  ├─ request help
  └─ view own help requests
```

**Implementation**: Email-based role matching + publish filters

**Criticality**: CRITICAL - Security/access control

### 4. Exercise URL Encoding

**Location**: Utilities in `wy.coffee`, URL parsing in templates

**Complexity**: MEDIUM

**Purpose**: Define exercises as URLs (no database lookups needed)

**Format**: `/ex/{type}/{params}`

**Examples**:
- `/ex/tt/qq/A∧B` - Truth table for "A and B"
- `/ex/proof/from/A|B/to/A∨B` - Proof exercise
- `/ex/create/from/P(a)/to/∃xP(x)` - Create world

**Encoding**: URL-safe encoding of logical formulas

**Benefits**: 
- Stateless exercise definition
- Easy sharing and linking
- Versioning through URL parameters

**Criticality**: HIGH - Core architecture

### 5. Truth Table Logic

**Location**: `client/lib/truth_table/`, `EXERCISE_GRADING_LOGIC.md`

**Complexity**: HIGH (mathematical)

**Purpose**: Evaluate truth values, detect logical properties

**Capabilities**:
- Sentence evaluation (tautology, contradiction, contingency)
- Equivalence checking (logical equivalence between sentences)
- Argument validity (check if conclusion follows from premises)
- Model finding (find truth value assignments satisfying constraints)

**Performance**: O(2^n) for n variables (exponential)

**Optimization**: 
- Limit to ~10 variables (2^10 = 1024 rows)
- Client-side computation (parallelizable)

**Criticality**: CRITICAL - Core exercise type

### 6. Proof Validation

**Location**: `client/ex/proof/`, `EXERCISE_GRADING_LOGIC.md`

**Complexity**: HIGH (formal logic)

**Purpose**: Validate natural deduction proofs

**Rules Supported**:
- Conjunction: ∧Intro, ∧Elim
- Disjunction: ∨Intro, ∨Elim
- Implication: →Intro, →Elim
- Negation: ¬Intro, ¬Elim
- Quantifiers: ∀Intro, ∀Elim, ∃Intro, ∃Elim
- Reductio: RAA (Reductio Ad Absurdum)
- Equivalence: ↔Intro, ↔Elim
- Other: Repeat, Lemma

**Validation**:
- Line numbering and references
- Rule applicability
- Conclusion correctness

**Dialect**: Proof Notation Format (PNF) - customizable

**Criticality**: CRITICAL - Flagship exercise type

### 7. World Creation

**Location**: `client/lib/possible_world/`, `EXERCISE_GRADING_LOGIC.md`

**Complexity**: HIGH (model theory)

**Purpose**: Build possible worlds satisfying logical constraints

**Components**:
- Domain specification (objects)
- Predicate interpretation (define true/false)
- Constant assignment
- Relation definition

**Validation**:
- Formula satisfaction checking
- Constraint verification
- Counterexample detection

**UI**: Visual world builder (visual elements for objects/predicates)

**Criticality**: CRITICAL - Advanced exercise type

---

## NON-FUNCTIONAL REQUIREMENTS

### Performance Requirements

**Response Times**:
- Exercise page load: < 2 seconds
- Exercise submission: < 1 second
- Grade view load: < 2 seconds
- Progress update: real-time (DDP sync)

**Throughput**:
- Support 1000+ concurrent users
- Handle 100+ submissions/minute at peak
- Serve 50+ grading operations/minute

**Scalability**:
- Horizontal scaling via multiple Meteor instances (behind load balancer)
- MongoDB replica set for replication
- Database sharding for very large deployments (100000+ submissions)

**Database**:
- Query response time: < 100ms (indexed queries)
- Slow query: > 1s (flag for optimization)
- Index size: < 10% of data size (typical)

### Security Requirements

**Authentication**:
- Password minimum 8 characters (configurable)
- Passwords hashed with bcrypt
- Session token-based (Meteor)
- HTTPS/TLS required in production

**Authorization**:
- Role-based access control (RBAC)
- Publish functions enforce data access
- Methods check user ID before operations
- No shared access (each user separate data)

**Data Protection**:
- Sensitive fields encrypted at rest (optional)
- Student answers not visible to other students
- Tutor assignments confidential
- Help questions private

**Audit Trail** (Optional):
- Log all submissions
- Log all grades/feedback
- Log help request responses
- Retention: 1+ years

### Scalability Considerations

**Growth Vectors**:
- SubmittedExercises: 1 per student per exercise per variant
  - 1000 students × 200 exercises = 200K submissions
  - 10000 students = 2M submissions (moderate)
- GradedAnswers: capped by unique answers (lower than submissions)
- HelpRequest: 1-10 per student (much lower volume)

**Scaling Strategies**:
1. **Database**:
   - Create indexes on query fields (critical)
   - Use replica set for read scaling
   - Shard by exerciseId or owner for very large installations
   - Archive old submissions

2. **Server**:
   - Scale horizontally (multiple Meteor instances)
   - Load balancer (sticky sessions recommended)
   - Redis for session storage (optional)
   - CDN for static assets

3. **Data**:
   - Pagination for large lists
   - Lazy load submissions (only current exercises)
   - Aggregate analytics (not real-time)

### Browser Compatibility

**Required Support**:
- Chrome 40+ (2014+)
- Firefox 35+ (2014+)
- Safari 8+ (2014+)
- Edge 12+ (2015+)
- NOT: Internet Explorer (any version)

**Feature Detection**:
- CSS Flexbox (flexWrap)
- CSS Background-Blend-Mode
- JavaScript ES5+ (no IE8 support)

**Mobile**:
- iOS Safari 8+ (iPad/iPhone)
- Chrome Mobile (Android 4.4+)
- Responsive design (Materialize grid)

**Testing**:
- BrowserStack or similar for compatibility
- Mobile device testing (real devices)
- Graceful degradation for older browsers (optional)

### Accessibility

**WCAG Compliance**: AA level (target)
- Keyboard navigation
- Screen reader support
- Color contrast ratios
- Semantic HTML

**Features**:
- Alt text for images
- ARIA labels for components
- Focus indicators
- Readable fonts (14pt+)

---

## APPENDICES

### A. Glossary of Terms

**Answer Hash**: Hash of normalized answer content, used for cache lookups and deduplication

**AWFOL**: First-order logic parsing and evaluation library (client-side)

**Blaze**: Meteor's reactive templating system

**DDP**: Distributed Data Protocol (Meteor's real-time sync)

**Dialect**: Logic notation system (e.g., PNF - Proof Notation Format)

**ExerciseSet**: Grouped exercises by course and variant (normal, fast, slow)

**FlowRouter**: Client-side router for Meteor

**GradedAnswers**: Cache of graded answers for auto-grading identical submissions

**Help Request**: Student question on specific exercise, tutor answer

**Jade**: HTML templating language (alternative to Handlebars)

**Materialize CSS**: Material Design CSS framework

**Minimongo**: Client-side MongoDB simulation (Meteor)

**PNF**: Proof Notation Format (logic dialect)

**Publication**: Meteor mechanism for publishing data to clients (subscription channel)

**Replica Set**: MongoDB replication configuration (2+ copies of data)

**Seminar Tutor**: User role for tutor/seminar leader

**Spacebars**: Meteor templating syntax

**Submission**: Student's answer to an exercise, stored in SubmittedExercises

**Tutor-Tutee**: Relationship between tutor and assigned students (via email)

**Upsert**: MongoDB operation combining insert and update (insert if not exists, else update)

**Variant**: Exercise set difficulty level (normal, fast, slow)

**World** (Possible World): Specification of object domain and predicate truth values

---

### B. Technology Reference

**Core Technologies**:
- Meteor.js 1.2.1
- Node.js 0.10.40
- MongoDB 3.2+
- CoffeeScript (ECMAScript 5)

**Frontend Libraries**:
- jQuery 1.11.4
- Underscore 1.0.4
- Moment.js 2.12.0
- Blaze (Meteor templating)
- Spacebars (template syntax)

**UI/Styling**:
- Materialize CSS 0.97.5
- Font Awesome 4.5.0
- Jade (HTML templates)
- Stylus + SCSS (CSS)

**Routing & Layout**:
- FlowRouter 2.10.1
- Kadira Blaze Layout 2.3.0

**Authentication**:
- accounts-password (Meteor)
- UserAccounts (UI templates)

**Database**:
- MongoDB native driver
- Minimongo (client)
- Babel 5.8.24 (transpilation)

**Key Packages** (see DEPLOYMENT_CONFIGURATION.md for complete list):
- ~105 total Meteor packages
- All pinned to specific versions in `.meteor/versions`

---

### C. Migration Considerations

### Schema Migration Checklist

**Before Migration**:
- [ ] Backup all production data
- [ ] Test migration on staging environment
- [ ] Plan downtime window (if needed)
- [ ] Notify users of maintenance

**Data Validation**:
- [ ] Verify all collections exist
- [ ] Verify all indexes created
- [ ] Validate collection sizes
- [ ] Check document counts

**Consistency Checks**:
- [ ] Check foreign key references (users, tutors)
- [ ] Verify email uniqueness constraints
- [ ] Validate denormalized fields (names, emails)
- [ ] Check no orphaned documents

**Access Control**:
- [ ] Verify publication functions work
- [ ] Test method authorization
- [ ] Check role-based access
- [ ] Verify tutor-tutee relationships

### Data Migration (from Previous System)

**User Migration**:
1. Export user accounts from legacy system
2. Create corresponding users in new system
3. Migrate user profiles (name, email)
4. Preserve tutor assignments (via email)
5. Map instructor-tutor relationships

**Submission Migration**:
1. Export all student submissions
2. Map to new exerciseId format
3. Recalculate answer hashes
4. Update owner IDs (old to new)
5. Preserve timestamps and feedback

**Course/Exercise Migration**:
1. Define courses in new system
2. Create exercise sets by variant
3. Define exercises by URL (may require updates)
4. Validate all exercise URLs resolve

**Help Request Migration**:
1. Migrate help request documents
2. Update user references
3. Map to new submission IDs
4. Preserve answer history

### Rollback Plan

**If Something Goes Wrong**:
1. Stop application server
2. Restore MongoDB from backup
3. Verify data integrity
4. Restart application
5. Test critical workflows

**Point-in-Time Recovery**:
- Keep MongoDB backup retention: 30+ days
- Use replica set oplog for fine-grained recovery
- Enable binlog/journaling

---

## FINAL NOTES

### Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-14 | Initial comprehensive documentation |

### Key Contacts & Resources

**Original Author**: Stephen A. Butterfill  
**Project Date**: 2015  
**Current Maintainer**: [TBD]

**External Resources**:
- Meteor Documentation: https://docs.meteor.com/
- MongoDB Documentation: https://docs.mongodb.com/
- First-Order Logic Resources: See `logic-1.butterfill.com`

### Recommended Reading Order

**For Project Managers/Stakeholders**:
1. This MASTER_SPECIFICATION.md (Executive Summary section)
2. Project Overview section
3. Implementation Roadmap
4. Key Specifications Summary

**For New Developers**:
1. Project Overview
2. Technology Stack Summary
3. SCHEMA_QUICK_REFERENCE.md
4. MONGODB_SCHEMA.md (Collections Overview)
5. API_METHODS_ROUTES.md
6. EXERCISE_GRADING_LOGIC.md

**For Database Engineers**:
1. MONGODB_SCHEMA.md (entire document)
2. SCHEMA_QUICK_REFERENCE.md
3. DEPLOYMENT_CONFIGURATION.md (Database section)

**For DevOps/Infrastructure**:
1. DEPLOYMENT_CONFIGURATION.md (entire document)
2. Implementation Roadmap (Phase 6)
3. Migration Considerations

**For Frontend Developers**:
1. UI_COMPONENTS_FLOWS.md
2. API_METHODS_ROUTES.md (Publications section)
3. UTILITIES_AND_HELPERS.md

**For Security Review**:
1. AUTHENTICATION_AUTHORIZATION.md
2. MONGODB_SCHEMA.md (Authorization section)
3. Non-Functional Requirements (Security)

---

## DOCUMENT INFORMATION

**Document Name**: MASTER_SPECIFICATION.md  
**Purpose**: Comprehensive specification for project recreation from scratch  
**Target Audience**: Technical team, project managers, new developers  
**Maintenance**: Update quarterly or with major changes  
**Classification**: Internal (Technical)  
**Related Documents**: All other documentation files in this directory  

**Status**: COMPLETE  
**Date Created**: November 14, 2025  
**Last Modified**: November 14, 2025

---

*This document serves as the central point of reference for the entire Love Logic Server project. It synthesizes information from all other documentation files into a cohesive specification suitable for project management, new team member onboarding, and architectural decision-making.*

