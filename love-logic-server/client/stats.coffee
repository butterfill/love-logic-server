
Template.stats.onCreated () ->
  templateInstance = this
  templateInstance.nofUsers = new ReactiveVar()
  templateInstance.nofUsersWithSeminarTutor = new ReactiveVar()
  templateInstance.nofUsersWithWarwickSeminarTutor = new ReactiveVar()
  templateInstance.nofSubmittedExercises = new ReactiveVar()
  templateInstance.nofSubmittedExercisesNoResubmits = new ReactiveVar()
  
  templateInstance.autorun () ->
    Meteor.call "getNofUsers", (error, result) ->
      templateInstance.nofUsers.set(result)
    Meteor.call "getNofUsersWithSeminarTutor", (error, result) ->
      templateInstance.nofUsersWithSeminarTutor.set(result)
    Meteor.call "getNofUsersWithSeminarTutor", ((error, result) ->
      templateInstance.nofUsersWithSeminarTutor.set(result)),
      '@warwick.ac.uk'
    Meteor.call "getNofSubmittedExercises", (error, result) ->
      templateInstance.nofSubmittedExercises.set(result)
    Meteor.call "getNofSubmittedExercisesNoResubmits", (error, result) ->
      templateInstance.nofSubmittedExercisesNoResubmits.set(result)

Template.stats.helpers
  'nofUsers' : () ->
    return Template.instance().nofUsers?.get?()
  'nofUsersWithSeminarTutor' : () ->
    return Template.instance().nofUsersWithSeminarTutor?.get?()
  'nofUsersWithWarwickSeminarTutor' : () ->
    return Template.instance().nofUsersWithWarwickSeminarTutor?.get?()
  'nofSubmittedExercises' : () ->
    return Template.instance().nofSubmittedExercises?.get?()
  'getNofSubmittedExercisesNoResubmits' : () ->
    return Template.instance().nofSubmittedExercisesNoResubmits?.get?()
    
  
    

    
