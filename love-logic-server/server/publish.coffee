Meteor.publish "courses", () ->
  return Courses.find()

Meteor.publish "course", (courseName) ->
  return Courses.find({name:courseName})
Meteor.startup ->
  Courses._ensureIndex({name:1})

Meteor.publish "exercise_sets", (courseName) ->
  return ExerciseSets.find({courseName},{fields:{courseName:1, variant:1, description:1}})
Meteor.startup ->
  ExerciseSets._ensureIndex({courseName:1})

Meteor.publish "exercise_set", (courseName, variant) ->
  return ExerciseSets.find({courseName, variant})
Meteor.startup ->
  ExerciseSets._ensureIndex({courseName:1, variant:1})

Meteor.publish "subscriptions", ->
  return Subscriptions.find({ owner:@userId })
Meteor.startup ->
  Subscriptions._ensureIndex({owner:1})

# This is called by students to see their own progress.
# Param `userId` allows tutors to call this to see a tutee’s progress.
Meteor.publish "dates_exercises_submitted", (userId) ->
  userId ?= @userId
  if @userId isnt userId
    studentId = userId
    throw new Meteor.Error "not authorized" unless checkIsTutee(@userId, studentId)
  return SubmittedExercises.find({ owner:userId }, {fields:{created:1, exerciseId:1, 'humanFeedback.isCorrect':1, 'machineFeedback.isCorrect':1}})
Meteor.startup ->
  SubmittedExercises._ensureIndex({owner:1})

# This is called by students to see everything they have submitted.
# Param `userId` allows tutors to call this to see a tutee’s progress.
Meteor.publish "submitted_exercises", (userId) ->
  userId ?= @userId
  if @userId isnt userId
    studentId = userId
    throw new Meteor.Error "not authorized" unless checkIsTutee(@userId, studentId)
  return SubmittedExercises.find({ owner:userId })

# check `userId` is a tutee of the currently logged-in user.
checkIsTutee = (userId, studentId) ->
  student = Meteor.users.findOne(studentId)
  seminarTutorEmail = student?.profile?.seminar_tutor
  return false unless seminarTutorEmail?

  user = Meteor.users.findOne(userId)
  currentUserEmail = user?.emails?[0]?.address
  
  isTutee = (seminarTutorEmail is currentUserEmail)
  return isTutee unless user.profile?.is_instructor and not isTutee
  
  # special case: user is an instructor
  # so we want to check whether the studentId is a tutee of a tutor of the instructor
  instructorEmail = currentUserEmail
  tutorsOfInstructor = Meteor.users.find({'profile.instructor':instructorEmail}).fetch()
  tutorEmails = (x.emails?[0]?.address for x in tutorsOfInstructor)
  isTutee = seminarTutorEmail in tutorEmails
  

Meteor.publish "submitted_exercise", (exerciseId) ->
  # if(Meteor.isServer)
  #   Meteor._sleepForMs(10000)
  return SubmittedExercises.find({owner:@userId, exerciseId:exerciseId})
Meteor.startup ->
  SubmittedExercises._ensureIndex({owner:1, exerciseId:1})

Meteor.publish "help_request", (exerciseId) ->
  # if(Meteor.isServer)
  #   Meteor._sleepForMs(10000)
  return HelpRequest.find( {requesterId:@userId, exerciseId:exerciseId} )
Meteor.startup ->
  HelpRequest._ensureIndex({requesterId:1,exerciseId:1})

Meteor.publish "graded_answers", (exerciseId) ->
  return GradedAnswers.find({exerciseId})
Meteor.startup ->
  GradedAnswers._ensureIndex({exerciseId:1})

Meteor.publish "next_exercise_with_unseen_feedback", ->
  SubmittedExercises.find({owner:@userId, 'humanFeedback.studentSeen':false}, {limit:1})
Meteor.startup ->
  SubmittedExercises._ensureIndex({owner:1,'humanFeedback.studentSeen':1})

Meteor.publish "exercises_with_unseen_feedback", ->
  SubmittedExercises.find({ owner:@userId, 'humanFeedback.studentSeen':false })


Meteor.publish "next_help_request_with_unseen_answer", ->
  HelpRequest.find({ requesterId:@userId, answer:{$exists:true}, studentSeen:{$exists:false} }, {limit:1})
Meteor.startup ->
  HelpRequest._ensureIndex({requesterId:1,answer:1,studentSeen:1})
  


