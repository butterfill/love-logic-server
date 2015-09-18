
# -------------



Template.courses.helpers
  courses : () -> 
    return Courses.find()

Template.exerciseSetsForCourse.helpers
  courseName : () ->
    return Courses.findOne()?.name
  courseDescription : () ->
    return Courses.findOne()?.description
  url : () ->
    return ix.url()
  exerciseSets : () -> 
    return ExerciseSets.find()

Template.exerciseSet.helpers
  courseName : () ->
    return Courses.findOne()?.name
  courseDescription : () ->
    return Courses.findOne()?.description
  exerciseSetName : () ->
    return ix.getParams()?._variant or ''
  lectures : () ->
    exObj = ExerciseSets.findOne()?.exercises
    return [] if not exObj
    console.log exObj
    lectureList = []
    for lecture of exObj
      unitList = []
      for unit, exercises of exObj[lecture]
        unitList.push {
          unit
          exercises : ({name:e, link:ix.convertToExerciseId(e), isSubmitted:ix.isSubmitted(e), dateSubmitted:ix.dateSubmitted(e)} for e in exercises)
        }
      lectureList.push {
        lecture
        units: unitList
      }

    
    return lectureList
        

# -------------
# User interactions


Template.exerciseSet.events
  'click button#subscribe' : (event, template) ->
    console.log "not implemented yet."
