

Template.mySubmittedExercises.onCreated () ->
  self = this
  self.autorun () ->
    userId = ix.getUserId()
    self.subscribe 'submitted_exercises', userId
    
Template.mySubmittedExercises.helpers
  exercises : () ->
    userId = ix.getUserId()
    return SubmittedExercises.find({ owner:userId }, {sort:{created:-1}})
  exerciseLink : () -> decodeURIComponent(@exerciseId)
  date : () ->
    return moment(@created).format("YYYY-MM-DD HH:mm")
  displayAnswer : () ->
    url = ix.url()
    type = url.split('/')[2]
    return "#{@answer.type}_ex_display_answer"