# ===
# Publications for seminar tutors

Meteor.publish "tutee_user_info", (userId) ->
  if @userId isnt userId
    studentId = userId
    throw new Meteor.Error "not authorized" unless checkIsTutee(@userId, studentId)
  return Meteor.users.find(userId, {fields:{emails:1, "profile.name":1}})


Meteor.publish "tutees", (tutorId) ->
  unless tutorId
    tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  else
    instructorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    # query for tutor ensures that the current user is the instructor for the tutor’s course
    tutor = Meteor.users.findOne({_id:tutorId, 'profile.instructor':instructorEmail})
    tutorEmail = tutor.emails?[0]?.address
  if not tutorEmail
    console.log "Tutor has no email address!"
    return [] 
  return Meteor.users.find({'profile.seminar_tutor':tutorEmail})
Meteor.startup ->
  Meteor.users._ensureIndex({"profile.seminar_tutor":1})

Meteor.publish "tutees_subscriptions", (tutorId) ->
  unless tutorId
    tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  else
    instructorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    # query for tutor ensures that the current user is the instructor for the tutor’s course
    tutor = Meteor.users.findOne({_id:tutorId, 'profile.instructor':instructorEmail})
    tutorEmail = tutor.emails?[0]?.address
  if not tutorEmail
    console.log "Tutor has no email address!"
    return [] 
  tuteeIds = wy.getTuteeIds(tutorEmail)
  return Subscriptions.find( {owner:{$in:tuteeIds}} )

# Leave `tutorId` undefined to get them all
Meteor.publish "tutors_for_instructor", (tutorId) ->
  instructorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  if not instructorEmail
    console.log "Current user has no email address!"
    return [] 
  unless tutorId
    return Meteor.users.find({'profile.instructor':instructorEmail})
  else
    return Meteor.users.find({_id:tutorId, 'profile.instructor':instructorEmail})
Meteor.startup ->
  Meteor.users._ensureIndex({"profile.instructor":1})
  

# If `tuteeId` is not specified, return submitted answers by the current user’s tutees.
# If `tuteeId` is specified, return submitted answers by that tutee.
Meteor.publish "submitted_answers", (exerciseId, tuteeId) ->
  if tuteeId?
    if @userId isnt tuteeId
      throw new Meteor.Error "not authorized" unless checkIsTutee(@userId, tuteeId)
    return SubmittedExercises.find({exerciseId:exerciseId, owner:tuteeId})
  else
    #restrict to TA’s own students
    tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    tuteeIds = wy.getTuteeIds(tutorEmail)
    return SubmittedExercises.find({exerciseId:exerciseId, owner:{$in:tuteeIds}})
Meteor.startup ->
  SubmittedExercises._ensureIndex({exerciseId:1, owner:1})

# Return help requests by the current user’s tutees.
Meteor.publish "help_requests_for_tutor", (exerciseId) ->
  #restrict to TA’s own students
  tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  tuteeIds = wy.getTuteeIds(tutorEmail)
  return HelpRequest.find({exerciseId:exerciseId, requesterId:{$in:tuteeIds}})
Meteor.startup ->
  HelpRequest._ensureIndex({exerciseId:1, requesterId:1})

Meteor.publish "all_unanswered_help_requests_for_tutor", () ->
  #restrict to TA’s own students
  tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  tuteeIds = wy.getTuteeIds(tutorEmail)
  return HelpRequest.find({ requesterId:{$in:tuteeIds}, answer:{$exists:false}})
Meteor.startup ->
  HelpRequest._ensureIndex({requesterId:1})

# Return fields from `SubmittedExercises` for working out what proportion of exercises tutees have completed.
Meteor.publish "tutees_progress", (tutorId) ->
  unless tutorId
    tutorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  else
    instructorEmail = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    # query for tutor ensures that the current user is the instructor for the tutor’s course
    tutor = Meteor.users.findOne({_id:tutorId, 'profile.instructor':instructorEmail})
    tutorEmail = tutor.emails?[0]?.address
  
  if not tutorEmail
    console.log "Tutor has no email address!"
    return [] 

  tuteeIds = wy.getTuteeIds(tutorEmail)
  return SubmittedExercises.find( {owner:{$in:tuteeIds}}, {fields:{'owner':1, 'exerciseId':1, 'humanFeedback.isCorrect':1, 'machineFeedback.isCorrect':1, 'created':1}} )

