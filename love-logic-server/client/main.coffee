

# -------------
# Template helpers

Template.main.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('subscriptions')

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
  
  hasNewMarks : () ->
    return true
  hasNewHelpRequestAnswers : () ->
    return true
  
  emailAddress : () ->
    return ix.getUserEmail()