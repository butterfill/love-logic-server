
Template.stats.onCreated () ->
  templateInstance = this
  templateInstance.nofUsers = new ReactiveVar()
  templateInstance.nofSubmittedExercises = new ReactiveVar()
  templateInstance.autorun () ->
    Meteor.call "getNofUsers", (error, result) ->
      templateInstance.nofUsers.set(result)
    Meteor.call "getNofSubmittedExercises", (error, result) ->
      templateInstance.nofSubmittedExercises.set(result)

Template.stats.helpers
  'nofUsers' : () ->
    return Template.instance().nofUsers?.get?()
  'nofSubmittedExercises' : () ->
    return Template.instance().nofSubmittedExercises?.get?()

    
