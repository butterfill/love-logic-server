
Template.myTutors.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe 'tutors_for_instructor'
    unless Meteor.user().profile?.is_instructor?
      Meteor.call "makeMeAnInstructor"
    

Template.myTutors.helpers
  'tutors' : () ->
    instructorEmail = Meteor.user()?.emails?[0]?.address
    return Meteor.users.find({'profile.instructor':instructorEmail})
  'email' : () ->
    return @emails?[0]?.address

