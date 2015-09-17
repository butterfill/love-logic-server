# -------------
# Template helpers

Template.exerciseSets.helpers
  institutions : () -> 
    return ExerciseSets.find()
