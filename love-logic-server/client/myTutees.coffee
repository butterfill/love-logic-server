
Template.myTutees.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe 'tutees'

Template.myTutees.helpers
  'tutees' : () ->
    tutor_email = Meteor.user()?.emails?[0]?.address
    return Meteor.users.find({'profile.seminar_tutor':tutor_email})
  'email' : () ->
    return @emails?[0]?.address