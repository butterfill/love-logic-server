Meteor.startup ->
  # code to run on server at startup
  SubmittedExercises._ensureIndex({owner:1})
  SubmittedExercises._ensureIndex({exerciseId:1})
  return


