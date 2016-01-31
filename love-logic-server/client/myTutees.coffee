
Template.myTutees.onCreated () ->
  templateInstance = this
  tutorId = FlowRouter.getQueryParam('tutor') 
  # tutorId is undefined if no query parameter
  templateInstance.autorun () ->
    if tutorId
      templateInstance.subscribe 'tutors_for_instructor', tutorId
      
    # doesn’t matter whether tutorId is undefined for these subscriptions
    templateInstance.subscribe 'tutees', tutorId
    templateInstance.subscribe 'tutees_subscriptions', tutorId

Template.myTutees.helpers
  forSelf : () -> FlowRouter.getQueryParam('tutor') is undefined
  tutorName : () ->
    tutorId = FlowRouter.getQueryParam('tutor')
    return Meteor.users.findOne(tutorId)?.profile?.name
  tutorEmail : () ->
    tutorId = FlowRouter.getQueryParam('tutor')
    return Meteor.users.findOne(tutorId)?.emails?[0]?.address
  'tutees' : () ->
    tutorId = FlowRouter.getQueryParam('tutor')
    if not tutorId?
      tutor_email = Meteor.user()?.emails?[0]?.address
    else
      tutor_email = Meteor.users.findOne(tutorId)?.emails?[0]?.address
    return Meteor.users.find({'profile.seminar_tutor':tutor_email})

  # called when data context is a tutee
  'email' : () ->
    return @emails?[0]?.address
  'subscriptions' : () -> Subscriptions.find({owner:@_id})
  
  # Called where the data context is a `Subscription`.
  # Used to pass to the `display_subscription` template
  'userQueryParam' :() -> "user=#{@owner}"
  