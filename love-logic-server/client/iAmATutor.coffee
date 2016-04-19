Template.iAmATutor.onCreated () ->
  @autorun () ->
    # Make the user a tutor is she is not a tutor already
    unless Meteor.user().profile?.is_seminar_tutor?
      Meteor.call "makeMeATutor"

Template.iAmHonestlyReallyAndTrulyAnInstructor.onCreated () ->
  @autorun () ->
    # Make the user a tutor is she is not a tutor already
    unless Meteor.user().profile?.is_instructor?
      Meteor.call "makeMeAnInstructor"


Template.iAmATutor.helpers
  isTutor : ix.userIsTutor

Template.iAmHonestlyReallyAndTrulyAnInstructor.helpers
  isInstructor : ix.userIsInstructor

    
Template.iAmATutor.events
  'click #makeMeNotATutor' : (event, template) ->
    Meteor.call "makeMeNotATutor"
  'click #makeMeATutor' : (event, template) ->
    Meteor.call "makeMeATutor"
    
Template.iAmHonestlyReallyAndTrulyAnInstructor.events
  'click #makeMeNotAnInstructor' : (event, template) ->
    Meteor.call "makeMeNotAnInstructor"
  'click #makeMeAnInstructor' : (event, template) ->
    Meteor.call "makeMeAnInstructor"
  
  
    
