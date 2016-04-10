
Template.exercisesToGrade.onCreated () ->
  templateInstance = this
  @exercises = new ReactiveVar()
  @autorun () ->
    templateInstance.subscribe('subscriptions')
    Meteor.call "getExercisesToGrade", (error, result) ->
      templateInstance.exercises.set(result)
      # Make the user a tutor is she is not a tutor already
      unless Meteor.user().profile?.is_seminar_tutor?
        Meteor.call "makeMeATutor"

Template.exercisesToGrade.helpers
  'subscriptions' : () -> return Subscriptions.find()
  'urlQueryPart' : () -> window.location.search
  'exercises' : () -> Template.instance().exercises?.get?()
  'gradeURL' : () -> (@exerciseId.replace(/\/$/, ''))+"/grade"
  'exerciseName' : () -> decodeURIComponent(@exerciseId)



# puts `exToGrade` into an ExerciseSet
createExerciseList = (exToGrade) ->
  exercises = (decodeURIComponent(e.exerciseId) for e in exToGrade)
  exSetOut = { lectures:[] }
  exerciseSet = ExerciseSets.findOne({courseName:FlowRouter.getParam('_courseName' ), variant:FlowRouter.getParam('_variant' )})
  for lecture in exerciseSet.lectures
    if FlowRouter.getParam('_lecture')?
      continue unless lecture.name is FlowRouter.getParam('_lecture')
    lectureOut = { name:lecture.name, units:[] }
    for unit in lecture.units
      if FlowRouter.getParam('_unit')?
        continue unless unit.name is FlowRouter.getParam('_unit')
      unitOut = { name:unit.name, exercises:[] }
      for e in unit.rawExercises
        if e in exercises
          unitOut.exercises.push({exerciseId:e})
      if unitOut.exercises.length > 0
        lectureOut.units.push(unitOut)
    if lectureOut.units.length > 0
      exSetOut.lectures.push(lectureOut)
  return exSetOut.lectures


Template.exercisesToGradeForExerciseSet.onCreated () ->
  variant = FlowRouter.getParam('_variant' )
  courseName = FlowRouter.getParam('_courseName' )
  templateInstance = this
  @exerciseList = new ReactiveVar()
  @autorun () ->
    exSetSub = templateInstance.subscribe 'exercise_set', courseName, variant
    if exSetSub.ready()
      Meteor.call "getExercisesToGrade", (error, result) ->
        templateInstance.exerciseList.set( createExerciseList(result) )
      

Template.exercisesToGradeForExerciseSet.helpers
  paramsSpecifyLecture : () -> FlowRouter.getParam('_lecture' )?
  variant : () -> FlowRouter.getParam('_variant' )
  courseName : () -> FlowRouter.getParam('_courseName' )
  'exerciseSetURLQuery' : () -> 
    courseName = FlowRouter.getParam('_courseName' )
    variant = FlowRouter.getParam('_variant' )
    return "?courseName=#{courseName}&variant=#{variant}"
  'exerciseList' : () -> Template.instance().exerciseList?.get?()
  'gradeURL' : () -> (@exerciseId.replace(/\/$/, ''))+"/grade"
  'exerciseName' : () -> decodeURIComponent(@exerciseId)
  