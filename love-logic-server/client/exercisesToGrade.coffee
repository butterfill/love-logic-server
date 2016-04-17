
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
createExerciseList = (exToGrade, exerciseSet) ->
  exercises = (decodeURIComponent(e.exerciseId) for e in exToGrade)
  exSetOut = { lectures:[] }
  lectureParam = FlowRouter.getParam('_lecture')
  unitParam = FlowRouter.getParam('_unit')
  for lecture in exerciseSet.lectures
    if lectureParam?
      continue unless lecture.name is lectureParam
    lectureOut = { name:lecture.name, units:[], nofExercises:0 }
    for unit in lecture.units
      if unitParam?
        continue unless unit.name is unitParam
      unitOut = { name:unit.name, exercises:[], nofExercises:0 }
      for e in unit.rawExercises
        if e in exercises
          unitOut.exercises.push({exerciseId:e})
          unitOut.nofExercises += 1
          lectureOut.nofExercises += 1
      if unitOut.exercises.length > 0 or unit.name is unitParam
        lectureOut.units.push(unitOut)
    if lectureOut.units.length > 0 or lecture.name is lectureParam
      exSetOut.lectures.push(lectureOut)
  return exSetOut.lectures


Template.exercisesToGradeForExerciseSet.onCreated () ->
  templateInstance = this
  
  # This autorun shouldn’t re-run when the url changes
  @exercises = new ReactiveVar()
  @autorun () ->
    Meteor.call "getExercisesToGrade", (error, result) ->
      templateInstance.exercises.set( result )
      
  # This autorun should re-run when the url changes
  @exerciseList = new ReactiveVar()
  @autorun () ->
    FlowRouter.watchPathChange()
    variant = FlowRouter.getParam('_variant' )
    courseName = FlowRouter.getParam('_courseName' )
    exSetSub = templateInstance.subscribe 'exercise_set', courseName, variant
    if Template.instance().exercises?.get?()? and exSetSub.ready()
      exercises = Template.instance().exercises.get()
      exerciseSet = ExerciseSets.findOne({courseName:FlowRouter.getParam('_courseName' ), variant:FlowRouter.getParam('_variant' )})
      templateInstance.exerciseList.set( createExerciseList(exercises, exerciseSet) )

Template.exercisesToGradeForExerciseSet.helpers
  paramsSpecifyLecture : () -> FlowRouter.getParam('_lecture' )?
  paramsSpecifyUnit : () -> FlowRouter.getParam('_unit' )?
  variant : () -> FlowRouter.getParam('_variant' )
  courseName : () -> FlowRouter.getParam('_courseName' )
  'exerciseSetURLQuery' : () -> 
    courseName = FlowRouter.getParam('_courseName' )
    variant = FlowRouter.getParam('_variant' )
    return "?courseName=#{courseName}&variant=#{variant}"
  'exerciseList' : () -> Template.instance().exerciseList?.get?()
  'gradeURL' : () -> (@exerciseId.replace(/\/$/, ''))+"/grade"
  'exerciseName' : () -> decodeURIComponent(@exerciseId)
  lectureNameOfUnit : () ->
    lecture = Template.parentData()
    return lecture.name