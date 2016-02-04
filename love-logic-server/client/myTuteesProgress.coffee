
Template.myTuteesProgress.onCreated () ->
  templateInstance = this
  templateInstance.stats = new ReactiveVar()
  tutorId = FlowRouter.getQueryParam('tutor') 
  templateInstance.autorun () ->
    if tutorId
      templateInstance.subscribe 'tutors_for_instructor', tutorId
    
    # For the following, `tutorId` can be undefined
    tuteesSub = templateInstance.subscribe 'tutees', tutorId
    progressSub = templateInstance.subscribe 'tutees_progress', tutorId
    templateInstance.subscribe 'tutees_subscriptions', tutorId
    
    FlowRouter.watchPathChange()
    variant = FlowRouter.getParam '_variant' 
    if variant?
      courseName = FlowRouter.getParam '_courseName'
      exSub = templateInstance.subscribe 'exercise_set', courseName, variant
      if exSub.ready() and progressSub.ready() and tuteesSub.ready()
        ex = getCurrentExercises()
        templateInstance.stats.set( getAllStats(DAYSAGO7, ex) )
    else
      if progressSub.ready() and tuteesSub.ready()
        templateInstance.stats.set( getAllStats(DAYSAGO7) )
      
    

isPageForParticularExercises = () ->
  FlowRouter.watchPathChange()
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

getAllStats = (sinceDate, exercises) ->
  start = performance.now()
  
  q = {}
  
  # restrict to certain exercises
  if exercises?
    q.exerciseId = {$in:exercises}
  
  # restrict to tutees of the tutor
  tutees = _getTutees().fetch()
  tuteeIds = (x._id for x in tutees)
  # Actually we won’t do that by querying - we’ll filter the others out below.
  # q.owner = {$in:tuteeIds}
  
  allSubmittedExercises = SubmittedExercises.find(q).fetch()
  console.log "stats query took #{performance.now() - start} ms"
  
  stats = {}
  
  addKey = (key) ->
    if not stats[key]?
      stats[key] = { 
        allTime : {num:0, correct:0, correctEx:[], incorrect:0, incorrectEx:[], ungraded:0, ungradedEx:[]}
        recent : {num:0, correct:0, correctEx:[], incorrect:0, incorrectEx:[], ungraded:0, ungradedEx:[]}
      }
  
  updateKey = (key, isCorrect, isIncorrect, isUngraded, isSinceDate, exerciseId) ->
    addKey(key)
    toUpdate = [stats[key].allTime]
    toUpdate.push(stats[key].recent) if isSinceDate
    for object in toUpdate
      object.num += 1
      if isCorrect
        object.correct += 1 
        object.correctEx.push(exerciseId)
      if isIncorrect
        object.incorrect +=1 
        object.incorrectEx.push(exerciseId)
      if isUngraded
        object.ungraded +=1 
        object.ungradedEx.push(exerciseId)

  for se in allSubmittedExercises

    # ignore any SubmittedExercise not done by one of the tutees under consideration here
    if not se.owner of tuteeIds
      continue
      
    isCorrect = se.humanFeedback?.isCorrect is true or se.machineFeedback?.isCorrect is true
    isIncorrect = se.humanFeedback?.isCorrect is false or se.machineFeedback?.isCorrect is false
    # isUngraded = (not se.humanFeedback?.isCorrect?) or (not se.machineFeedback?.isCorrect?)
    isUngraded = (not isCorrect) and (not isIncorrect)
    isSinceDate = se.created >= sinceDate
    updateKey('all', isCorrect, isIncorrect, isUngraded, isSinceDate, se.exerciseId)
    updateKey(se.owner, isCorrect, isIncorrect, isUngraded, isSinceDate, se.exerciseId)
  
  # This is the number of students who have submitted at least one exercise.
  stats.numStudents = Object.keys(stats).length - 1
  
  console.log "stats all took #{performance.now() - start} ms"
  
  return stats



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
    key = dataCtx._id
  else
    key = 'all'
    
  stats = Template.instance().stats?.get()
  return 0 unless stats?[key]?
  
  if sinceDate?
    # assume it’s always the same date
    return stats[key].recent.num
    
  return stats[key].allTime.num
  
  
DAYSAGO7 = moment().subtract(7, "days").toDate()

getNumberSubmitted7Days = (dataCtx) ->
  dataCtx ?= this
  getNumberSubmitted(dataCtx, DAYSAGO7)  
  
getPercent = (value, total) -> Math.floor((value / total) * 100) or 0
  
_getTutees = () ->
  tutorId = FlowRouter.getQueryParam('tutor')
  if tutorId?
    tutorEmail = Meteor.users.findOne(tutorId)?.emails?[0]?.address
  else
    tutorEmail = Meteor.user()?.emails?[0]?.address
  return Meteor.users.find({'profile.seminar_tutor':tutorEmail})
  
