
Template.myTuteesProgress.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe 'tutees'
    templateInstance.subTuteesProgress = templateInstance.subscribe 'tutees_progress'
    templateInstance.subscribe 'tutees_subscriptions'
    
    FlowRouter.watchPathChange()
    variant = FlowRouter.getParam '_variant' 
    if variant?
      courseName = FlowRouter.getParam '_courseName'
      templateInstance.subscribe 'exercise_set', courseName, variant
    

isPageForParticularExercises = () ->
  variant = FlowRouter.getParam '_variant' 
  return variant?

getCurrentExerciseSet = () ->
  FlowRouter.watchPathChange()
  variant = FlowRouter.getParam '_variant' 
  return undefined unless variant?
  courseName = FlowRouter.getParam '_courseName'
  return ExerciseSets.findOne({variant, courseName})

getCurrentExercises = () ->
  FlowRouter.watchPathChange()
  exerciseSet = getCurrentExerciseSet()
  return undefined unless exerciseSet?
  targetLecture = FlowRouter.getParam '_lecture' 
  targetUnit = FlowRouter.getParam '_unit'
  ex = []
  for lecture in exerciseSet.lectures
    if (not targetLecture?) or (lecture.name is targetLecture)
      for unit in lecture.units
        if (not targetUnit?) or (unit.name is targetUnit)
          for e in unit.rawExercises
            ex.push ix.convertToExerciseId(e)
  return ex

getLectureNamesOfCurrentExerciseSet = () ->
  FlowRouter.watchPathChange()
  exerciseSet = getCurrentExerciseSet()
  return undefined unless exerciseSet?
  return ({name:l.name, url:"/myTuteesProgress/course/#{exerciseSet.courseName}/exerciseSet/#{exerciseSet.variant}/lecture/#{l.name}"} for l in exerciseSet.lectures)
      
getUnitNamesOfCurrentLecture = () ->
  FlowRouter.watchPathChange()
  exerciseSet = getCurrentExerciseSet()
  return undefined unless exerciseSet?
  targetLecture = FlowRouter.getParam '_lecture' 
  return undefined unless targetLecture?
  for lecture in exerciseSet.lectures
    if lecture.name is targetLecture
      return ({name:u.name, url:"/myTuteesProgress/course/#{exerciseSet.courseName}/exerciseSet/#{exerciseSet.variant}/lecture/#{lecture.name}/unit/#{u.name}"} for u in lecture.units)
  # No match found (error in URL)
  return undefined

getNumberSubmitted = (dataCtx, sinceDate) -> 
  FlowRouter.watchPathChange()
  dataCtx ?= this
  if dataCtx._id?
    # Restrict the query to SubmittedExercises owned by a particular tutee.
    q = {owner:dataCtx._id}
  else
    q = {}
  if sinceDate?
    q.created = {$gte:sinceDate}
  if isPageForParticularExercises()
    ex = getCurrentExercises() or []
    q.exerciseId = {$in:ex}
  return SubmittedExercises.find(q).count()

DAYSAGO7 = moment().subtract(7, "days").toDate()

getNumberSubmitted7Days = (dataCtx) ->
  dataCtx ?= this
  getNumberSubmitted(dataCtx, DAYSAGO7)  
  
getPercent = (value, total) -> Math.floor((value / total) * 100) or 0

_getQuery = (dataCtx) ->
  # Restrict the query to SubmittedExercises owned by a particular tutee.
  q = {}
  if dataCtx?._id?
    q.owner = dataCtx._id
  if isPageForParticularExercises()
    ex = getCurrentExercises() or []
    q.exerciseId = {$in:ex}
  return q
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
  paramsSpecifyExerciseSet : () -> FlowRouter.getParam('_variant' )?
  exerciseSetName : () -> "the #{FlowRouter.getParam('_variant' )} exercises for #{FlowRouter.getParam('_courseName' )}"
  paramsSpecifyLecture : () -> FlowRouter.getParam('_lecture' )?
  lectureName :  () -> FlowRouter.getParam('_lecture' )
  paramsSpecifyUnit : () -> FlowRouter.getParam('_unit' )?
  unitName : () -> FlowRouter.getParam('_unit' )
  lectureNamesOfCurrentExerciseSet : getLectureNamesOfCurrentExerciseSet
  unitNamesOfCurrentLecture : getUnitNamesOfCurrentLecture
  allSubscriptionsUniqueExerciseSets : () -> 
    ss = Subscriptions.find().fetch()
    # Make sure we only have one subscription per exercise set (crude method)/
    alreadyGot = []
    result = []
    for sub in ss
      key = "#{sub.courseName}/#{sub.variant}"
      result.push(sub) unless key in alreadyGot
      alreadyGot.push(key)
    console.log result
    return result
  nofTutees : () -> _getTutees().count()
  'tutees' : _getTutees
  'email' : () ->
    return @emails?[0]?.address

  meanNumberSubmitted : () ->
    # We assume that all `SubmittedExercises` currently available are from tutees.
    q = _getQuery()
    return Math.floor(SubmittedExercises.find(q).count() / _getTutees().count())
  meanNumberSubmitted7days : () ->
    q = _getQuery()
    q = _onlyLast7Days(q)
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
  
  # This is only here for the side-effects
  drawProgressCharts : () ->
    FlowRouter.watchPathChange()
    drawProgressChart 'progressChart'
    drawProgressChart 'progressChart7days', _onlyLast7Days
    return ''
    
    
Template.myTuteesProgress.events
  # TODO: this is not ideal but I can’t find a better way
  'click .collapsible' : (event, template) -> 
    if not template.doneInitCollapsible?
      $('.collapsible').collapsible()
      template.doneInitCollapsible = true
      $(event.target).click()
  'click #showChart' : (event, template) ->
    drawProgressChart 'progressChart'
    drawProgressChart 'progressChart7days', _onlyLast7Days

drawProgressChart = (chartElemId, daysQueryWrapper) ->
  console.log 'drawProgressChart'
  daysQueryWrapper ?= (a) -> a
  drawChart = () ->
    tutees = _getTutees()
    dataArray = [ ['Status', 'Correct', 'Incorrect', 'Ungraded', { role: 'annotation' } ] ]
    for t in tutees.fetch()
      row = [t.profile.name]
      for fn in [_onlyCorrect, _onlyIncorrect, _onlyUngraded]
        q = daysQueryWrapper(fn(t))
        num = SubmittedExercises.find(q).count() 
        row.push( num )
      row.push ''
      dataArray.push(row)
    data = google.visualization.arrayToDataTable dataArray
    options = {
      width: 600,
      height: 400,
      legend: { position: 'top', maxLines: 3 },
      bar: { groupWidth: '75%' },
      isStacked: true,
    }
    # Instantiate and draw our chart, passing in some options.
    chart = new google.visualization.BarChart(document.getElementById(chartElemId))
    chart.draw(data, options)
  google.load('visualization', '1.0', {'packages':['corechart'], callback: drawChart})