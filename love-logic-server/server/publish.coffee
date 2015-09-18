Meteor.publish "submitted_exercises", () ->
  # return SubmittedExercises.find()
  return SubmittedExercises.find({ owner: this.userId })

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

Meteor.publish "work_in_progress", () ->
  return WorkInProgress.find({ owner: this.userId })