Template.myTuteesProgress.helpers
  urlQueryPart : () -> window.location.search
  forSelf : () -> FlowRouter.getQueryParam('tutor') is undefined
  tutorName : () ->
    tutorId = FlowRouter.getQueryParam('tutor')
    return Meteor.users.findOne(tutorId)?.profile?.name
  
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
    # console.log result
    return result
  nofTutees : () -> _getTutees().count()
  'tutees' : _getTutees
  'email' : () ->
    return @emails?[0]?.address

  meanNumberSubmitted : () ->
    # We assume that all `SubmittedExercises` currently available are from tutees.
    stats = Template.instance().stats?.get()
    return 0 unless stats?.all?
    return Math.floor( stats.all.allTime.num / stats.numStudents )
  meanNumberSubmitted7days : () ->
    stats = Template.instance().stats?.get()
    return 0 unless stats?.all?
    return Math.floor( stats.all.recent.num / stats.numStudents )
    
  
  # These are called where the data context is a tutee (`Meteor.user`)
  'number_submitted' : getNumberSubmitted
  'number_submitted_7days' : getNumberSubmitted7Days
  # The following are called both for the overall figures (at the top  of the page)
  # and for the individual tutees.  When called with individual tutees, @ will be
  # the user record for the tutee; when called for the overall figures, @_id? will be false.
  'percentCorrect' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return 0 unless stats?[key]?
    numCorrect = stats[key].allTime.correct
    numSubmitted = stats[key].allTime.num
    return getPercent(numCorrect, numSubmitted)
  'percentCorrect7Days' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return 0 unless stats?[key]?
    numCorrect = stats[key].recent.correct
    numSubmitted = stats[key].recent.num
    return getPercent(numCorrect, numSubmitted)
  'percentIncorrect' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return 0 unless stats?[key]?
    numCorrect = stats[key].allTime.incorrect
    numSubmitted = stats[key].allTime.num
    return getPercent(numCorrect, numSubmitted)
  'percentIncorrect7Days' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return 0 unless stats?[key]?
    numCorrect = stats[key].recent.incorrect
    numSubmitted = stats[key].recent.num
    return getPercent(numCorrect, numSubmitted)
  'percentUngraded' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return 0 unless stats?[key]?
    numCorrect = stats[key].allTime.ungraded
    numSubmitted = stats[key].allTime.num
    return getPercent(numCorrect, numSubmitted)
  'percentUngraded7Days' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return 0 unless stats?[key]?
    numCorrect = stats[key].recent.ungraded
    numSubmitted = stats[key].recent.num
    return getPercent(numCorrect, numSubmitted)
    
    
  'correct7Days' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return stats?[key]?.recent.correctEx
  'incorrect7Days' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return stats?[key]?.recent.incorrectEx
  'ungraded7Days' : () -> 
    key = @?._id or 'all'
    stats = Template.instance().stats?.get()
    return stats?[key]?.recent.ungradedEx
  
  'subscriptions' : () -> Subscriptions.find({owner:@_id})
  
  # These are called where the data context is a `Subscription`.
  # Used to pass to the `display_subscription` template
  'userQueryParam' :() -> "user=#{@owner}"
  
  # These are called when the data context is an exerciseId<String>
  gradeURL : () ->
    tutee=Template.parentData()
    (@.replace(/\/$/, ''))+"/grade?user=#{tutee._id}"
  exerciseLink : () -> decodeURIComponent(@)
  
  # This is only here for the side-effects
  drawProgressCharts : () ->
    FlowRouter.watchPathChange()
    drawProgressChart 'progressChart'
    drawProgressChart 'progressChart7days', true
    return ''
    
    
Template.myTuteesProgress.events
  # TODO: this is not ideal but I can’t find a better way
  'click .collapsible' : (event, template) -> 
    if not template.doneInitCollapsible?
      $('.collapsible').collapsible()
      template.doneInitCollapsible = true
      $(event.target).click()

drawProgressChart = (chartElemId, showRecent) ->
  stats = Template.instance().stats?.get()
  return unless stats?
  drawChart = () ->
    tutees = _getTutees()
    dataArray = [ ['Status', 'Correct', 'Incorrect', 'Ungraded', { role: 'annotation' } ] ]
    for t in tutees.fetch()
      row = [t.profile.name]
      if showRecent
        nums = stats[t._id]?.recent or {correct:0, incorrect:0, ungraded:0}
      else
        nums = stats[t._id]?.allTime or {correct:0, incorrect:0, ungraded:0}
      row.push( nums.correct )
      row.push( nums.incorrect )
      row.push( nums.ungraded )
      row.push ''
      dataArray.push(row)
    data = google.visualization.arrayToDataTable dataArray
    options = 
      width: 600
      height: 400 + (10 * (stats.numStudents))
      legend: { position: 'top', maxLines: 3 }
      bar: { groupWidth: '75%' }
      isStacked: true
    # Instantiate and draw our chart, passing in some options.
    chart = new google.visualization.BarChart(document.getElementById(chartElemId))
    chart.draw(data, options)
  google.load('visualization', '1.0', {'packages':['corechart'], callback: drawChart})