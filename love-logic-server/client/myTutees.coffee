
Template.myTutees.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe 'tutees'
    templateInstance.subscribe 'exercises_to_mark'

Template.myTutees.helpers
  'tutees' : () ->
    tutor_email = Meteor.user()?.emails?[0]?.address
    return Meteor.users.find({'profile.seminar_tutor':tutor_email})
  'email' : () ->
    console.log this
    return @emails?[0]?.address