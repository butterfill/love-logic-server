
Template.exercisesToGrade.onCreated () ->
  templateInstance = this
  templateInstance.exercises = new ReactiveVar()
  templateInstance.autorun () ->
    Meteor.call "getExercisesToGrade", (error, result) ->
      templateInstance.exercises.set(result)
      # Make the user a tutor is she is not a tutor already
      unless Meteor.user().profile?.is_seminar_tutor?
        Meteor.call "makeMeATutor"

Template.exercisesToGrade.helpers
  'exercises' : () ->
    # console.log Template.instance().exercises.get()
    return Template.instance().exercises?.get?()
  'gradeURL' : () ->
    return (@exerciseId.replace(/\/$/, ''))+"/grade"
  'exerciseName' : () ->
    return decodeURIComponent(@exerciseId)