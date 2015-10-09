Meteor.startup ->
  # code to run on server at startup
  Meteor.users._ensureIndex({"profile.seminar_tutor":1})
  Subscriptions._ensureIndex({owner:1})
  SubmittedExercises._ensureIndex({owner:1})
  SubmittedExercises._ensureIndex({exerciseId:1})
  HelpRequest._ensureIndex({requesterId:1})
  HelpRequest._ensureIndex({exerciseId:1})
  GradedAnswers._ensureIndex({exerciseId:1})
  return


