# Functions used across a various template helpers or event handlers

@ix = {}

# ----
# Meteor general

# Decodes and returns the params from the url
ix.getParams = () ->
  controller = Iron.controller()
  result = {}
  for k, v of controller.getParams()
    result[k] = decodeURIComponent(v)
  return result
  
# Return the current url.
ix.url = () ->
  return decodeURIComponent(Router.current().location.get().path)





# ----
# Relating to Exercises

# Converts a link specifying an exercise to the `exerciseId` used in the database
ix.convertToExerciseId = (exerciseLink) ->
  return (encodeURIComponent(i) for i in exerciseLink.split('/')).join('/')

# Get the exerciseId of the current page
ix.getExerciseId = () ->
  exerciseLink = ix.url()
  return ix.convertToExerciseId(exerciseLink)


# Returns true if the current user has already submitted the exercise specified by `exerciseLink`
# If `exerciseLink` is not given, uses the current url.
ix.isSubmitted = (exerciseLink) ->
  if not exerciseLink?
    exerciseLink = ix.url()
  exerciseId = ix.convertToExerciseId exerciseLink
  return SubmittedExercises.find({exerciseId}).count() > 0

# Returns the date the user submitted the specified exercise.
ix.dateSubmitted = (exerciseLink) ->
  if not exerciseLink?
    exerciseLink = ix.url()
  exerciseId = ix.convertToExerciseId exerciseLink
  return moment(SubmittedExercises.findOne({exerciseId})?.created).fromNow()


# Returns the answer submitted by the current user 
ix.getSubmission = (exerciseLink) ->
  if not exerciseLink?
    exerciseLink = ix.url()
  exerciseId = ix.convertToExerciseId exerciseLink
  return SubmittedExercises.findOne({exerciseId})

ix.submitExercise = (exercise) ->
    
    Meteor.call('submitExercise', _.defaults(exercise,
      exerciseId : ix.convertToExerciseId(ix.url())
    ))

ix.saveWorkInProgress = (text) ->
  exerciseId = ix.getExerciseId()
  console.log "saving #{exerciseId}"
  Meteor.call('saveWorkInProgress', exerciseId, text)

ix.getWorkInProgress = () ->
  exerciseId = ix.getExerciseId()
  console.log "restoring #{exerciseId}"
  return WorkInProgress.findOne({exerciseId})
  
  
  
