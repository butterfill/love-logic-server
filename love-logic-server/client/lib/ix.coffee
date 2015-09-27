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

# The student’s work in progress (in an editor) is stored under this key.
ix.getSessionKeyForUserExercise = () ->
  return "#{ix.getUserId()}/#{ix.getExerciseId()}"
ix.getAnswer = () ->
  Session.get(ix.getSessionKeyForUserExercise())
ix.setAnswer = (answer) ->
  Session.setPersistent(ix.getSessionKeyForUserExercise(), answer)




# ====
# proofs


# Extract premises from the URL.  Remove any premises which are `true`
# (so you can set proofs with no premises).  Add an error if any 
# sentences cannot be parsed.
# Return a list of awFOL objects.
ix.getPremisesFromParams = () ->
  _premises = FlowRouter.getParam('_premises')
  txtList = decodeURIComponent(_premises).split('|')
  try
    folList = (fol.parse(t) for t in txtList)
  catch e
    return ["Sorry, there is an error with the URL you gave (#{e})."]
  folList = (e for e in folList when not (e.type is 'value' and e.value is true))
  return folList

# Extract the conclusion from the URL.
# Return it as an awFOL object.
ix.getConclusionFromParams = () ->
  _conclusion = FlowRouter.getParam('_conclusion')
  try
    e = fol.parse(decodeURIComponent(_conclusion))
  catch error
    return "Sorry, there is an error with the URL you gave (#{error})."
  return e

# Extract the proof to be written from the params.  
ix.getProofFromParams = () ->
  premiseTxt = (t.toString({replaceSymbols:true}) for t in ix.getPremisesFromParams()).join('\n| ')
  conclusionTxt = ix.getConclusionFromParams().toString({replaceSymbols:true})
  return "| #{premiseTxt}\n|---\n| \n| \n| #{conclusionTxt}"  
  

ix.checkPremisesAndConclusionOfProof = (theProof) ->
    # Now check the conclusion is what its supposed to be.
    conclusionIsOk = theProof.getConclusion().isIdenticalTo( ix.getConclusionFromParams() )
    if not conclusionIsOk 
      return "Your conclusion (#{theProof.getConclusion()}) is not the one you were supposed to prove (#{ix.getConclusionFromParams()})."
    # Finally, check no premises other than those stipulated have been used (but
    # you don't have to use the premises given.)
    proofPremises = theProof.getPremises()
    proofPremisesStr = (p.toString({replaceSymbols:true}) for p in proofPremises)
    actualPremisesList = (p.toString({replaceSymbols:true}) for p in ix.getPremisesFromParams())
    proofPremisesNotInActualPremises = _.difference proofPremisesStr, actualPremisesList
    premisesAreOk = proofPremisesNotInActualPremises.length is 0
    if not premisesAreOk
      return "Your premises (#{proofPremisesStr.join(', ')}) are not the ones you were supposed to start from---you added #{proofPremisesNotInActualPremises.join(', ')}."
    #Everything is  ok
    return true
