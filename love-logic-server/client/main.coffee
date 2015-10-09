

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
    return Meteor.user()?.profile?.seminar_tutor?
  seminarTutor : () ->
    return Meteor.user()?.profile?.seminar_tutor
  seminarTutorEmail : () ->
    return Meteor.user()?.profile?.seminar_tutor
  
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

Template.main.events
  'click #confirm-set-seminar-tutor-email' : (event, template) ->
    newAddress = $('textarea.seminarTutor').val()
    Meteor.call "updateSeminarTutor", newAddress, (error) ->
      if error
        Materialize.toast error.message, 4000
      else
        Materialize.toast "Your seminar tutor has been updated", 4000
  
  'click #confirm-update-email' : (event, template) ->
    newAddress = $('textarea.newEmailAddress').val()
    Meteor.call "updateEmailAddress", newAddress, (error) ->
      if error
        Materialize.toast error.message, 4000
      else
        Materialize.toast "Your email address has been updated", 4000
  
  
  'click .changeSeminarTutor' : (event, template) ->
    $('#seminar-tutor-modal').openModal()
  'click .changeEmail' : (event, template) ->
    $('#change-email-modal').openModal()

