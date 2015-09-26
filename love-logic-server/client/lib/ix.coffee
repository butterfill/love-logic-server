# Functions used across various template helpers or event handlers.
# Note: this runs on the client only.

@ix = {}

# ----
# Meteor general

# Return the `_id` of the current user.
ix.getUserId = () ->
  if Meteor.user()?._id
    return Meteor.user()._id
  return undefined

ix.getUserEmail = () ->
  if Meteor.user()?.emails?[0]?.address?
    return Meteor.user().emails[0].address
  return undefined
  

# Return the current url minus any querystring.
ix.url = () ->
  # # NOTE: this would make calls to ix.url reactive
  # FlowRouter.watchPathChange()
  path = FlowRouter.current().path?.split('?')[0]
  if path 
    return decodeURIComponent(path)
  return undefined

ix.queryString = () ->
  # # NOTE: this would make calls to ix.url reactive
  # FlowRouter.watchPathChange()
  path = FlowRouter.current().path
  if path 
    parts = path.split('?')
    if parts.length >0
      return parts[1]
    return ""
  return undefined
  


# ----
# Relating to Exercises

# Converts a link specifying an exercise to the `exerciseId` used in the database
ix.convertToExerciseId = (exerciseLink) ->
  # Remove any trailing slash
  exerciseLink = exerciseLink.replace /\/?$/, ''
  return (encodeURIComponent(i) for i in exerciseLink.split('/')).join('/')

# Get the exerciseId of the current page (when called from a 
# page like `/ex/proof/from/A%7CB%7CC/to/A%20and%20(B%20and%20C)`)
ix.getExerciseId = () ->
  exerciseLink = ix.url()
  return undefined unless exerciseLink
  # Remove any trailing slash
  exerciseLink = exerciseLink.replace /\/$/, ''
  # Remove the extra bit added when grading
  exerciseLink = exerciseLink.replace /\/grade\/?$/, ''
  return ix.convertToExerciseId(exerciseLink) 


# Returns true if the current user has already submitted the exercise specified by `exerciseLink`
# If `exerciseLink` is not given, uses the current url.
ix.isSubmitted = (exerciseLink) ->
  if not exerciseLink?
    exerciseId = ix.getExerciseId()
  else
    exerciseId = ix.convertToExerciseId exerciseLink
  return SubmittedExercises.find({exerciseId}).count() > 0

ix.submitExercise = (exercise, cb) ->
  Meteor.call('submitExercise', _.defaults(exercise,
    exerciseId : ix.convertToExerciseId(ix.url())
  ), cb)


# Return an object specifying the lecture and unit in which the present 
# exercise occurs, and also the next exercise in the series (if any).
# Used by the `next_exercise` template.
# Note: this should be called in a context where there is a subscription to a 
# single `ExerciseSet`.
ix.getExerciseContext = () ->
  currentExLink = decodeURIComponent(ix.getExerciseId())
  exSet = ExerciseSets.findOne()
  return undefined unless exSet?.lectures?
  for lecture, lectureIdx in exSet.lectures
    for unit, unitIdx in lecture.units
      for link, linkIdx in unit.rawExercises
        if link is currentExLink
          next = undefined
          if unit.rawExercises.length > linkIdx+1
            next = unit.rawExercises[linkIdx+1]
          else
            if lecture.units.length > unitIdx+1
              next = lecture.units[unitIdx+1].rawExercises[0]
            else
              if exSet.lectures.length > lectureIdx+1
                next = exSet.lectures[lectureIdx+1].units[0].rawExercises[0]
          return {
            lecture
            unit
            next
            exerciseSet : exSet
          }

