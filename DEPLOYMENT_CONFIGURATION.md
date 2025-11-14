# Love Logic Server - Deployment Configuration & Environment Setup Guide

**Project**: love-logic-server  
**Version**: Based on Meteor 1.2.1  
**Author**: Stephen A. Butterfill (2015)  
**Purpose**: Server and web UI for setting logic exercises, tracking students' progress

---

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Meteor Packages](#meteor-packages)
3. [Environment Variables](#environment-variables)
4. [Database Configuration](#database-configuration)
5. [Deployment Configurations](#deployment-configurations)
6. [Server Configuration](#server-configuration)
7. [Client Configuration](#client-configuration)
8. [Static Assets](#static-assets)
9. [Build Process](#build-process)
10. [Development Setup](#development-setup)
11. [Quick Start Guides](#quick-start-guides)

---

## Technology Stack

### Core Framework
- **Meteor Framework**: 1.2.1
- **Node.js Version**: 0.10.40 (as configured in MUP deployments)
- **MongoDB**: Varies by deployment (Replica Set enabled)
  - Production: MongoDB Replica Set (rsLogic0)
  - Aruba: MongoDB Replica Set (aDb)
  - TincTest: MongoDB Replica Set (bDb)

### Frontend Technology
- **Language**: CoffeeScript
- **Templating Engine**: Jade (mquandalle:jade 0.4.9)
- **Styling**: Stylus (mquandalle:stylus 1.1.1) + SCSS (fourseven:scss 3.4.1)
- **UI Framework**: Materialize CSS (materialize:materialize 0.97.5)
- **Icons**: Font Awesome (natestrauser:font-awesome 4.5.0) + Material Design Icons
- **Router**: Flow Router (kadira:flow-router 2.10.1)
- **Templating System**: Blaze with Spacebars
- **Layout Management**: Kadira Blaze Layout (kadira:blaze-layout 2.3.0)

### Runtime Dependencies
- **Babel Compiler**: 5.8.24_1 (ECMAScript transpilation)
- **jQuery**: 1.11.4
- **Underscore**: 1.0.4
- **Moment.js**: 2.12.0
- **bcrypt**: npm-bcrypt 0.7.8_2

### Package Versions (Complete list in .meteor/versions)
Total packages: ~105 (see `.meteor/versions` for complete list with exact version numbers)

---

## Meteor Packages

### Core Meteor Packages
- `meteor-base` (1.0.1) - Base Meteor package
- `mongo` (1.1.3) - MongoDB driver
- `blaze-html-templates` (1.0.1) - Blaze templating
- `session` (1.1.1) - Client session management
- `tracker` (1.0.9) - Reactive dependency tracking
- `logging` (1.0.8) - Client logging
- `reload` (1.1.4) - Reload functionality on update
- `random` (1.0.5) - Random number generation
- `ejson` (1.0.7) - JSON serialization

### UI/Frontend Packages
- `blaze-html-templates` - HTML templates
- `spacebars` (1.0.7) - Template language
- `materialize:materialize` (0.97.5) - Material Design CSS framework
- `natestrauser:font-awesome` (4.5.0) - Font Awesome icons
- `meteorstuff:materialize-modal` (1.0.6) - Modal components

### Routing & Layout
- `kadira:flow-router` (2.10.1) - Client-side router
- `kadira:blaze-layout` (2.3.0) - Layout manager for Blaze

### Authentication & User Accounts
- `accounts-base` (1.2.2) - Core authentication system
- `accounts-password` (1.1.4) - Password-based authentication
- `useraccounts:core` (1.13.1) - User accounts UI core
- `useraccounts:flow-routing` (1.13.1) - User accounts with Flow Router
- `useraccounts:materialize` (1.13.1) - Materialize UI for accounts
- `service-configuration` (1.0.5) - Service provider configuration

### Database & Data
- `mongo` (1.1.3) - MongoDB
- `mongo-id` (1.0.1) - MongoDB ID utilities
- `livedata` (1.0.15) - Real-time data synchronization
- `mongo-livedata` (1.0.9) - MongoDB integration with live data
- `minimongo` (1.0.10) - Client-side MongoDB simulation

### Build & Deployment
- `standard-minifiers` (1.0.2) - CSS/JS minification
- `meteor-base` (1.0.1) - Base Meteor package
- `appcache` (1.0.6) - Application cache manifest

### Clustering & Performance
- `meteorhacks:cluster` (1.6.9) - Clustering support
- `meteorhacks:aggregate` (1.3.0) - MongoDB aggregation
- `meteorhacks:search-source` (1.4.2) - Real-time search
- `meteorhacks:collection-utils` (1.2.0) - Collection utilities
- `meteorhacks:picker` (1.0.3) - HTTP request handler

### Development & Debugging
- `kadira:debug` (3.2.1) - Kadira debugging tools
- `kadira:runtime-dev` (0.0.1) - Runtime development tools
- `meteorhacks:meteorx` (1.4.1) - Internal monitoring

### Language & Preprocessing
- `coffeescript` (1.0.11) - CoffeeScript support
- `mquandalle:jade` (0.4.9) - Jade template engine
- `mquandalle:stylus` (1.1.1) - Stylus CSS preprocessor
- `fourseven:scss` (3.4.1) - SCSS/SASS support

### Additional Utilities
- `reactive-var` (1.0.6) - Reactive variables
- `reactive-dict` (1.1.3) - Reactive dictionaries
- `u2622:persistent-session` (0.4.4) - Persistent session storage
- `check` (1.1.0) - Type checking
- `http` (1.1.1) - HTTP requests
- `amplify` (1.0.0) - Ajax and storage
- `moment.js` (2.12.0) - Date/time handling
- `east5th:package-scan` (0.0.4) - Package scanning
- `cscottnet:es5-shim` (4.4.1) - ES5 compatibility shim
- `cosmos:browserify` (0.9.4) - Browserify support

---

## Environment Variables

### Essential Configuration

#### PORT
- **Type**: Integer
- **Default**: 3000
- **Purpose**: HTTP server port
- **Used in**: All deployments

#### ROOT_URL
- **Type**: String (HTTPS URL)
- **Example**: `https://logic-ex.butterfill.com`
- **Purpose**: Application root URL
- **Required for**: SSL/HTTPS, proper routing

#### MONGO_URL
- **Type**: MongoDB Connection String
- **Format**: `mongodb://host1,host2,host3/database?replicaSet=rsName`
- **Examples**:
  - Development: `mongodb://localhost:27017/love-logic`
  - Production MUP: `mongodb://127.0.0.1,10.8.0.1,10.8.0.5,10.8.0.9,10.8.0.14,10.8.0.19,10.8.0.24/love-logic?replicaSet=rsLogic0`
  - Aruba: `mongodb://10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.21,10.0.0.32/love-logic?replicaSet=aDb`
  - TincTest: `mongodb://10.0.0.1/love-logic?replicaSet=bDb`
- **Purpose**: MongoDB connection for data storage
- **Required**: Yes, for all deployments

#### MONGO_OPLOG_URL
- **Type**: MongoDB Connection String
- **Format**: `mongodb://host1,host2.../local?replicaSet=rsName`
- **Purpose**: MongoDB oplog for real-time synchronization
- **Required**: For clustered deployments using Meteor's oplog tailing

#### CLUSTER_DISCOVERY_URL
- **Type**: MongoDB Connection String
- **Format**: `mongodb://host1,host2.../cluster-database?replicaSet=rsName`
- **Purpose**: Service discovery and coordination for Meteor clusters
- **Required**: Only for clustered deployments

#### CLUSTER_SERVICE
- **Type**: String
- **Value**: `"web"` (for web servers in cluster)
- **Purpose**: Identifies service type in cluster
- **Required**: Only for clustered deployments

#### CLUSTER_BALANCER_URL
- **Type**: String (HTTPS URL)
- **Example**: `https://logic-ex-1.butterfill.com`
- **Purpose**: Load balancer URL for cluster node
- **Required**: Only for clustered deployments

#### DISABLE_WEBSOCKETS
- **Type**: Integer (0 or 1)
- **Default**: 1 (disabled)
- **Purpose**: Disables WebSocket connections, uses HTTP polling instead
- **Use case**: Deployment environments with WebSocket restrictions

### Optional Configuration

#### NODE_VERSION
- **Type**: String (version without 'v' prefix)
- **Example**: `0.10.40`
- **Purpose**: Node.js version to install on server
- **Default**: 0.10.36
- **Used in**: MUP deployment configuration

#### MAIL_URL
- **Type**: SMTP Connection String
- **Format**: Not currently configured (see server code for email handling)
- **Purpose**: Email sending (if needed in future)
- **Note**: Currently not configured; email features use Meteor's email module

### Setting Environment Variables

#### Development Setup
```bash
# Set local Mongo URL
export MONGO_URL=mongodb://localhost:27017/love-logic
export ROOT_URL=http://localhost:3000
```

#### Using setMongoURL.sh
```bash
#!/bin/bash
MONGO_URL=mongodb://localhost:27017/love-logic; export MONGO_URL
```

#### MUP Deployment
Edit deployment-specific `mup.json` file in `.deploy_*` folders.

---

## Database Configuration

### MongoDB Setup

#### Collections

**1. Courses**
- Stores course information
- **Index**: `{name: 1}` - indexed for fast lookups
- **Fields**: name, description, hidden (optional), owner
- **Purpose**: Course catalog

**2. ExerciseSets**
- Groups related exercises
- **Indexes**:
  - `{courseName: 1}` - for course-based queries
  - `{courseName: 1, variant: 1}` - composite for variant lookups
  - `{owner: 1}` - for user-owned sets
- **Fields**: courseName, variant, description, owner, hidden (optional)
- **Purpose**: Exercise set management

**3. SubmittedExercises**
- Tracks student submissions
- **Index**: `{owner: 1}` - for student progress queries
- **Fields**: owner (userId), exerciseId, answer (content), created (timestamp), humanFeedback, machineFeedback, graded (boolean)
- **Purpose**: Student submission tracking and grading

**4. Subscriptions**
- Course subscriptions per student
- **Index**: `{owner: 1}` - for user subscriptions
- **Fields**: owner (userId), courseName, exerciseSetVariant
- **Purpose**: Track which courses/exercises students are working on

**5. GradedAnswers**
- Cache of graded exercises
- **Fields**: exerciseId, ownerIdHash, answerHash, isCorrect, comment, graderId, created
- **Purpose**: Reuse grades for identical answers across students

**6. HelpRequest**
- Student help requests
- **Fields**: owner (userId), content, status, assignedTo, created, resolved
- **Purpose**: Support system for student requests

**7. Meteor.users**
- Authentication and user profiles
- **Fields**:
  - emails: array of email objects
  - profile: {name, is_seminar_tutor, is_instructor, seminar_tutor (assigned tutor email), instructor (assigned instructor email)}
  - services: authentication services data
  - createdAt: account creation timestamp
- **Purpose**: User authentication and profile management

#### Replica Set Configuration

All production deployments use MongoDB Replica Sets for:
- High availability
- Automatic failover
- Oplog tailing for real-time synchronization

**Replica Set Names Used**:
- `rsLogic0` - Production MUP cluster
- `aDb` - Aruba deployment
- `bDb` - TincTest deployment

#### Index Creation

Indexes are automatically created at Meteor startup via `Meteor.startup()` blocks:

```coffeescript
Meteor.startup ->
  Courses._ensureIndex({name:1})
  ExerciseSets._ensureIndex({courseName:1})
  ExerciseSets._ensureIndex({courseName:1, variant:1})
  # ... more indexes
```

---

## Deployment Configurations

### Overview

The application supports multiple deployment configurations in different directories:

```
.deploy_mup/          - Production (6 geographically distributed servers with clustering)
.deploy_aruba/        - Aruba servers (3 servers)
.deploy_test/         - Test environment (single server)
.deploy_no_cluster/   - Single server (no clustering)
.deploy_tinctest/     - TincTest cluster (2 servers)
.OLD_deploy_mup/      - Legacy configuration (archived)
```

### Deployment Method: Meteor Up (MUP)

All deployments use **Meteor Up** for deployment and management.

#### MUP Features Used
- Automated Node.js setup and configuration
- MongoDB installation and management
- PhantomJS for rendering (optional)
- SSL/HTTPS support
- Environment variable configuration
- Health checks on deployment

#### Common MUP Configuration Settings

```json
{
  "setupMongo": true,        // Install MongoDB on server
  "setupNode": true,         // Install Node.js
  "setupPhantom": true,      // Install PhantomJS (optional)
  "nodeVersion": "0.10.40",  // Node.js version
  "appName": "love-logic",   // Application name
  "enableUploadProgressBar": true,
  "deployCheckWaitTime": 90  // Seconds to wait after deployment
}
```

### 1. Production MUP (.deploy_mup)

**Servers**: 6 geographically distributed servers

```json
Servers:
- logic-ex-1 (Vultr, USA): 108.61.173.108
  - CLUSTER_BALANCER_URL: https://logic-ex-1.butterfill.com
  
- logic-ex-uk (Rackspace, UK): 31.3.227.147
  - CLUSTER_BALANCER_URL: https://logic-ex-2.butterfill.com
  
- logic-w-nyc2: 107.155.107.190
  - CLUSTER_BALANCER_URL: https://logic-ex-w-nyc2.butterfill.com
  
- logic-w-seattle: 23.29.125.135
  - CLUSTER_BALANCER_URL: https://logic-ex-w-seattle.butterfill.com
  
- logic-w-dallas: 107.155.88.153
  - CLUSTER_BALANCER_URL: https://logic-ex-w-dallas.butterfill.com
  
- logic-w-nyc: 107.155.107.85
  - CLUSTER_BALANCER_URL: https://logic-ex-w-nyc.butterfill.com
```

**Configuration**:
- PORT: 3000
- ROOT_URL: `https://logic-ex.butterfill.com` (shared across all servers via load balancer)
- DISABLE_WEBSOCKETS: 1
- CLUSTER_SERVICE: `web`
- MongoDB: Replica Set with 6 members
- MONGO_URL: `mongodb://127.0.0.1,10.8.0.1,10.8.0.5,10.8.0.9,10.8.0.14,10.8.0.19,10.8.0.24/love-logic?replicaSet=rsLogic0`
- MONGO_OPLOG_URL: Same servers, `/local` database
- CLUSTER_DISCOVERY_URL: Same servers, `/logic-ex-cluster` database

**Deployment Steps**:
1. Edit `.deploy_mup/mup.json` with your server details
2. Run: `mup deploy`
3. Monitor: `mup logs -f`
4. SSH: `mup ssh server.0` (or .1, .2, etc.)

### 2. Aruba Deployment (.deploy_aruba)

**Servers**: 3 servers in Aruba data center

```json
Servers:
- logic-a-uk4: 185.58.225.240
  - CLUSTER_BALANCER_URL: https://logic-ex-a-uk4.butterfill.com
  
- logic-a-uk5: 185.58.225.8
  - CLUSTER_BALANCER_URL: https://logic-ex-a-uk5.butterfill.com
  
- logic-vu-uk1 (Vultr): 45.32.180.114
  - CLUSTER_BALANCER_URL: https://logic-ex-v-uk1.butterfill.com
```

**Configuration**:
- PORT: 3000
- ROOT_URL: `https://logic-ex-a.butterfill.com`
- CLUSTER_SERVICE: `web`
- MongoDB: Replica Set (aDb)
- MONGO_URL: `mongodb://10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.21,10.0.0.32/love-logic?replicaSet=aDb`

**Deployment Steps**:
```bash
cd .deploy_aruba
mup deploy
```

### 3. Test Environment (.deploy_test)

**Servers**: 1 test server

```json
Server:
- logic-a-uk6 (hostname-based)
```

**Configuration**:
- PORT: 3000
- ROOT_URL: `https://logic-ex-test.butterfill.com`
- setupMongo: false (uses existing MongoDB)
- MONGO_URL: `mongodb://10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.21,10.0.0.32/love-logic?replicaSet=aDb`

**Purpose**: Testing new builds before production deployment

### 4. Single Server (No Cluster) (.deploy_no_cluster)

**Servers**: 1 server

```json
Server:
- logic-w-nyc3: 107.155.100.116
```

**Configuration**:
- PORT: 3000
- ROOT_URL: `https://logic-ex-w-nyc3.butterfill.com/`
- No clustering configuration
- setupMongo: true
- deployCheckWaitTime: 15 (faster due to single server)

**Purpose**: Standalone server without cluster overhead

### 5. TincTest Cluster (.deploy_tinctest)

**Servers**: 2 servers

```json
Servers:
- 108.61.166.113
  - CLUSTER_BALANCER_URL: https://tinctest2.zoxiy.xyz
  
- 45.32.180.115
  - CLUSTER_BALANCER_URL: https://tinctest4.zoxiy.xyz
```

**Configuration**:
- PORT: 3000
- ROOT_URL: `http://tinctest.zoxiy.xyz`
- CLUSTER_SERVICE: `web`
- MongoDB: Replica Set (bDb)
- setupMongo: false (external MongoDB)
- setupPhantom: false

**Purpose**: TincTest cluster for distributed testing

---

## Server Configuration

### Startup Sequence

The application initialization occurs in this order:

1. **Meteor.startup()** blocks execute when server starts
2. **Database indexes** are created for all collections
3. **Publications** are registered
4. **Methods** are registered
5. **Server is ready** to accept connections

### Published Collections

Publications define what data is sent to connected clients:

```coffeescript
# Public/unrestricted
Meteor.publish "courses"           # All non-hidden courses
Meteor.publish "course"            # Specific course by name

# User-specific
Meteor.publish "exercise_sets"     # Non-hidden sets for course
Meteor.publish "exercise_set"      # Specific set
Meteor.publish "submitted_exercises" # User's submissions
Meteor.publish "subscriptions"     # User's subscriptions
Meteor.publish "dates_exercises_submitted" # User's submission dates

# Tutor/Instructor-specific
Meteor.publish "user_details"      # Full user profile
Meteor.publish "tutees_of_user"    # Students assigned to tutor
Meteor.publish "tutees_progress"   # Student progress data
```

### Meteor Methods

Server-side callable methods for user actions:

#### User Management
- `seminarTutorExists(emailAddress)` - Check if tutor exists
- `updateSeminarTutor(emailAddress)` - Assign tutor to user
- `updateInstructor(emailAddress)` - Assign instructor to user
- `updateEmailAddress(emailAddress)` - Change user email
- `makeMeATutor()` - Upgrade user to tutor role
- `makeMeNotATutor()` - Remove tutor role
- `makeMeAnInstructor()` - Make user instructor
- `makeMeNotAnInstructor()` - Remove instructor role

#### Course Management
- `createNewCourse(name, description)` - Create new course

#### Exercise Management
- `submitExercise(exerciseId, answer)` - Submit exercise
- `gradeSubmission(submissionId, isCorrect, comment)` - Grade submission
- `requestHelp(exerciseId, content)` - Request help from tutor

### Authentication

Uses **Accounts Password** package with **UserAccounts** integration:

**Configuration** (`lib/config/at_config.coffee`):
- User fields: email (built-in), name (required), terms_of_use (required checkbox)
- reCaptcha integration (configured but disabled by default)
  - reCaptcha Site Key: `6Lc7Ew8TAAAAAE4stjjDQZj75lJr04uiVF4IY9EP`
  - reCaptcha Secret Key: `6Lc7Ew8TAAAAAFelC7T0-4557O7oODaW0jlaA-mk`
- Terms of Use URL: `/termsOfUse`
- Layout: ApplicationLayout with Materialize styling
- Protected routes: All except signin/signup/password recovery

### Email Configuration

**Current Status**: Basic email handling implemented

**Email Components**:
- User registration confirmation
- Password reset
- Help request notifications to tutors
- Grading notifications to students

**Implementation**:
- Uses Meteor's built-in email module
- Email addresses stored in user profiles
- Email validation on registration

**Future Configuration** (MAIL_URL):
```bash
# SMTP Configuration (when needed)
export MAIL_URL=smtp://username:password@smtp-server:587
```

### Scheduled Tasks

**MongoDB Startup Indexes** (in `server/publish.coffee`):
```coffeescript
Meteor.startup ->
  Courses._ensureIndex({name:1})
  ExerciseSets._ensureIndex({courseName:1})
  ExerciseSets._ensureIndex({courseName:1, variant:1})
  # ... creates all necessary indexes for performance
```

### Server Startup Configuration

**File**: `server/at_server_config.coffee`
- reCaptcha configuration
- User account templates setup
- Email settings (if configured)

---

## Client Configuration

### UI Framework & Components

**Materialize CSS Framework**:
- Material Design implementation
- Responsive grid system
- Pre-built components (buttons, cards, modals, forms)

**Material Design Icons**:
- Material Design Icons font
- Used throughout UI for navigation and actions

**Font Awesome Icons**:
- Alternative icon set
- For additional visual elements

### Frontend Structure

**Main Templates**:
- `ApplicationLayout.html.jade` - Main layout container
- `main.html.jade` - Landing/home page
- `loading.html.jade` - Loading state

**Page Templates**:
- `exerciseSets.html.jade` - Exercise set listing
- `exercisesToGrade.html.jade` - Tutor grading interface
- `mySubmittedExercises.html.jade` - Student submissions view
- `myTuteesProgress.html.jade` - Tutor student progress tracking
- `stats.html.jade` - Statistics view
- `termsOfUse.html.jade` - Legal page

**Authentication Templates**:
- Sign-in page (Flow Router)
- Sign-up page (Flow Router)
- Password change (Flow Router)

### Client Routing

**Router**: Flow Router by Kadira

**Route Groups**:
- Public routes: /, /sign-in, /sign-up, /termsOfUse
- Protected routes: /ex/*, /courses/*, /dashboard/*

**Authentication Check**:
```coffeescript
FlowRouter.triggers.enter [AccountsTemplates.ensureSignedIn], 
  except: ['signIn', 'signUp', 'forgotPwd', 'resetPwd', ...]
```

### Client Data Storage

**Session Management**:
- `Tracker.Dependency` - Reactive tracking
- `Reactive-Var` - Reactive variables
- `u2622:persistent-session` - Persistent session across page refreshes

**Example Storage**:
```javascript
// Temporary (cleared on logout)
Session.set('currentExerciseId', exerciseId)

// Persistent (survives page refresh)
PersistentSession.set('userPreferences', {...})
```

### Exercise Types Supported

The client supports exercises specified via URL patterns:

```
/ex/tt/qq/EXPRESSION
  - Truth table for propositional logic expression
  - Example: /ex/tt/qq/not (A or B)

/ex/tt/from/PREMISES/to/CONCLUSION
  - Truth table evaluation of argument
  - Example: /ex/tt/from/A or not B|not A or B/to/A and not A

/ex/create/qq/EXPRESSIONS
  - Create counterexample (satisfying interpretation)
  - Example: /ex/create/qq/Happy(a)|exists x not Happy(x)

/ex/create/from/PREMISES/to/CONCLUSION
  - Counterexample to argument
  - Example: /ex/create/from/all x all y (LeftOf(x,y) → SameSize(x,y))/to/all x all y SameSize(x,y)

/ex/proof/from/PREMISES/to/CONCLUSION
  - Natural deduction proof
  - Example: /ex/proof/from/exists x all y (¬ x = y → TallerThan(x,y))/to/∀y ∃x ( ¬ x = y → TallerThan(x,y) )
```

### Browser Requirements

**Supported Browsers**:
- Modern browsers with ES5 support
- Fallback: `cscottnet:es5-shim` (4.4.1) for older browsers

**Requirements**:
- JavaScript enabled
- LocalStorage support (for persistent session)
- WebSocket support (optional, falls back to HTTP polling)
- Cookies enabled (for session management)

### JavaScript/DOM APIs Used

- `localStorage` - Persistent client-side storage
- `sessionStorage` - Temporary storage
- DOM manipulation via jQuery
- WebSocket connections (or HTTP polling)
- File upload APIs (for exercise submissions)

---

## Static Assets

### Public Directory Structure

```
public/
├── font/
│   ├── roboto/
│   │   ├── Roboto-Light.woff
│   │   ├── Roboto-Light.woff2
│   │   ├── Roboto-Regular.ttf
│   │   ├── Roboto-Regular.woff
│   │   ├── Roboto-Regular.woff2
│   │   ├── Roboto-Medium.ttf
│   │   ├── Roboto-Medium.woff
│   │   ├── Roboto-Medium.woff2
│   │   ├── Roboto-Bold.ttf
│   │   ├── Roboto-Bold.woff
│   │   ├── Roboto-Bold.woff2
│   │   ├── Roboto-Thin.ttf
│   │   ├── Roboto-Thin.woff
│   │   └── Roboto-Thin.woff2
│   └── material-design-icons/
│       ├── Material-Design-Icons.ttf
│       ├── Material-Design-Icons.woff
│       ├── Material-Design-Icons.svg
│       └── LICENSE.txt
└── images/
    └── down.png
```

### Fonts

**Roboto Font Family** (Google Fonts):
- Weights: Thin, Light, Regular, Medium, Bold
- Formats: TTF, WOFF, WOFF2 (cross-browser support)
- Used for UI typography

**Material Design Icons**:
- Vector icon font
- Used for Material Design components
- Multiple formats for compatibility

### Images

- `down.png` - Dropdown/menu indicator
- Location: `/public/images/`

### Font Loading

Fonts are served as static assets via Meteor's public directory:
- Accessed via `/font/roboto/*` and `/font/material-design-icons/*`
- Defined in CSS/Stylus files for use in templates

### CSS/Asset Bundling

**Processing Pipeline**:
1. Jade templates → HTML
2. Stylus files → CSS
3. SCSS files → CSS
4. CoffeeScript → JavaScript
5. Assets minified (standard-minifiers)
6. Bundled into single files
7. Served with cache-busting hashes

---

## Build Process

### Build Steps

1. **Asset Compilation**:
   - CoffeeScript → JavaScript
   - Jade templates → HTML
   - Stylus/SCSS → CSS

2. **Bundling**:
   - All JavaScript combined and minified
   - All CSS combined and minified
   - Assets bundled into deployable package

3. **Minification**:
   - Uses `standard-minifiers` package
   - Reduces file sizes for faster load times
   - Source maps available for debugging

### Building for Deployment

**Local Build** (development):
```bash
meteor run
```

**Production Build** (with MUP):
```bash
cd .deploy_mup
mup deploy
```

The deploy process automatically:
1. Builds the Meteor application
2. Creates a bundle (tarball)
3. Uploads to server
4. Extracts and starts the application

### Build Configuration

**Minifiers Package** (standard-minifiers 1.0.2):
- Enabled by default in production
- Minifies CSS and JavaScript
- Removes comments and whitespace
- Generates source maps for debugging

**Asset Pipeline**:
- Babel compiler transpiles code
- CSS preprocessors (Stylus, SCSS) compile to CSS
- Jade templates compile to HTML
- All assets bundled into Meteor app bundle

---

## Development Setup

### Prerequisites

- Node.js 0.10.40+ (or latest stable)
- Meteor 1.2.1
- MongoDB (local instance for development)
- CoffeeScript knowledge helpful (main language)
- Git for version control

### Local Development Environment

#### 1. Install Meteor (if not already installed)

```bash
# macOS/Linux
curl https://install.meteor.com/ | sh

# Windows
# Download installer from https://www.meteor.com/install
```

#### 2. Set MongoDB URL

```bash
# Source the MongoDB setup script
source setMongoURL.sh

# Or manually set:
export MONGO_URL=mongodb://localhost:27017/love-logic
```

#### 3. Install Dependencies

```bash
# Dependencies should be handled by Meteor, but if needed:
npm install
```

#### 4. Start Development Server

```bash
cd love-logic-server
meteor
```

The app will be available at `http://localhost:3000`

#### 5. Access MongoDB (optional)

```bash
# Connect to local MongoDB to inspect data
mongo love-logic
```

### Development Workflow

1. **File Changes**: Meteor automatically watches files and recompiles
2. **Testing**: Changes reflected immediately in browser (hot reload)
3. **Debugging**: 
   - Browser console for client-side
   - Server logs in terminal for server-side
   - Set `DEBUG` environment variable for more logging

### Testing Setup

**Framework**: Gagarin (for end-to-end testing)

**Test Configuration** (`.gagarin/`):
- Test files in `tests/gagarin/`
- Settings in `tests/gagarin/settings-test.json`

**Sample Test** (`tests/gagarin/test.coffee`):
```coffeescript
describe 'love-logic tests', () ->
  server = meteor({})
  client = browser(server)
  
  before(() ->
    return server.execute(() ->
      Accounts.createUser({email: 'test@.com', password: 'password'})
    )
  )
  
  it 'should log on the server', () ->
    return server.execute(() -> 
      console.log 'I am alive!'
    )
```

**Running Tests**:
```bash
cd .gagarin
gagarin --help
# Run specific test
gagarin tests/gagarin/test.coffee
```

### Debugging Tools

**Kadira Debug** (kadira:debug 3.2.1):
- Debugging tools for Meteor development
- Subscription and method tracing
- Performance monitoring

**Browser DevTools**:
- Chrome/Firefox developer tools for client-side debugging
- Network inspector for viewing DDP messages
- Console for JavaScript debugging

**Server Logs**:
- Terminal output shows all server-side logs
- Use `console.log()` for debugging
- View in `mup logs -f` for deployed instances

### Code Structure

```
love-logic-server/
├── client/              # Client-side code
│   ├── ex/             # Exercise viewer components
│   ├── grade/          # Grading interface
│   ├── lib/            # Client shared utilities
│   └── *.coffee        # Page templates
│
├── server/             # Server-side code
│   ├── publish.coffee  # Publications and indexes
│   └── at_server_config.coffee  # Auth configuration
│
├── lib/                # Shared code (client + server)
│   ├── config/         # Configuration
│   └── *.coffee        # Shared utilities
│
├── public/             # Static assets (fonts, images)
│   ├── font/
│   └── images/
│
├── tests/              # Testing
│   └── gagarin/        # End-to-end tests
│
├── .meteor/            # Meteor configuration
│   ├── packages        # Package list
│   ├── versions        # Pinned versions
│   └── release         # Meteor version
│
├── .deploy_*/          # Deployment configurations
└── love-logic.coffee   # Main application file (468 lines)
```

### Package Management

**Adding Packages**:
```bash
# Add to app
meteor add package-name

# Remove from app
meteor remove package-name

# List all installed
meteor list
```

**Updating Packages**:
```bash
# Update all packages
meteor update

# Update specific package
meteor update package-name
```

---

## Quick Start Guides

### Quick Start: Development

```bash
# 1. Clone repository
git clone <repo-url>
cd love-logic-server/love-logic-server

# 2. Set MongoDB
export MONGO_URL=mongodb://localhost:27017/love-logic

# 3. Ensure MongoDB is running
# (Start MongoDB in another terminal)
mongod

# 4. Start Meteor app
meteor

# 5. Visit application
# Open http://localhost:3000 in browser
```

### Quick Start: Deployment

#### Prerequisites
- SSH access to target servers
- SSH key-pair in `~/.ssh/id_rsa`
- Servers running Ubuntu/Linux
- Port 3000 accessible (or behind load balancer)

#### Deploy to Production

```bash
# 1. Configure deployment
cd .deploy_mup
# Edit mup.json with your server IPs and paths

# 2. Deploy
mup deploy

# 3. Check status
mup status

# 4. View logs
mup logs -f

# 5. SSH to server (if needed)
mup ssh server.0
```

#### Deploy to Test Server

```bash
# Similar to production, but use .deploy_test
cd .deploy_test
mup deploy
```

### Quick Start: First-Time Server Setup

```bash
# 1. SSH into server
ssh root@your-server-ip

# 2. Install Meteor Up (if not already installed)
npm install -g mup

# 3. Create app directory
mkdir -p ~/love-logic-app
cd ~/love-logic-app

# 4. Initialize MUP
mup init

# 5. Edit mup.json with app details

# 6. Setup servers (first time only)
mup setup

# 7. Deploy app
mup deploy

# 8. Verify running
curl https://localhost:3000  # If on server
# Or check from client machine
curl https://your-domain.com
```

### Quick Start: Troubleshooting

#### Application won't start

```bash
# Check server logs
mup logs -f

# Common issues:
# - MONGO_URL not set
# - MongoDB not running
# - Port 3000 in use
# - Insufficient disk space
```

#### Can't connect to MongoDB

```bash
# Check MongoDB connection string
echo $MONGO_URL

# Verify MongoDB is running
mongo  # Try connecting locally

# Check replica set status (if using replication)
mongo --eval "rs.status()"
```

#### WebSocket issues

```bash
# If clients can't connect:
# 1. Check DISABLE_WEBSOCKETS setting (try setting to 1)
# 2. Check firewall allows WebSocket connections
# 3. Check browser console for connection errors
```

### Quick Start: Backup & Recovery

#### Backup Database

```bash
# SSH into server
ssh root@your-server-ip

# Backup MongoDB
mongodump -d love-logic -o /backup/love-logic-$(date +%Y%m%d)

# Or using MUP
mup ssh server.0
# Then run mongodump commands
```

#### Restore Database

```bash
# Restore from backup
mongorestore -d love-logic /path/to/backup/love-logic
```

---

## Additional Configuration Files

### .meteor/packages
Contains list of all Meteor packages used (see Meteor Packages section)

### .meteor/versions
Pins exact versions of all packages for reproducible builds

### .meteor/release
Specifies Meteor version: METEOR@1.2.1

### settings.json Files
Each `.deploy_*/settings.json` contains deployment-specific settings (currently minimal)

---

## Performance Tuning

### Database Indexing
All critical indexes are created at startup via `Meteor.startup()` blocks

### MongoDB Replica Set
- Enables oplog tailing for real-time synchronization
- Automatic failover for high availability

### Clustering (meteorhacks:cluster)
- Horizontal scaling by running multiple instances
- Load balanced across instances
- Shared discovery via MongoDB

### Disabling WebSockets
- DISABLE_WEBSOCKETS=1 uses HTTP polling instead
- Useful in restricted network environments
- Slightly higher latency but more stable

### Minification
- Production builds automatically minify CSS/JS
- Reduces file size and load times
- Source maps available for debugging

---

## Security Considerations

### Authentication
- User passwords hashed with bcrypt (npm-bcrypt)
- SRP (Secure Remote Password) protocol support
- Session management via accounts-password

### reCaptcha
- Site key configured for user registration
- Can be enabled in lib/config/at_config.coffee
- Currently disabled (showReCaptcha: false)

### HTTPS/SSL
- ROOT_URL uses HTTPS in production
- Recommended for all production deployments
- Configure via MUP or reverse proxy/load balancer

### Email Verification
- User email verification can be enforced
- Links expire after configured time period
- Currently not required but available

### Authorization
- Publications check user IDs before sending data
- Methods validate user permissions server-side
- Tutors can only see their assigned students

---

## Support & Maintenance

### Documentation
- See README.md in project root for basic overview
- This file provides comprehensive deployment reference

### Monitoring
- Use `mup logs -f` to watch real-time logs
- Kadira tools available for performance monitoring
- Check MongoDB oplog for replication lag

### Updates
- Update Meteor: `meteor update`
- Update packages: `meteor update package-name`
- Test in development first, then deploy to test environment before production

### Contacts
- Original Author: Stephen A. Butterfill (2015)
- All rights reserved - Contact for licensing/modifications

---

## Change Log

**Meteor Version**: 1.2.1  
**Last Configured**: Unknown (based on .meteor/versions analysis)  
**Node Version**: 0.10.40  
**Server Count**: 1-6 depending on deployment

---

**END OF DEPLOYMENT CONFIGURATION DOCUMENT**

For questions or issues, refer to Meteor documentation (https://docs.meteor.com) or reach out to the project maintainer.
