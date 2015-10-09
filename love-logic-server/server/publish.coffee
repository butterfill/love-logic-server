Meteor.publish "courses", () ->
  return Courses.find()

Meteor.publish "course", (courseName) ->
  return Courses.find({name:courseName})

Meteor.publish "exercise_sets", (courseName) ->
  return ExerciseSets.find({courseName})

Meteor.publish "exercise_set", (courseName, variant) ->
  return ExerciseSets.find({courseName, variant})

Meteor.publish "subscriptions", ->
  return Subscriptions.find({ owner:@userId })

Meteor.publish "dates_exercises_submitted", () ->
  return SubmittedExercises.find({ owner:@userId }, {fields:{created:1, exerciseId:1}})

Meteor.publish "submitted_exercise", (exerciseId) ->
  # if(Meteor.isServer)
  #   Meteor._sleepForMs(10000)
  return SubmittedExercises.find({ $and:[{owner:@userId},{exerciseId:exerciseId}] })

Meteor.publish "help_request", (exerciseId) ->
  # if(Meteor.isServer)
  #   Meteor._sleepForMs(10000)
  return HelpRequest.find( {requesterId:@userId, exerciseId:exerciseId} )

Meteor.publish "graded_answers", (exerciseId) ->
  return GradedAnswers.find({exerciseId})

Meteor.publish "next_exercise_with_unseen_feedback", ->
  SubmittedExercises.find({ $and:[{owner:@userId}, {'humanFeedback.studentSeen':false}] }, {limit:1})

Meteor.publish "exercises_with_unseen_feedback", ->
  SubmittedExercises.find({ owner:@userId, 'humanFeedback.studentSeen':false })


Meteor.publish "next_help_request_with_unseen_answer", ->
  HelpRequest.find({ requesterId:@userId, answer:{$exists:true}, studentSeen:{$exists:false} }, {limit:1})
  


# ===
# Publications for seminar tutors

Meteor.publish "tutees", () ->
  tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  if not tutor_email
    console.log "Current user has no email address!"
    return [] 
  return Meteor.users.find({'profile.seminar_tutor':tutor_email})

# Return submitted answers by the current user’s tutees.
Meteor.publish "submitted_answers", (exerciseId) ->
  #restrict to TA’s own students
  tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  tuteeIds = wy.getTuteeIds(tutor_email)
  return SubmittedExercises.find({exerciseId:exerciseId, owner:{$in:tuteeIds}})

# Return help requests by the current user’s tutees.
Meteor.publish "help_requests_for_tutor", (exerciseId) ->
  #restrict to TA’s own students
  tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  tuteeIds = wy.getTuteeIds(tutor_email)
  return HelpRequest.find({exerciseId:exerciseId, requesterId:{$in:tuteeIds}})

Meteor.publish "all_unanswered_help_requests_for_tutor", () ->
  #restrict to TA’s own students
  tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
  tuteeIds = wy.getTuteeIds(tutor_email)
  return HelpRequest.find({ requesterId:{$in:tuteeIds}, answer:{$exists:false}})

