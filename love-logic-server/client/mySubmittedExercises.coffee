

Template.mySubmittedExercises.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('submitted_exercises')
    
Template.mySubmittedExercises.helpers
  exercises : () ->
    userId = ix.getUserId()
    return SubmittedExercises.find({ owner:userId }, {sort:{created:-1}})
  exerciseLink : () ->
    decodeURIComponent(@exerciseId)
  date : () ->
    return moment(@created).format("YYYY-MM-DD HH:mm")
  answerLines : () ->
    return ({line:x} for x in @answer.content.split('\n'))