
Template.exercisesToGrade.onCreated () ->
  templateInstance = this
  templateInstance.exercises = new ReactiveVar()
  templateInstance.autorun () ->
    Meteor.call "getExercisesToGrade", (error, result) ->
      templateInstance.exercises.set(result)
      console.log result

Template.exercisesToGrade.helpers
  'exercises' : () ->
    console.log "updating exercises"
    return Template.instance().exercises.get()
  'gradeURL' : () ->
    return (@exerciseId.replace(/\/$/, ''))+"/grade"
  'exerciseName' : () ->
    return decodeURIComponent(@exerciseId)