
Template.myTutees.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe 'tutees'
    templateInstance.subscribe 'tutees_subscriptions'

Template.myTutees.helpers
  'tutees' : () ->
    tutor_email = Meteor.user()?.emails?[0]?.address
    return Meteor.users.find({'profile.seminar_tutor':tutor_email})
  'email' : () ->
    return @emails?[0]?.address

  # called when data context is a tutee
  'subscriptions' : () -> Subscriptions.find({owner:@_id})
  # These are called where the data context is a `Subscription`.
  # Used to pass to the `display_subscription` template
  'userQueryParam' :() -> "user=#{@owner}"
  