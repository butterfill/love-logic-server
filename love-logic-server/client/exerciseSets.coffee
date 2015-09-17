
# -------------
# Template helpers

convertToExerciseId = (exerciseLink) ->
  return (encodeURIComponent(i) for i in exerciseLink.split('/')).join('/')

isSubmitted = (exerciseLink) ->
  exerciseId = convertToExerciseId exerciseLink
  return SubmittedExercises.find({exerciseId}).count() > 0

dateSubmitted = (exerciseLink) ->
  exerciseId = convertToExerciseId exerciseLink
  return SubmittedExercises.findOne({exerciseId})?.created


Template.exerciseSets.helpers
  institutions : () -> 
    return ExerciseSets.find()

Template.exerciseSetVariants.helpers
  setName : () ->
    return ExerciseSets.findOne()?.name
  setDescription : () ->
    return ExerciseSets.findOne()?.description
  url : () ->
    return Router.current().location.get().path
  variants : () -> 
    variants = ExerciseSets.findOne()?.variants
    return (v for k,v of variants)

Template.listExercises.helpers
  exerciseSetName : () ->
    return ExerciseSets.findOne()?.name
  exerciseSetDescription : () ->
    return ExerciseSets.findOne()?.description
  variantName : () ->
    controller = Iron.controller()
    params = controller.getParams()
    return params._variant
  lectures : () ->
    controller = Iron.controller()
    params = controller.getParams()
    return [] unless params
    exObj = ExerciseSets.findOne()?.variants[params._variant]?.exercises
    console.log params._variant
    console.log exObj
    lectureList = []
    for lecture of exObj
      unitList = []
      for unit, exercises of exObj[lecture]
        unitList.push {
          unit
          exercises : ({link:e, isSubmitted:isSubmitted(e), dateSubmitted:dateSubmitted(e)} for e in exercises)
        }
      lectureList.push {
        lecture
        units: unitList
      }

    
    return lectureList
        
    

# -------------
# User interactions


Template.listExercises.events
  'click button#subscribe' : (event, template) ->
    console.log "not implemented yet."
