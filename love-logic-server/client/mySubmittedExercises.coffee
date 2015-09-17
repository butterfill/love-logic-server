


Template.mySubmittedExercises.helpers
  testd : () ->
    return "ok"
  exercises : () ->
    return SubmittedExercises.find().fetch()