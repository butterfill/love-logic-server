Meteor.publish "courses", () ->
  # return SubmittedExercises.find()
  return Courses.find()

Meteor.publish "course", (courseName) ->
  # return SubmittedExercises.find()
  return Courses.find({name:courseName})

Meteor.publish "exercise_sets", (courseName) ->
  # return SubmittedExercises.find()
  return ExerciseSets.find({courseName})

Meteor.publish "exercise_set", (courseName, variant) ->
  # return SubmittedExercises.find()
  return ExerciseSets.find({courseName, variant})

Meteor.publish "subscriptions", ->
  return Subscriptions.find({ owner:@userId })

Meteor.publish "work_in_progress", (exerciseId) ->
  return WorkInProgress.find({ $and:[{owner:@userId},{exerciseId:exerciseId}] })

Meteor.publish "submitted_exercises", () ->
  # if(Meteor.isServer)
  #   Meteor._sleepForMs(10000)
  return SubmittedExercises.find({ owner:@userId })

Meteor.publish "submitted_exercise", (exerciseId) ->
  # if(Meteor.isServer)
  #   Meteor._sleepForMs(10000)
  return SubmittedExercises.find({ $and:[{owner:@userId},{exerciseId:exerciseId}] })

Meteor.publish "submitted_answers", (exerciseId) ->
  #TODO restrict to TA’s own students
  return SubmittedExercises.find({exerciseId:exerciseId})
  