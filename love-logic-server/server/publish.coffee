Meteor.publish "submitted_exercises", () ->
  # return SubmittedExercises.find()
  return SubmittedExercises.find({ owner: this.userId })

Meteor.publish "exercise_sets", () ->
  # return SubmittedExercises.find()
  return ExerciseSets.find()

Meteor.publish "exercise_set", (id) ->
  # return SubmittedExercises.find()
  return ExerciseSets.find({_id:id})