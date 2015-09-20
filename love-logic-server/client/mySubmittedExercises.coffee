

Template.mySubmittedExercises.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('submitted_exercises')
    
Template.mySubmittedExercises.helpers
  testd : () ->
    return "ok"
  exercises : () ->
    return SubmittedExercises.find().fetch()