

# -------------
# Template helpers

Template.main.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('subscriptions')
    self.subscribe('next_exercise_with_unseen_feedback')

getNextExercisesWithUnseenFeedback = () ->
  return SubmittedExercises.findOne({ $and:[{owner:Meteor.userId()}, {'humanFeedback.studentSeen':false}] })

Template.main.helpers
  hasSubscriptions : () ->
    return Subscriptions.find().count() >0
  hasNoSubscriptions : () ->
    return Subscriptions.find().count() is 0
  subscriptions : () ->
    return Subscriptions.find()

  hasSeminarTutor : () ->
    return true
  seminarTutor : () ->
    return "Ayesha Beatrix"
  
  hasNewGrades : () ->
    return getNextExercisesWithUnseenFeedback()?
  nextUnseenFeedbackLink : () ->
    ex = getNextExercisesWithUnseenFeedback()
    link = ex.exerciseId
    return link
  
  hasNewHelpRequestAnswers : () ->
    return true
  
  emailAddress : () ->
    return ix.getUserEmail()