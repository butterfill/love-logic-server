# Love Logic Server: UI Components, Templates, and User Flows Documentation

## Table of Contents
1. [Application Layout and Structure](#application-layout-and-structure)
2. [Key Pages and Templates](#key-pages-and-templates)
3. [Exercise Types](#exercise-types)
4. [Reusable UI Components](#reusable-ui-components)
5. [User Workflows](#user-workflows)
6. [UI Libraries and Styling](#ui-libraries-and-styling)
7. [Client-Side State Management](#client-side-state-management)
8. [Directory Structure](#directory-structure)

---

## Application Layout and Structure

### Main Application Layout (ApplicationLayout)

**File Location:** `/client/ApplicationLayout.html.jade` and `/client/ApplicationLayout.coffee`

**Purpose:** The root layout template for the entire application. All pages are rendered within this layout.

**Structure:**

```jade
template(name='ApplicationLayout')
  +header
  .container
    +Template.dynamic(template=main)
```

**Key Features:**
- Header with navigation bar
- Navigation brand logo "zoxiy (beta)"
- Dynamic content area that renders different templates based on current route
- User email display in navigation
- Browser compatibility warnings

### Navigation Header

**File Location:** `ApplicationLayout.html.jade` (lines 14-24)

**Components:**
- **Brand Logo:** "zoxiy (beta)" - home link
- **User Information:** Displays `currentUserEmail` 
- **Navigation Button:** `+atNavButton` for authentication
- **Browser Warning:** Displays if browser is not compatible (checks for flexWrap and backgroundBlendMode support)

**Helper Functions:**
```coffee
Template.header.helpers
  currentUserEmail: () -> # Returns user's email or empty string
  isBrowserNotCompatible: () -> # Checks browser compatibility
```

**Browser Compatibility Check:**
The application checks for:
- CSS `flexWrap` support (for modern layout)
- CSS `backgroundBlendMode` support
- Notifies users with old browsers to use `/oldBrowserSorry` page

### Responsive Design Considerations

**Grid System:** 
- Uses Materialize CSS grid system
- Breakpoints: `.col.s12` (small), `.col.m6` (medium), `.col.l4` (large)
- Example: `.col.s12.m6.l4` (12 cols small, 6 cols medium, 4 cols large)

**Components Used:**
- Materialize CSS cards (`.card`, `.card-content`, `.card-action`)
- Collections (`.collection`, `.collection-item`)
- Navigation (`nav`, `.nav-wrapper`)
- Modal forms (`MaterializeModal`)

---

## Key Pages and Templates

### 1. Home/Main Page (`/`)

**File Location:** `/client/main.html.jade` and `/client/main.coffee`

**Route:** `FlowRouter.route '/'`

**Purpose:** Dashboard for logged-in users showing:
- Subscribed exercise sets
- Last exercise resume link
- Tutor-specific links
- Instructor-specific links
- Card-based notifications and settings

**Key Sections:**

#### Exercise Subscriptions
- Lists exercises the student is subscribed to
- Shows "Resume from last exercise" button if available
- Quick edit links for owned exercise sets
- "Follow another exercise set" button to browse courses

#### Tutor Dashboard Links
- "Exercises to Grade" - exercises requiring grading
- "Help Requests to Answer" - student help requests with count
- "List of Tutees" - view all assigned tutees
- "Tutees' Progress" - analytics on tutee performance (all exercises and by specific sets)

#### Instructor Dashboard Links
- "List of Tutors" - manage tutors assigned to course(s)

#### Cards Section
Responsive cards (12/6/4 col breakpoints) showing:
1. **Exercises Card** - if no subscriptions, prompt to select exercise set
2. **Help Request Card** - if student has answered help requests
3. **Grades Card** - if student has new feedback to review
4. **Instructor Card** - set/change instructor (for tutors)
5. **Tutor Card** - assign/change seminar tutor
6. **Email Card** - displays and allows changing email address
7. **Backup Card** - link to view all submitted exercises
8. **Guides Card** - link to external zoxiy guide

**Data Requirements:**
- Meteor user authentication
- Subscriptions collection
- ExerciseSets collection
- SubmittedExercises collection
- HelpRequest collection
- User profile (seminar_tutor, instructor)

**Modals:**
- `changeTutorModal` - typeahead search for tutor selection
- `changeInstructorModal` - instructor email input
- `changeEmailModal` - email address textarea

**Helper Functions:**
```coffee
hasSubscriptions() # Boolean - user has subscribed to exercise sets
hasNoSubscriptions() # Boolean - opposite of above
subscriptions() # Array of Subscription objects
ownedExerciseSets() # Array of ExerciseSet objects owned by user
hasSeminarTutor() # Boolean - user has assigned tutor
seminarTutor() # Email of assigned tutor
nofHelpRequestsForTutor() # Count of help requests for this tutor
```

**Events:**
- `click #resume-last-exercise` - navigate to last exercise
- `click .changeSeminarTutor` - open tutor selection modal
- `click .changeInstructor` - open instructor modal
- `click .changeEmail` - open email change modal

---

### 2. Course Listing and Selection

#### Courses Page (`/courses`)

**File Location:** `/client/exerciseSets.html.jade` and `/client/exerciseSets.coffee`

**Route:** `FlowRouter.route '/courses'`

**Purpose:** Browse and subscribe to exercise sets

**Display:**
- List of all courses with descriptions
- "Create New Course" button (for instructors/tutors only)
- "Select an exercise set" action

**Modals:**
- `createNewCourseModal` - create new course with name and description

**Data Required:**
- Courses collection

#### Exercise Sets for Course (`/course/:courseName`)

**File Location:** `exerciseSets.html.jade` (lines 34-62)

**Route:** `FlowRouter.route '/course/:_courseName'`

**Purpose:** View all exercise set variants for a specific course

**Display:**
- Course name and description
- List of exercise set variants with descriptions
- Edit button (for instructors/tutors)
- "Create New Exercise Set" button (for instructors/tutors)
- Paste from clipboard button (if available)
- Delete course button (only when no exercise sets exist)

**Modals:**
- `createNewExerciseSetModal` - variant name and description

**Data Required:**
- Course details
- ExerciseSets collection filtered by courseName

---

### 3. Exercise Set Browsing and Management

#### Exercise Set View (`/course/:courseName/exerciseSet/:variant`)

**File Location:** Multiple files handle exercise set display

**Route:** Navigates to `exerciseSet` template

**Purpose:** View exercise structure and list all exercises

**Display:**
- Topic hierarchy (lectures and units)
- Exercise descriptions and links
- Reading materials and slides links
- Exercise difficulty indicators
- Help request status

**Modals:**
- `createNewExerciseSetModal` - for editing exercises
- Exercise builder for creating/editing exercises

#### Exercise Set Edit Mode (`/course/:courseName/exerciseSet/:variant/edit`)

**File Location:** `exerciseSets.html.jade` (exercise builder integration)

**Route:** `FlowRouter.route '/course/:_courseName/exerciseSet/:_variant/edit'`

**Purpose:** Manage exercise set structure and exercises

**Features:**
- Add/remove lectures and units
- Create/edit/delete exercises
- Drag-and-drop reordering (via gridstack)
- Exercise builder UI

---

### 4. Exercise Solving Interfaces

All exercises follow a common template structure with variations for exercise type.

#### Common Exercise Interface Structure

**Template Locations:** `/client/ex/[TYPE]_ex.html.jade`

**Common Elements (for all exercise types):**

```jade
template(name='[TYPE]_ex')
  +topic_header
  +[TYPE]_ex_display_question
  h5 Your answer:
  #[EDITOR] 
  .row: .col.s12
    p#feedback
  .row: .col.s12
    button#check[TYPE].btn.waves-effect.grey check
    button#reset[TYPE].btn.waves-effect.grey reset
    +submitted_answer
  +help_with_this_exercise
  .right
    +ask_for_help
    +submit_btn
  +next_exercise
```

**Key Template Fragments (from `/client/ex/template_fragments/`):**

1. **submitted_answer.html.jade** - Shows previous submission with feedback
2. **help.html.jade** - Help request interface
3. **next_exercise.html.jade** - Navigation to next exercise
4. **topic_header.jade** - Unit/topic information and grade button

---

#### 4.1 Tree Exercise (`/ex/tree/*`)

**File Location:** `/client/ex/tree_ex.html.jade` and `/client/ex/tree_ex.coffee`

**Purpose:** Create semantic tableaux (proof trees) for logical validity testing

**Types:**
- Proof tree for argument validity: `/ex/tree/require/[requirements]/from/[premises]/to/[conclusion]`
- Tree for sentence consistency: `/ex/tree/require/[requirements]/qq/[sentences]`

**Answer Structure:**
- Tree proof (nested structure with nodes and branches)
- Optional: TorF answer about validity/consistency
- Optional: stateIfValid/stateIfConsistent requirements

**UI Components:**
- **Editor:** Treant.js based visual tree editor in `#treeEditor`
- **Buttons:**
  - `#checkProof` - validate tree structure
  - `#resetProof` - clear the tree
  - `#convert-to-symbols` - convert natural language to logical symbols
- **TorF Questions:** If validity/consistency determination required

**Data Context:**
```coffee
premises: () # Array of premise sentences
conclusion: () # Single conclusion sentence
requireStateIfValid: () # Boolean
requireStateIfConsistent: () # Boolean
requireComplete: () # Boolean - tree must be complete
requireClosed: () # Boolean - tree must be closed
```

**File References:**
- `/client/lib/treant_dependencies/` - tree visualization library

---

#### 4.2 True/False Exercise (`/ex/TorF/*`)

**File Location:** `/client/ex/TorF_ex.html.jade` and `/client/ex/TorF_ex.coffee`

**Purpose:** Evaluate truth values of sentences in given contexts

**Types:**
- Argument validity: `/ex/TorF/from/[premises]/to/[conclusion]`
- Possible world evaluation: `/ex/TorF/qq/[sentences]` (with world in params)
- Truth table row evaluation: `/ex/TorF/qq/[sentences]` (with TT row in params)

**Context Display:**
- **If argument:** Shows premises and conclusion in logical notation table format
- **If possible world:** Displays situation with named objects and predicate extensions
- **If truth table row:** Shows table header with variable assignments

**Answer Structure:**
- Array of boolean values (one per sentence/requirement)
- Indexed with `idx` and `value`

**Key Helpers:**
```coffee
isArgument: () # Is this about an argument?
isWorld: () # Is this about a possible world?
isTTrow: () # Is this about a truth table row?
isJustOneSentence: () # Single vs multiple sentences
sentences: () # Array of sentence objects with theSentence and idx
```

**UI Components:**
- `+TorF_questions` template fragment for checkbox interface
- Radio buttons or checkboxes for true/false selection

**File References:**
- `/client/lib/TorF_questions/` - TorF question component

---

#### 4.3 Translation Exercise (`/ex/trans/*`)

**File Location:** `/client/ex/trans_ex.html.jade` and `/client/ex/trans_ex.coffee`

**Purpose:** Translate between English and first-order logic

**URL Format:**
```
/ex/trans/domain/[domain]/names/[names]/predicates/[predicates]/sentence/[sentence]
```

**Example:**
```
/ex/trans/domain/5things/names/a=thing1|b=thing2/predicates/Fish1|Person2|Red1/sentence/At%20least%20two%20people%20are%20not%20fish
```

**Detection Logic:**
- If `[sentence]` is English → translate to logic
- If `[sentence]` is logical notation → translate to English

**Answer Structure:**
```coffee
content: {
  sentence: "translated sentence",
  dialectName: "lpl",
  dialectVersion: "1.0"
}
```

**UI Components:**
- **Editor:** `+editSentence` template with CodeMirror
- `editorId="awFOLeditor"`
- CodeMirror integration for syntax highlighting
- Language mode detection

**Display Data:**
```coffee
isTranslationToEn: () # Boolean - direction of translation
domain: () # Domain description
names: () # Array of names and referents
predicates: () # Array of predicate descriptions
sentence: () # Current sentence to translate
```

**File References:**
- `/client/lib/codemirror/` - CodeMirror editor component
- `/client/lib/awfol/` - First-order logic parser

---

#### 4.4 Proof Exercise (`/ex/proof/*`)

**File Location:** `/client/ex/proof_ex.html.jade` and `/client/ex/proof_ex.coffee`

**Purpose:** Write natural deduction proofs

**Types:**
- Standard proof: `/ex/proof/from/[premises]/to/[conclusion]`
- Proof or invalid claim: `/ex/proof/orInvalid/from/[premises]/to/[conclusion]`

**Answer Structure:**
```coffee
content: {
  proof: "proof text",
  dialectName: "lpl",
  dialectVersion: "1.0"
}
```

**UI Components:**
- **Editor:** CodeMirror-based proof editor
- Proof checking button with feedback
- Reset button

**Display Data:**
```coffee
premises: () # Array of premise sentences
conclusion: () # Conclusion sentence
isForInvalidity: () # Boolean - can claim argument is invalid
```

---

#### 4.5 Counter-Example Exercise (`/ex/counter/*` and `/ex/create/*`)

**File Location:** `/client/ex/counter_ex.html.jade` and `/client/ex/counter_ex.coffee`, `/client/ex/create_ex.html.jade` and `/client/ex/create_ex.coffee`

**Purpose:** 
- **Counter Exercise:** Describe a situation where premises are true and conclusion false
- **Create Exercise:** Create a situation where given sentences are all true

**Types:**
- For argument: `/ex/counter/from/[premises]/to/[conclusion]` or `/ex/create/from/[premises]/to/[conclusion]`
- For sentences: `/ex/counter/qq/[sentences]` or `/ex/create/qq/[sentences]`
- Or-type (claim consistency/validity): `/ex/counter/orInconsistent/qq/...` or `/ex/create/orValid/from/...`

**Answer Structure:**
```coffee
counterexample: {
  domain: [0, 1, 2, ...],  # array of object references
  names: { a: 0, b: 1, ... },  # name to domain element mapping
  predicates: {
    Fish: [0, 2],  # elements where predicate is true
    Person: [1, 3],
    ...
  }
}
# Optional: TorF answer if "orValid" or "orInconsistent"
TorF: [true/false]  # true = valid/consistent, false = invalid/inconsistent
```

**UI Components:**
- **Possible World Editor:** `/client/lib/possible_world/` component
- Domain specification
- Name assignment controls
- Predicate extension controls
- Sentence truth value display

**Key Helpers:**
```coffee
displayCreateCounterexample: () # Boolean - show editor
namesToAssign: () # Array of names from parsed sentences
predicatesToAssign: () # Array of predicates from parsed sentences
getDomain: () # Array of domain elements
```

---

#### 4.6 Truth Table Exercise (`/ex/tt/*`)

**File Location:** `/client/ex/tt_ex.html.jade` and `/client/ex/tt_ex.coffee`

**Purpose:** Construct complete or partial truth tables

**Types:**
- For sentences: `/ex/tt/qq/[sentences]` or `/ex/tt/noQ/qq/[sentences]`
- For argument validity: `/ex/tt/from/[premises]/to/[conclusion]` or `/ex/tt/noQ/from/...`

**Features:**
- Interactive truth table grid
- Auto-calculation of sentence values
- Argument validity determination
- Counterexample specification (if invalid)

**Answer Structure:**
```coffee
truthTable: {
  rows: [
    { A: true, B: false, "A and B": false, ... },
    { A: true, B: true, "A and B": true, ... },
    ...
  ]
}
# Optional: validity claim and counterexample for argument exercises
TorF: [true/false]  # true = valid, false = invalid
counterexample: { ... }  # if showing invalidity
```

**UI Components:**
- Truth table grid editor
- `/client/lib/truth_table/` component

---

#### 4.7 Scope Exercise (`/ex/scope/*`)

**File Location:** `/client/ex/scope_ex.html.jade` and `/client/ex/scope_ex.coffee`

**Purpose:** Identify quantifier scope and parse logical structure

**URL:** `/ex/scope/qq/[sentences]/`

**Answer Structure:**
```coffee
content: {
  scopes: [
    { sentence: "...", scope: "[[ALL x] [SOME y] ...]" },
    ...
  ]
}
```

---

#### 4.8 Free Text Question (`/ex/q/*`)

**File Location:** `/client/ex/q_ex.html.jade` and `/client/ex/q_ex.coffee`

**Purpose:** Answer free-text questions about logic

**URL:** `/ex/q/:_question/`

**Answer Structure:**
```coffee
content: "student's free text answer"
```

**UI Components:**
- Simple textarea for response

---

### 5. Grading Interface (`/ex/*/grade`)

**File Location:** `/client/grade/GradeLayout.html.jade` and `/client/grade/GradeLayout.coffee`

**Route:** `FlowRouter.route "#{routeTxt}/grade"`

**Purpose:** Tutor-only interface for grading student submissions

**Key Features:**

#### Display Elements
- **Question Display:** Shows same interface as student (read-only)
- **Student Answers List:** Each student's submission with:
  - Student name and email
  - Submission timestamp
  - Machine feedback (if available)
  - Help requests associated with this submission
- **Grading Form:** For each answer:
  - Correctness determination (correct/incorrect/don't know)
  - Human feedback comment textarea
  - Edit/delete buttons for existing feedback

#### Controls
- **Hide Correct Answers:** Toggle switch to hide already-graded correct answers
- **Check Your Answer:** Link to student's exercise page to check own answer
- **Help Request Handling:** Display and answer help requests inline

#### Data Context
```coffee
answers: () # Array of SubmittedExercises
isAnswers: () # Boolean - any answers to grade
isMachineFeedback: () # Boolean - auto-grading available
isHumanFeedback: () # Boolean - tutor feedback exists
helpRequests: () # Array of HelpRequest documents
```

#### Grading Form Elements
```jade
form
  p #{ownerName}'s answer is:
  if isCorrectnessDetermined
    span #{rightOrWrong}
    if canDeleteCorrectness
      a.changeCorrectness.waves-effect edit
  else
    // Radio buttons for correct/incorrect/don't know
  // Human feedback comment field
  // Help request answer field (if present)
```

#### User Interactions
- Select correctness via radio buttons
- Type feedback in textarea
- Edit existing correctness determination
- Edit existing feedback (if student hasn't seen it)
- Answer help requests inline
- Navigate to next exercise

---

### 6. Student Dashboard Pages

#### My Submitted Exercises (`/mySubmittedExercises`)

**File Location:** `/client/mySubmittedExercises.html.jade` and `/client/mySubmittedExercises.coffee`

**Purpose:** View and download archive of all submitted work

**Features:**
- List of all submitted exercises
- Backup/export functionality

---

#### Feedback to Review (`/feedbackToReview`)

**File Location:** `/client/feedbackToReview.html.jade` and `/client/feedbackToReview.coffee`

**Purpose:** Quick navigation to exercises with new grader feedback

---

### 7. Tutor Dashboard Pages

#### Exercises to Grade (`/exercisesToGrade`)

**File Location:** `/client/exercisesToGrade.html.jade` and `/client/exercisesToGrade.coffee`

**Route:** `FlowRouter.route '/exercisesToGrade'`

**Purpose:** See all ungraded exercises from tutees

**Display:**
- Links to exercises by exercise set
- Count of ungraded exercises
- Filter options:
  - All students vs. only subscription followers

**Modals:**
- Filter controls (toggle for "show only followers")

**Data Required:**
- Meteor method `getExercisesToGrade(filterOptions)`
- Subscriptions collection
- SubmittedExercises collection

**Helper Functions:**
```coffee
subscriptions() # Unique exercise sets
exercises() # Array of ungraded exercise objects
isShowOnlyFollowers() # Boolean toggle state
```

#### Help Requests to Answer (`/helpRequestsToAnswer`)

**File Location:** `/client/helpRequestsToAnswer.html.jade` and `/client/helpRequestsToAnswer.coffee`

**Purpose:** Answer student help requests

**Display:**
- List of unanswered help requests
- Question text from student
- Context: exercise name, student name, submission time
- Answer textarea
- Submit answer button

---

#### My Tutees (`/myTutees`)

**File Location:** `/client/myTutees.html.jade` and `/client/myTutees.coffee`

**Route:** `FlowRouter.route '/myTutees'`

**Purpose:** List of students this user tutors

**Display:**
- Tutee name and email
- Exercise sets each tutee is following
- Quick link to tutee's work on each exercise set

**Data Required:**
- User profile (seminar_tutor designation)
- Subscriptions collection filtered by tutees
- Users collection filtered by seminar_tutor

---

#### Tutees' Progress (`/myTuteesProgress`)

**File Location:** `/client/myTuteesProgress.html.jade` and `/client/myTuteesProgress.coffee`

**Route:** `FlowRouter.route '/myTuteesProgress'`

**Purpose:** Analytics and progress tracking for tutees

**Features:**
- Overall statistics table:
  - Mean number of exercises submitted
  - Percentage correct/incorrect/ungraded
  - Separate: All-time and Last 7 days
- Progress charts (using chart library)
- Per-tutee detailed statistics
- Filter by exercise set, lecture, unit

**Display:**
```jade
h4 Means for your #{nofTutees} tutees:
table.centered
  tr
    td All time
    td #{meanNumberSubmitted}
    td #{percentCorrect}%
    td #{percentIncorrect}%
    td #{percentUngraded}%
  tr
    td last 7 days
    td #{meanNumberSubmitted7days}
    td #{percentCorrect7Days}%
    // ...

#progressChart  // all-time chart
#progressChart7days  // last 7 days chart

each tutees
  h4 #{profile.name}
  table.centered
    // Per-tutee stats...
```

**Data Required:**
- Meteor method `subscribe('tutees', tutorId, filters)`
- Meteor method `subscribe('tutees_progress', tutorId, filters)`
- SubmittedExercises collection (large dataset)
- ReactiveVar for stats computation

**Helper Functions:**
```coffee
nofTutees() # Count of tutees
meanNumberSubmitted() # Average exercises submitted
percentCorrect() # % with correct answers
percentIncorrect() # % with incorrect answers
percentUngraded() # % not yet graded
drawProgressCharts() # Trigger chart rendering
```

**Performance Note:** Computes statistics client-side from potentially >14000 SubmittedExercises documents. Comment in code indicates TODO to move to server-side computation.

---

### 8. Other Pages

#### Terms of Use (`/termsOfUse`)

**File Location:** `/client/termsOfUse.html.jade`

**Purpose:** Display terms of service

---

#### Explore Zoxiy (`/exploreZoxiy`)

**File Location:** `/client/exploreZoxiy.html.jade`

**Purpose:** Tutorial/educational content about using zoxiy

---

#### Old Browser Sorry (`/oldBrowserSorry`)

**File Location:** `/client/oldBrowserSorry.html.jade`

**Purpose:** Inform users with incompatible browsers

---

#### I Am A Tutor (`/iAmATutor`)

**File Location:** `/client/iAmATutor.html.jade` and `/client/iAmATutor.coffee`

**Purpose:** Self-registration as tutor

---

#### I Am Honestly Really And Truly An Instructor (`/iAmHonestlyReallyAndTrulyAnInstructor`)

**File Location:** Similar structure

**Purpose:** Self-registration as instructor

---

#### Loading Page (`/loading`)

**File Location:** `/client/loading.html.jade`

**Purpose:** Loading indicator while subscriptions initialize

**Display:**
```jade
template(name='loading')
  .spinner
    .double-bounce1
    .double-bounce2
```

---

#### Route Not Found

**File Location:** `/client/routeNotFound.html.jade`

**Default Route:** `FlowRouter.notFound`

---

## Reusable UI Components

### Template Fragments

Located in `/client/ex/template_fragments/`:

#### 1. `submitted_answer.html.jade`

**Purpose:** Display previous student submission with feedback

**Template Name:** `submitted_answer`

**Display:**
- "You submitted an answer [time ago]" with load answer link
- Correctness status (correct/incorrect)
- Machine feedback comment (if available)
- Human feedback from grader (if available)

**Requires Handling:**
- `#view-answer` click events
- Load previous answer from session

**Data Context:**
```coffee
isSubmitted: () # Has student submitted?
submittedAnswers: () # Array of SubmittedExercise objects
dateSubmitted: () # Formatted timestamp
rightOrWrong: () # "correct" or "incorrect"
displayMachineFeedback: () # Boolean
machineSays: () # Machine feedback text
humanFeedback: () # Human feedback object
```

#### 2. `help.html.jade`

**Purpose:** Help request and correct answer display interface

**Includes:**

**topic_header**
- Topic/unit title and breadcrumb
- Grade button (if tutor and not grading)

**help_with_this_exercise**
- Link to zoxiy guide
- Links to lecture slides and reading materials

**ask_for_help**
- Display previous help requests
- "ask for help" button opens modal
- "show an answer" button shows correct answer(s)

**requestHelpModal**
- Checkboxes: "Reviewed lecture slides" and "Read textbook"
- Description textarea: "What are you stuck on?"
- Note: Requests may go unanswered outside lecture weeks

**showCorrectAnswerModal**
- Displays correct answer(s) for the exercise
- Shows answer type and content

**Modals Used:**
- `requestHelpModal` - for asking help
- `showCorrectAnswerModal` - for viewing solutions

#### 3. `submitted_answer.html.jade`

**Purpose:** Submit or re-submit exercise answer

**Template Name:** `submit_btn`

**Display:**
- If not submitted: "Submit" button
- If submitted: "Re-submit" button (active) + disabled "submit" button

**Button Elements:**
- Material icons: `send`
- Wave effect ripple animation

**Requires Handling:**
- `#submit` click events to submit the exercise

#### 4. `next_exercise.html.jade`

**Purpose:** Navigate to next exercise in sequence

**Template Name:** `next_exercise`

**Display:**
- "next exercise >" button (if there is a next exercise)
- Styled with `.huge-glow-20` class for emphasis

**Navigation Logic:**
- Gets next exercise from exercise set structure
- Handles transitions between units and lectures
- Updates session with last exercise URL

**Data Context:**
```coffee
isNextExercise: () # Boolean - is there a next exercise?
```

### Shared Template Helpers

#### `topic_header` Template

**Location:** `/client/ex/template_fragments/help.html.jade` (lines 1-14)

**Purpose:** Displays unit/topic context

**Display:**
```jade
template(name='topic_header')
  if variant
    p Topic: #{unitTitle} --- #{variant} exercises for #{courseName}
  if isSeminarTutor
    unless isGrading
      button#grade.btn Grade
```

**Data Context:**
```coffee
variant: () # Exercise set variant name
unitTitle: () # Current unit/topic name
courseName: () # Course name
isSeminarTutor: () # Boolean - is current user a tutor?
isGrading: () # Boolean - viewing in grade mode?
```

### Shared Template Patterns

#### `display_subscription` Template

**Location:** `/client/main.html.jade` (lines 2-3)

**Purpose:** Display a single exercise set subscription link

**Renders:**
```jade
a(href="/course/#{courseName}/exerciseSet/#{variant}?#{userQueryParam}") 
  The '#{variant}' exercises for #{courseName}
```

#### `display_argument` Template

**Location:** `/client/ex/TorF_ex.html.jade` (lines 58-74)

**Purpose:** Render logical argument in standard format

**Structure:**
```
Premises (in box with left border)
---
Conclusion
```

**Uses:**
- Materialize CSS table styling
- Material icons (if needed)

#### `TorF_questions` Component

**Location:** `/client/lib/TorF_questions/`

**Purpose:** Reusable true/false question interface

**Files:**
- `TorF_questions.html.jade`
- `TorF_questions.coffee`

**Features:**
- Checkbox interface for multiple questions
- Indexed sentences
- Session-based answer tracking

### Utility and Library Components

#### CodeMirror Component

**Location:** `/client/lib/codemirror/meteor_component.html.jade` and `meteor_component.coffee`

**Purpose:** Code editor for proof and translation exercises

**Features:**
- Syntax highlighting for logical notation
- Line numbers
- Auto-indent
- Integrated with Meteor reactivity

**Used In:**
- Translation exercises (AWFol editor)
- Proof exercises

#### Possible World/Situation Editor

**Location:** `/client/lib/possible_world/`

**Files:**
- `possible_world.html.jade`
- `possible_world.coffee`

**Purpose:** Interactive editor for creating logical situations

**Features:**
- Domain element creation and management
- Name-to-element assignment
- Predicate extension definition
- Visual representation of world state

**Used In:**
- Counter-example exercises
- Create exercises

#### Truth Table Component

**Location:** `/client/lib/truth_table/`

**Files:**
- `truth_table.html.jade`
- `truth_table.coffee`

**Purpose:** Truth table construction interface

**Features:**
- Auto-calculation of sentence truth values
- Interactive cell editing
- Variable assignment

#### GridStack Component

**Location:** `/client/lib/gridstack/`

**Purpose:** Draggable grid layout for exercise builder

**Used In:**
- Exercise set editor
- Exercise builder interface

---

## User Workflows

### Workflow 1: New Student Registration and First Exercise

**Steps:**

1. **Registration** (handled by accounts system)
   - Meteor authentication
   - Email verification
   - User profile creation

2. **Select Exercise Set** (`/courses` → `/course/:courseName` → `/course/:courseName/exerciseSet/:variant`)
   - Browse available courses
   - Select course
   - Choose exercise set variant
   - Subscribe to exercise set

3. **Configure Tutor**
   - Main page card: "Tutor"
   - Click "Add tutor" button
   - Modal: typeahead search for tutor email
   - Confirm selection
   - Toast notification: "Tutor has been updated"

4. **Start First Exercise**
   - Main page: "Resume from last exercise" (if available) or browse exercises
   - Click exercise link
   - Navigate to exercise page (e.g., `/ex/tree/require/complete|closed/from/...`)

5. **Complete First Exercise**
   - Read question displayed at top
   - Use appropriate editor for exercise type
   - Check answer with "check" button
   - View feedback
   - Optional: Ask for help (if unsure)
   - Click "submit" button
   - Toast notification: "Exercise submitted"
   - Button changes to "re-submit"

**Key Pages Visited:**
1. `/`
2. `/courses`
3. `/course/[courseName]`
4. `/course/[courseName]/exerciseSet/[variant]`
5. `/ex/[type]/...`

**Session Variables Set:**
- `userId/lastExercise` - URL of last accessed exercise
- `userId/hideBrowserWarning` - browser warning dismissal

---

### Workflow 2: Student Solving Exercise and Viewing Feedback

**Steps:**

1. **Start Exercise**
   - From home page or exercise list
   - Navigate to exercise page
   - Load previous answer (if any) via "load answer" link

2. **Input Answer**
   - Editor appears based on exercise type
   - For trees: drag-and-drop in Treant editor
   - For TorF: check appropriate boxes
   - For translation: type in CodeMirror
   - For proof: type proof steps
   - For situations: define domain and predicates

3. **Check Answer**
   - Click "check" button
   - Feedback appears in `#feedback` element
   - Machine grading runs (if available)
   - Shows whether answer is correct/incorrect

4. **Submit Answer**
   - Click "submit" button
   - Meteor method: `submitExercise()`
   - Stores to SubmittedExercises collection
   - Toast: "Exercise submitted"
   - Button changes to "re-submit"

5. **View Submitted Answer**
   - "submitted_answer" template shows:
     - Timestamp: "You submitted an answer [time ago]"
     - "load answer" link
     - Machine feedback (if available)

6. **Receive Grader Feedback**
   - Tutor grades exercise (see Workflow 4)
   - Human feedback added to SubmittedExercises
   - Student receives notification on main page
   - Student navigates to `/feedbackToReview`
   - Clicks exercise to see feedback
   - In "submitted_answer" section, sees grader's comment

**Session Variables Used:**
- `userId/[exerciseId]/answer` - current answer being built
- `userId/lastExercise` - updated each page load

**Databases Modified:**
- SubmittedExercises - insert on submit
- GradedAnswers - if existing perfect answer

---

### Workflow 3: Student Requesting Help

**Steps:**

1. **Stuck on Exercise**
   - Viewing exercise page
   - Click "ask for help" button

2. **Fill Help Request**
   - Modal opens: `requestHelpModal`
   - Checkboxes:
     - "I have reviewed the lecture slides"
     - "I have read [textbook reference]"
   - Textarea: "What are you stuck on?"
   - Click "submit"

3. **Request Stored**
   - Meteor method: `submitHelpRequest()`
   - Stores to HelpRequest collection
   - Linked to SubmittedExercise
   - Toast: "Help request submitted"

4. **Monitor for Answer**
   - Template shows: "You asked for help [time ago]"
   - Updating status: "No answer yet" or displays answer

5. **Receive Answer**
   - Tutor answers help request (see Workflow 5)
   - Student notification: help request answered
   - Main page card: "Help Request"
   - Click card to see answer
   - Modal or inline display: Tutor's response

**Collections Modified:**
- HelpRequest - insert request
- SubmittedExercises - link to help request

**Templates Involved:**
- `ask_for_help` - display and request interface
- `requestHelpModal` - help request form
- `grading_form` - tutor sees help requests inline

---

### Workflow 4: Tutor Grading an Exercise

**Steps:**

1. **View Exercises to Grade**
   - Navigate to `/exercisesToGrade`
   - See list of ungraded exercises from tutees
   - Optional: Filter by exercise set or just followers
   - Click exercise link

2. **Open Grading Interface**
   - Navigates to `/ex/[type]/[...]/grade`
   - Renders GradeLayout template
   - Shows exercise question (read-only)
   - Lists all submitted answers from tutees

3. **Review Student Answer**
   - Displays answer using exercise-specific template
   - Machine feedback shown (if available)
   - Help requests associated with submission shown

4. **Determine Correctness**
   - Grading form shows radio buttons:
     - Correct
     - Incorrect
     - I don't know
   - Select appropriate option

5. **Add Feedback**
   - Textarea: "Comments to [student name]:"
   - Type constructive feedback
   - Optional fields:
     - Answer help request (if present)
     - Edit existing feedback (if not yet seen)

6. **Submit Grading**
   - Click "submit" button
   - Meteor method: `submitGrade()`
   - Stores HumanFeedback to SubmittedExercises
   - Updates GradedAnswers if applicable

7. **Student Notifications**
   - Student sees feedback on main page
   - Toast notification if first viewing
   - Can view full feedback at `/feedbackToReview` or exercise page

**Session Variables:**
- `userId/hideCorrectAnswers` - toggle visibility

**Databases Modified:**
- SubmittedExercises - add/update humanFeedback
- GradedAnswers - create if all info present

**Templates/Helpers:**
```coffee
isAnswers() # Are there answers to grade?
isMachineFeedback() # Show auto-grade comment?
isHumanFeedback() # Feedback already exists?
isHumanFeedbackComment() # Comment already exists?
```

---

### Workflow 5: Tutor Answering a Help Request

**Steps:**

1. **View Help Requests**
   - Navigate to `/helpRequestsToAnswer`
   - See count of unanswered requests
   - List shows:
     - Student name and email
     - Exercise name
     - Question student asked
     - Timestamp

2. **Select Help Request**
   - In grading interface (Workflow 4):
     - View student's submitted exercise
     - See help requests on that submission
   - Or navigate directly to `/helpRequestsToAnswer`

3. **View Request Details**
   - Student's question displayed
   - Context: exercise name, submission time
   - Optional: Review student's answer

4. **Type Answer**
   - Textarea appears in grading form (if grading)
   - Or dedicated help request page
   - Type response addressing student's specific question

5. **Submit Answer**
   - Click "submit" button
   - Meteor method: `submitHelpRequestAnswer()`
   - Stores answer to HelpRequest collection

6. **Student Notifications**
   - On next view of exercise, student sees answer
   - Main page notification: "Your help request has been answered"
   - Modal or section displays tutor's response

**Databases Modified:**
- HelpRequest - add answer and answererName

**Related Collections:**
- SubmittedExercises - linked for context
- Exercises - for display

---

### Workflow 6: Instructor Creating a Course and Exercise Set

**Steps:**

1. **Create Course**
   - Navigate to `/courses`
   - Click "Create New Course" button (instructor/tutor only)
   - Modal: `createNewCourseModal`
   - Fields:
     - Course name (no spaces, used in URI)
     - Description
   - Validation:
     - Name contains no `:`, `/`, or `?`
     - Both fields required
   - Click "create"
   - Meteor method: `createNewCourse(name, description)`
   - Toast: "Created [name]"
   - Redirect to `/course/[name]`

2. **Create Exercise Set**
   - On course page: click "Create New Exercise Set" button
   - Modal: `createNewExerciseSetModal`
   - Fields:
     - Variant name (e.g., "normal", "easy", "hard")
     - Description (e.g., "for UK_W20_PH126")
   - Click "create"
   - Meteor method: `createNewExerciseSet(courseName, variant, description)`
   - Redirect to `/course/[courseName]/exerciseSet/[variant]/edit`

3. **Edit Exercise Set**
   - In edit mode (`/edit` in URL)
   - Add lectures and units
   - For each unit, add exercises

4. **Add Exercise**
   - Click "add exercise" button/icon
   - Opens exercise builder modal
   - Typeahead search for exercise type

5. **Exercise Builder**
   - Select exercise type (TorF, tree, proof, etc.)
   - Fields vary by type:
     - Premises/conclusion
     - Domain and predicates
     - Requirements (e.g., "complete", "closed")
     - Help text/hints
   - Save exercise
   - Appears in unit

6. **Publish Exercise Set**
   - Exercises can be immediately accessed
   - Or scheduled for release on date
   - Students can subscribe and work on exercises

**Databases Modified:**
- Courses - new course document
- ExerciseSets - new exercise set document
- Exercises (in database, not collections shown)

**Email Domain Prefix:**
- Course names automatically prefixed with user's email domain
- Example: `uk.ac.warwick:MyLogicCourse`

---

## UI Libraries and Styling

### Materialize CSS

**Version:** Integrated in Meteor packages

**Components Used:**

1. **Navigation Bar**
   - `.nav-wrapper` with `.container`
   - `.brand-logo` for title
   - `.right` for right-aligned items

2. **Buttons**
   - `.btn` - standard button
   - `.btn-flat` - flat button style
   - `.waves-effect` - ripple animation on click

3. **Forms**
   - `.input-field` - wraps inputs with labels
   - `.materialize-textarea` - styled textarea
   - `label` - floating labels
   - Radio buttons with `.with-gap` class

4. **Cards**
   - `.card` - card container
   - `.card-content` - card body
   - `.card-title` - card title
   - `.card-action` - action links/buttons at bottom

5. **Collections/Lists**
   - `.collection` - styled list
   - `.collection-item` - list item

6. **Grid System**
   - `.row` - row container
   - `.col.s12` - 12 cols on small screens
   - `.col.m6` - 6 cols on medium screens
   - `.col.l4` - 4 cols on large screens

7. **Utilities**
   - `.right` - float right
   - `.left` - float left
   - `.center` - text-align center
   - `.divider` - horizontal line
   - `.spacer` - margin spacing

8. **Switches**
   - `.switch` - toggle switch component
   - `.lever` - switch handle
   - Checkbox + label structure

9. **Tables**
   - `.centered` - centered table
   - Can be nested in responsive grid

10. **Colors**
    - `.grey`, `.grey.lighten-2` - grey background
    - `.red-text` - red text
    - `.black-text` - black text
    - `.blue-text` - blue text

**Material Icons**
- Font: "Material+Icons" from Google Fonts (loaded in head)
- Usage: `i.material-icons [icon-name]`
- Examples:
  - `mode_edit` - edit icon
  - `delete` - trash icon
  - `add_circle_outline` - add icon
  - `send` - send/submit icon
  - `live_help` - help icon
  - `content_paste` - paste icon

### Custom CSS/Stylus

**File Location:** `/client/lib/site_style.css.styl`

**Key Styles:**

1. **Text Effects**
   ```styl
   .huge-glow-[SIZE]
     - Large glow text with text-shadow
     - Sizes: 20, 30, 40, 50, 60, 70, 80, 90, 120, 150, 180, 210, 240, 270, 300 pt
   ```

2. **Monospace Font**
   ```styl
   .monospace
     font-family: monospace
   ```

3. **Grid and Layout**
   ```styl
   .grid-stack-item-content
     box-shadow: 0 0 40px #FFF, 0 0 4px #FFF  // glow effect
   ```

4. **Truth Table**
   ```styl
   .truthtable
     th, td
       padding: 0
   ```

5. **Typeahead**
   ```styl
   .tt-query, .tt-hint, .tt-menu, .tt-suggestion
     // Twitter Typeahead styling
     // Max height with scroll
     .scrollable-dropdown-menu .tt-menu
       max-height: 200px
       overflow-y: auto
   ```

6. **Loading Spinner**
   - Double-bounce animation: `sk-bounce`
   - Alternative: rect animation: `sk-stretchdelay`

7. **Nib Import**
   - Vendor prefix mixins from Nib CSS library

### Icon Library

**Font:** Material Icons (Google Fonts)

**Common Icons:**
- `mode_edit` - edit
- `delete` - delete
- `add_circle_outline` - add
- `send` - submit/send
- `live_help` - help
- `content_paste` - paste
- `check` - checkmark
- `close` - close

### Grid Layout System (GridStack)

**Location:** `/client/lib/gridstack/`

**Purpose:** Draggable widget grid for exercise builder

**Features:**
- Drag-and-drop reordering
- Responsive grid
- Size constraints
- Persist layout

**Used In:**
- Exercise set editor
- Exercise builder interface

### Tree Visualization (Treant.js)

**Location:** `/client/lib/treant_dependencies/`

**Purpose:** Visual semantic tableaux (proof trees)

**Features:**
- Interactive node creation and editing
- Tree structure validation
- Export/rendering
- Connected nodes

**Used In:**
- Tree exercises (`/ex/tree/...`)
- Tree grading display

---

## Client-Side State Management

### Reactive Variables

**Location:** Various template `.coffee` files

**Types:**

#### Session Variables

Used for persistent user preferences and temporary state:

```coffee
# Exercise preference
Session.get("#{userId}/lastExercise")
Session.get("#{userId}/hideCorrectAnswers")
Session.get("#{userId}/oldBrowserIgnoreWarning")

# Grading interface
Session.get("#{userId}/#{courseName}/#{variant}/showOnlyFollowers")

# Help requests
Session.get("helpRequestAnswer/#{userId}/#{submittedExerciseId}")

# Typeahead search
Session.setPersistent(key, value)  # Persist across page reload
```

#### Meteor ReactiveVar

Used in template instances:

```coffee
Template.instance().nofHelpRequestsForTutor = new ReactiveVar()
Template.instance().exercises = new ReactiveVar()
Template.instance().stats = new ReactiveVar()
Template.instance().exerciseList = new ReactiveVar()
```

#### Local Variables in Coffee Files

```coffee
# tree_ex.coffee
bareTreeInEditor = undefined  # Tracks current tree in editor

# Possible world state
answerKey = {}  # Current answer being constructed

# UI state
isHideCorrectAnswers = () -> Session.get(...)
```

### Local Storage Usage

**Implemented via Session.setPersistent():**
- User preferences persist across sessions
- Example: hide correct answers toggle, browser warning dismissal

### Answer Storage

**Session Variable Pattern:**
```coffee
# Get current answer
ix.getAnswer()  # Returns from Session or undefined

# Set answer key (for sub-components)
ix.setAnswerKey(value, key)  # Sets ix.getAnswer()[key]

# Add dialect info
ix.addDialectInfoToAnswerDoc(answerDoc)  # Adds dialectName and dialectVersion
```

### Subscriptions Management

**Pattern:**
```coffee
Template.[name].onCreated () ->
  self = this
  self.autorun () ->
    FlowRouter.watchPathChange()  # Re-run on route change
    self.subscribe('collection_name', params)
```

**Key Subscriptions:**
- `subscriptions` - user's exercise set subscriptions
- `courses` - available courses
- `exercise_set` - current exercise set with structure
- `graded_answers` - previously graded answers for auto-grading
- `submitted_answers` - student submissions
- `help_requests_for_tutor` - help requests needing answers
- `tutees` - students taught by this tutor
- `tutees_progress` - aggregate statistics for tutees
- `tutees_subscriptions` - exercise sets tutees follow

### Helper Relationships

**Reactive Helpers** (automatic re-run on data change):

```coffee
Template.main.helpers
  hasSubscriptions: () ->
    return Subscriptions.find({owner:Meteor.userId()}).count() > 0
  
  subscriptions: () ->
    return Subscriptions.find({owner}).fetch()
```

**Non-Reactive Helpers** (manual updates):

```coffee
isInstructorOrTutor: ix.isInstructorOrTutor  # Function reference
```

### FlowRouter Integration

**Watching Path Changes:**

```coffee
FlowRouter.watchPathChange()  # Re-run reactive code on route change
FlowRouter.current()  # Get current route info
FlowRouter.getParam('_paramName')  # Get route param
FlowRouter.getQueryParam('paramName')  # Get query param
```

**State in URL:**
- Course name, exercise set variant
- Exercise parameters (premises, conclusion, etc.)
- User ID (for viewing others' work)
- Filter options (show only followers, etc.)

### Answer Lifecycle

1. **Initial State:** Default or loaded from previous submission
2. **User Edits:** Answer tracked in Session
3. **Validation:** Check button validates client-side
4. **Submission:** `ix.submitExercise()` sends to server
5. **Storage:** Stored in SubmittedExercises collection
6. **Grading:** Tutor grades (stored in humanFeedback)
7. **Notification:** Student sees feedback (marked with studentSeen flag)

### Global Utility Functions (ix)

**File:** `/client/lib/ix.coffee` (33KB)

**Key Functions:**

```coffee
# User identification
ix.getUserId()  # Current user ID
ix.getUserEmail()  # Current user email
ix.isInstructorOrTutor()
ix.userIsTutor()
ix.userIsInstructor()

# URL and exercise handling
ix.url()  # Current path without query string
ix.getExerciseId()  # Encoded exercise ID from URL
ix.convertToExerciseId(exerciseLink)
ix.getExerciseType()  # exercise type (tree, proof, etc.)
ix.isExerciseSubtype(type, submittedAnswer)
ix.isSubmitted(exerciseLink)

# Exercise parameters
ix.getPremisesFromParams()
ix.getConclusionFromParams()
ix.getSentencesFromParam()
ix.getWorldFromParam()
ix.getTTrowFromParam()

# Dialects (logical notation systems)
ix.setDialectFromExerciseSet()
ix.setDialectFromCurrentAnswer()
ix.setDialectFromThisAnswer(answer)

# Answer operations
ix.getAnswer()  # Current answer in session
ix.setAnswerKey(value, key)
ix.submitExercise(exercise, callback)
ix.addDialectInfoToAnswerDoc(answerDoc)

# Grading
ix.hashAnswer(answerDoc)
ix.gradeUsingGradedAnswers(answerDoc, options)
ix.hash(text)  # XXHash function

# Exercise context
ix.getExerciseContext()  # Lecture, unit, next exercise info
ix.getExerciseSet(options)
ix.getReading(exerciseSet, unit)
ix.getGradeURL(exerciseId)

# Utilities
ix.clipboard.get('key')  # Inter-template communication
ix.isBrowserCompatible()
ix.checkBrowserCompatible()
```

### Clipboard/Inter-template Communication

**Pattern:**
```coffee
ix.clipboard.get('exerciseSet')  # Get copied exercise set
ix.clipboard.set('exerciseSet', data)  # Copy exercise set
```

**Use Cases:**
- Copy/paste exercise sets between courses
- Copy exercise builder data

---

## Directory Structure

```
love-logic-server/
├── client/
│   ├── ApplicationLayout.html.jade
│   ├── ApplicationLayout.coffee
│   │
│   ├── main.html.jade              # Home/dashboard page
│   ├── main.coffee
│   │
│   ├── exerciseSets.html.jade      # Course and exercise set browsing
│   ├── exerciseSets.coffee
│   │
│   ├── exerciseSets.html.jade      # Exercise set creation
│   ├── upsertExerciseSet.coffee
│   │
│   ├── exerciseBuilder.html.jade   # Exercise builder UI
│   ├── exerciseBuilder.coffee
│   │
│   ├── exercisesToGrade.html.jade  # Exercises needing grading
│   ├── exercisesToGrade.coffee
│   │
│   ├── helpRequestsToAnswer.html.jade
│   ├── helpRequestsToAnswer.coffee
│   │
│   ├── myTutees.html.jade          # View tutees
│   ├── myTutees.coffee
│   │
│   ├── myTuteesProgress.html.jade  # Tutee statistics
│   ├── myTuteesProgress.coffee
│   │
│   ├── myTutors.html.jade
│   ├── myTutors.coffee
│   │
│   ├── mySubmittedExercises.html.jade  # View submitted work
│   ├── mySubmittedExercises.coffee
│   │
│   ├── feedbackToReview.html.jade
│   ├── feedbackToReview.coffee
│   │
│   ├── termsOfUse.html.jade
│   ├── iAmATutor.html.jade
│   ├── iAmATutor.coffee
│   ├── oldBrowserSorry.html.jade
│   ├── loading.html.jade
│   ├── exploreZoxiy.html.jade
│   │
│   ├── ex/                         # Exercise type templates
│   │   ├── tree_ex.html.jade      # Tree/tableaux exercise
│   │   ├── tree_ex.coffee
│   │   ├── TorF_ex.html.jade      # True/false exercise
│   │   ├── TorF_ex.coffee
│   │   ├── trans_ex.html.jade     # Translation exercise
│   │   ├── trans_ex.coffee
│   │   ├── proof_ex.html.jade     # Proof exercise
│   │   ├── proof_ex.coffee
│   │   ├── counter_ex.html.jade   # Counterexample exercise
│   │   ├── counter_ex.coffee
│   │   ├── create_ex.html.jade    # Create situation exercise
│   │   ├── create_ex.coffee
│   │   ├── tt_ex.html.jade        # Truth table exercise
│   │   ├── tt_ex.coffee
│   │   ├── scope_ex.html.jade     # Scope exercise
│   │   ├── scope_ex.coffee
│   │   ├── q_ex.html.jade         # Free text question
│   │   ├── q_ex.coffee
│   │   │
│   │   └── template_fragments/    # Shared exercise components
│   │       ├── help.html.jade         # Help request UI
│   │       ├── submitted_answer.html.jade  # Feedback display
│   │       └── next_exercise.html.jade     # Navigation button
│   │
│   ├── grade/                      # Grading interface
│   │   ├── GradeLayout.html.jade
│   │   └── GradeLayout.coffee
│   │
│   └── lib/                        # Shared utilities and libraries
│       ├── routes.coffee           # All routing definitions
│       ├── ix.coffee              # Utility functions (33KB)
│       ├── site_style.css.styl    # Custom styling
│       ├── hint.css               # Tooltip styling
│       │
│       ├── codemirror/            # Code editor
│       │   ├── meteor_component.html.jade
│       │   └── meteor_component.coffee
│       │
│       ├── TorF_questions/        # True/false question component
│       │   ├── TorF_questions.html.jade
│       │   └── TorF_questions.coffee
│       │
│       ├── possible_world/        # Situation editor
│       │   ├── possible_world.html.jade
│       │   └── possible_world.coffee
│       │
│       ├── truth_table/           # Truth table editor
│       │   ├── truth_table.html.jade
│       │   └── truth_table.coffee
│       │
│       ├── gridstack/             # Draggable grid layout
│       ├── treant_dependencies/   # Tree visualization
│       ├── jquery-ui-for-gridstack/
│       ├── awfol/                 # First-order logic parser
│       │
│       ├── materializecss_missing.js   # Materialize utilities
│       ├── typeahead.bundle.js     # Autocomplete search
│       ├── String.prototype.endsWith.js
│       ├── murmurhash3_gc.js       # Hashing
│       ├── xxhash.lmd.js           # Fast hashing
│       ├── es6-shim.js             # ES6 compatibility
│       └── ex_builder/             # Exercise builder utilities
│           └── exercise_schema.coffee
│
├── love-logic.coffee               # Collections and Meteor methods
├── meteor-startup.coffee
└── README.md
```

---

## Key Data Collections

### SubmittedExercises Collection

```coffee
{
  _id: ObjectId,
  exerciseId: String,           # Encoded exercise path
  owner: String,                # User ID
  created: Date,
  answer: {
    content: Mixed,             # Exercise type specific
    dialectName: String,
    dialectVersion: String
  },
  machineFeedback: {
    isCorrect: Boolean,
    comment: String
  },
  humanFeedback: {
    isCorrect: Boolean,
    comment: String,
    studentSeen: Boolean,
    studentEverSeen: Boolean
  }
}
```

### GradedAnswers Collection

```coffee
{
  _id: ObjectId,
  exerciseId: String,
  answerHash: String,           # Hash of answer content
  answerPNFsimplifiedSorted: String,  # For proof checking
  isCorrect: Boolean,
  comment: String,
  graderId: String,
  answer: Mixed                 # Answer object
}
```

### HelpRequest Collection

```coffee
{
  _id: ObjectId,
  exerciseId: String,
  submittedExerciseId: String,  # Link to submission
  requesterId: String,
  question: String,
  created: Date,
  answer: String,
  answererName: String,
  answerDate: Date,
  studentSeen: Boolean
}
```

### Subscriptions Collection

```coffee
{
  _id: ObjectId,
  owner: String,                # Student ID
  courseName: String,
  variant: String,
  created: Date
}
```

---

## Styling Summary

**Primary Framework:** Materialize CSS

**Key CSS Classes:**
- Grid: `.row`, `.col.s12/m6/l4`
- Cards: `.card`, `.card-content`, `.card-title`
- Buttons: `.btn`, `.btn-flat`, `.waves-effect`
- Colors: `.grey`, `.grey.lighten-2`, `.red-text`, `.blue-text`
- Layout: `.right`, `.center`, `.divider`
- Forms: `.input-field`, `.materialize-textarea`

**Typography:**
- Material Icons from Google Fonts
- Monospace font for code: `.monospace`
- Large glowing text: `.huge-glow-[SIZE]`

**Components:**
- Tables with centered layout
- Switches with lever animation
- Modals via MaterializeModal
- Tooltips via hint.css
- Typeahead search with custom styling

---

## Notes and TODOs from Code

1. **Performance:** Statistics computation in myTuteesProgress sends >14000 SubmittedExercises to client. Should move to server-side aggregation.

2. **Caching:** Currently not caching computed stats. Could optimize with server-side summary collection.

3. **Exercise ID Encoding:** URL encoding/decoding can be problematic with special characters. Mitigated by careful encoding.

4. **Lastly Exercise Tracking:** Currently disabled but structure in place to resume last exercise.

5. **Dialect Handling:** Multiple logic dialects supported (lpl, awFOL, etc.). Dialect info stored with answers for version compatibility.

6. **Browser Support:** Checks for CSS flexWrap and backgroundBlendMode. Old browsers directed to compatibility page.

