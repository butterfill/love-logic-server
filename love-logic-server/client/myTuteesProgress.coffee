
Template.myTuteesProgress.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe 'tutees'
    templateInstance.subTuteesProgress = templateInstance.subscribe 'tutees_progress'
    templateInstance.subscribe 'tutees_subscriptions'


getNumberSubmitted = (dataCtx, sinceDate) -> 
  dataCtx ?= this
  if dataCtx._id?
    # Restrict the query to SubmittedExercises owned by a particular tutee.
    q = {owner:dataCtx._id}
  else
    q = {}
  if sinceDate?
    q.created = {$gte:sinceDate}
  return SubmittedExercises.find(q).count()

DAYSAGO7 = moment().subtract(7, "days").toDate()

getNumberSubmitted7Days = (dataCtx) ->
  dataCtx ?= this
  getNumberSubmitted(dataCtx, DAYSAGO7)  
  
getPercent = (value, total) -> Math.floor((value / total) * 100) or 0

_getQuery = (dataCtx) ->
  # Restrict the query to SubmittedExercises owned by a particular tutee.
  return {owner:dataCtx._id} if dataCtx? and dataCtx._id?
  return {}
_onlyCorrect = (dataCtx) ->
  q = _getQuery(dataCtx)
  q.$or = [ {'humanFeedback.isCorrect': true}, {'machineFeedback.isCorrect': true} ]
  return q
_onlyIncorrect = (dataCtx) ->
  q = _getQuery(dataCtx)
  q.$or = [ {'humanFeedback.isCorrect': false}, {'machineFeedback.isCorrect': false} ]
  return q
_onlyUngraded = (dataCtx) ->
  q = _getQuery(dataCtx)
  q['humanFeedback.isCorrect'] = {$exists:false}
  q['machineFeedback.isCorrect'] = {$exists:false}
  return q
_onlyLast7Days = (q) ->
  q.created = {$gte:DAYSAGO7}
  return q
  
_getTutees = () ->
  tutor_email = Meteor.user()?.emails?[0]?.address
  return Meteor.users.find({'profile.seminar_tutor':tutor_email})
  
Template.myTuteesProgress.helpers
  nofTutees : () -> _getTutees().count()
  'tutees' : _getTutees
  'email' : () ->
    return @emails?[0]?.address

  meanNumberSubmitted : () ->
    # We assume that all `SubmittedExercises` currently available are from tutees.
    return Math.floor(SubmittedExercises.find({}).count() / _getTutees().count())
  meanNumberSubmitted7days : () ->
    q = _onlyLast7Days({})
    return Math.floor(SubmittedExercises.find(q).count() / _getTutees().count())
    
    
  
  # These are called where the data context is a tutee (`Meteor.user`)
  'number_submitted' : getNumberSubmitted
  'number_submitted_7days' : getNumberSubmitted7Days
  # The following are called both for the overall figures (at the top  of the page)
  # and for the individual tutees.  When called with individual tutees, @ will be
  # the user record for the tutee; when called for the overall figures, @_id? will be false.
  'percentCorrect' : () -> 
    q = _onlyCorrect(@)
    numCorrect = SubmittedExercises.find(q).count()
    numSubmitted = getNumberSubmitted(@)
    return getPercent(numCorrect, numSubmitted)
  'percentCorrect7Days' : () -> 
    q = _onlyCorrect(@)
    q = _onlyLast7Days(q)
    numCorrect = SubmittedExercises.find(q).count()
    numSubmitted = getNumberSubmitted7Days(@)
    return getPercent(numCorrect, numSubmitted)
  'percentIncorrect' : () -> 
    q = _onlyIncorrect(@)
    numIncorrect = SubmittedExercises.find(q).count()
    numSubmitted = getNumberSubmitted(@)
    return getPercent(numIncorrect, numSubmitted)
  'percentIncorrect7Days' : () -> 
    q = _onlyIncorrect(@)
    q = _onlyLast7Days(q)
    numIncorrect = SubmittedExercises.find(q).count()
    numSubmitted = getNumberSubmitted7Days(@)
    return getPercent(numIncorrect, numSubmitted)
  'percentUngraded' : () -> 
    q = _onlyUngraded(@)
    numUngraded = SubmittedExercises.find(q).count()
    numSubmitted = getNumberSubmitted(@)
    return getPercent(numUngraded, numSubmitted)
  'percentUngraded7Days' : () -> 
    q = _onlyUngraded(@)
    q = _onlyLast7Days(q)
    numUngraded = SubmittedExercises.find(q).count()
    numSubmitted = getNumberSubmitted7Days(@)
    return getPercent(numUngraded, numSubmitted)
    
  'correct7Days' : () -> 
    q = _onlyCorrect(@)
    q = _onlyLast7Days(q)
    return SubmittedExercises.find(q)
  'incorrect7Days' : () -> 
    q = _onlyIncorrect(@)
    q = _onlyLast7Days(q)
    return SubmittedExercises.find(q)
  'ungraded7Days' : () -> 
    q = _onlyUngraded(@)
    q = _onlyLast7Days(q)
    return SubmittedExercises.find(q)
  
  'subscriptions' : () -> Subscriptions.find({owner:@_id})
  
  # These are called where the data context is a `Subscription`.
  # Used to pass to the `display_subscription` template
  'userQueryParam' :() -> "user=#{@owner}"
  
  # These are called when the data context is a SubmittedExercise
  gradeURL : () -> (@exerciseId.replace(/\/$/, ''))+"/grade?user=#{@owner}"
  exerciseLink : () -> decodeURIComponent(@exerciseId)

Template.myTuteesProgress.events
  # TODO: this is not ideal but I can’t find a better way
  'click .collapsible' : (event, template) -> 
    if not template.doneInitCollapsible?
      $('.collapsible').collapsible()
      template.doneInitCollapsible = true
      $(event.target).click()
