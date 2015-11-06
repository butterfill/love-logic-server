
# -------------

getExerciseSetName = () ->
  return decodeURIComponent(FlowRouter.getParam('_variant') or '')
getCourseName = () ->
  return Courses.findOne({},{reactive:false})?.name

Template.courses.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('courses')


Template.courses.helpers
  courses : () -> 
    return Courses.find({}, {reactive:false})


Template.exerciseSetsForCourse.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    self.subscribe('course', courseName)
    self.subscribe('exercise_sets', courseName)


Template.exerciseSetsForCourse.helpers
  courseName : () ->
    return Courses.findOne({},{reactive:false})?.name
  courseDescription : () ->
    return Courses.findOne({},{reactive:false})?.description
  exerciseSets : () -> 
    return ExerciseSets.find({}, {reactive:false})


Template.exerciseSet.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    variant = FlowRouter.getParam('_variant')
    self.subscribe('course', courseName)
    self.exerciseSet = self.subscribe('exercise_set', courseName, variant)
    
    # The `dates_exercises_submitted` subscription provides all `SubmittedExercises` 
    # for the user but only some fields.
    userId = ix.getUserId()
    self.datesExercisesSubmitted = self.subscribe('dates_exercises_submitted', userId)
    
    self.subscribe('tutee_user_info', userId)
    if userId is Meteor.userId()
      # This is only used to check whether the user wants to follow or stop following
      # an exercise set.
      self.subscribe('subscriptions')

  
Template.exerciseSet.helpers
  # These are copied from `myTuteesProgress.coffee`
  paramsSpecifyExerciseSet : () -> FlowRouter.getParam('_variant' )?
  exerciseSetName : () -> "the #{FlowRouter.getParam('_variant' )} exercises for #{FlowRouter.getParam('_courseName' )}"
  paramsSpecifyLecture : () -> FlowRouter.getParam('_lecture' )?
  lectureName :  () -> FlowRouter.getParam('_lecture' )
  paramsSpecifyUnit : () -> FlowRouter.getParam('_unit' )?
  unitName : () -> FlowRouter.getParam('_unit' )

  courseName : () ->
    return getCourseName() 
  courseDescription : () ->
    return Courses.findOne({},{reactive:false})?.description
  exerciseSetName : () ->
    return getExerciseSetName()
  exerciseSetDescription : () ->
    return ExerciseSets.findOne({},{reactive:false})?.description
  isForTutee : () -> Meteor.users.find().count() > 1
  tuteeId : () -> 
    tuteeId = ix.getUserId()
    return Meteor.users.findOne(ix.getUserId())._id
  tuteeName : () -> 
    tuteeId = ix.getUserId()
    return Meteor.users.findOne(ix.getUserId())?.profile?.name
  tuteeEmail : () -> 
    tuteeId = ix.getUserId()
    return Meteor.users.findOne(ix.getUserId())?.emails?[0]?.address
  submittedDateAndCorrectnessInfoReady : () -> Template.instance().datesExercisesSubmitted.ready()
  exerciseSetReady : () -> Template.instance().exerciseSet.ready() and Template.instance().datesExercisesSubmitted.ready()
  lectures : () ->
    FlowRouter.watchPathChange()
    theLectures = ExerciseSets.findOne({},{reactive:false})?.lectures
    return [] if not theLectures
    
    # Filter the document if a particular lecture or unit is specified
    if FlowRouter.getParam('_lecture')?
      lectureToShow = FlowRouter.getParam('_lecture')
      theLectures = (l for l in theLectures when l.name is lectureToShow)
    if FlowRouter.getParam('_unit')? 
      unitToShow = FlowRouter.getParam('_unit')
      for lecture in theLectures
        lecture.units = (u for u in lecture.units when u.name is unitToShow)
    
    # Build an object that makes blaze templating easier
    exDict = {}
    for l in theLectures
      l.htmlAnchor = encodeURIComponent(l.name)
      l.exerciseSetLectureURL = ''
      if ix.url().indexOf('/unit/') is -1 and ix.url().indexOf('/lecture/') is -1
          l.exerciseSetLectureURL = "#{ix.url().replace(/\/$/,'')}/lecture/#{l.name}#{document.location.search}"
      if ix.url().indexOf('/unit/') isnt -1
        # move up from unit to lecture
        l.exerciseSetLectureURL = "#{ix.url().replace(/\/unit\/.+/, '')}#{document.location.search}"
      for unit in l.units
        unit.htmlAnchor = encodeURIComponent(unit.name)
        unit.exerciseSetUnitURL = ''
        if ix.url().indexOf('/unit/') is -1
          if ix.url().indexOf('/lecture/') is -1
            unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'')}/lecture/#{l.name}/unit/#{unit.name}#{document.location.search}"
          else
            unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'')}/unit/#{unit.name}#{document.location.search}"
        exercises = []
        for e in unit.rawExercises
          exDoc = 
            name:e.replace('/ex/','')
            link:ix.convertToExerciseId(e)
            isSubmitted:false
          exercises.push exDoc
          exDict[exDoc.link] = exDoc
        unit.exercises = exercises
        if unit.rawReading?.length >0
          unit.reading = "Sections §#{unit.rawReading.join(', §')} of Language, Proof and Logic (Barwise & Etchemendy; the course textbook)."
        else 
          unit.reading =""
    
    # Now fill in details of exercises
    exLinks = _.keys exDict
    allExIncludingResubmits = SubmittedExercises.find({exerciseId:{$in:exLinks}},{reactive:false}).fetch()
    exDup = {}  # used to keep track of multiple submissions for one exercise
    allEx = allExIncludingResubmits
    for ex in allEx
      if ex.exerciseId of exDup
        oldEx = exDup[ex.exerciseId]
        if ex.created < oldEx.created
          # Keep the newer exercise
          continue
      exDup[ex.exerciseId] = ex
      exDoc = exDict[ex.exerciseId]
      exDoc.isSubmitted = true
      exDoc.dateSubmitted = moment(ex.created).fromNow()
      exDoc.exerciseIsCorrect = ex.humanFeedback?.isCorrect or ex.machineFeedback?.isCorrect
      exDoc.exerciseIsIncorrect = ex.humanFeedback?.isCorrect is false or ex.machineFeedback?.isCorrect is false
      exDoc.exerciseIsUngraded = ex.humanFeedback?.isCorrect? is false and ex.machineFeedback?.isCorrect? is false
    return theLectures
    
  # NB: has side-effect: draws the chart
  stats : () ->
    theLectures = ExerciseSets.findOne({},{reactive:false})?.lectures
    return {} if not theLectures
    
    # Filter the document if a particular lecture or unit is specified
    if FlowRouter.getParam('_lecture')?
      lectureToShow = FlowRouter.getParam('_lecture')
      theLectures = (l for l in theLectures when l.name is lectureToShow)
    if FlowRouter.getParam('_unit')? 
      unitToShow = FlowRouter.getParam('_unit')
      for lecture in theLectures
        lecture.units = (u for u in lecture.units when u.name is unitToShow)
    
    exLinksToCheck = []
    for l in theLectures
      for unit in l.units
        for exLink in unit.rawExercises
          e = ix.convertToExerciseId(exLink)
          exLinksToCheck.push(e)
          
    allExIncludingResubmits = SubmittedExercises.find({exerciseId:{$in:exLinksToCheck}},{reactive:false}).fetch()
    exDup = {}  # used to keep track of multiple submissions for one exercise
    for ex in allExIncludingResubmits
      if ex not of exDup
        exDup[ex.exerciseId] = ex 
      else
        if exDup[ex.exerciseId].created > ex.created
          # Take the newest exercise
          exDup[ex.exerciseId] = ex 
    allEx = _.values exDup
    correctEx = (x.exerciseId for x in allEx when x.machineFeedback?.isCorrect or x.humanFeedback?.isCorrect) 
    incorrectEx = (x.exerciseId for x in allEx when x.machineFeedback?.isCorrect is false or x.humanFeedback?.isCorrect is false) 
    ungradedEx = (x.exerciseId for x in allEx when x.machineFeedback?.isCorrect? is false and x.humanFeedback?.isCorrect? is false) 
    submittedEx = (x.exerciseId for x in allEx)
    
    stats = 
      nofExercises: exLinksToCheck.length
      submitted: submittedEx.length
      correct: correctEx.length
      incorrect: incorrectEx.length
      ungraded: ungradedEx.length
    Meteor.defer () ->
      drawProgressDonut('progressChart', stats)
    return stats
    
  'gradeURL' : () -> (@link.replace(/\/$/, ''))+"/grade"
  isAlreadyFollowing : () ->
    # Here we get the acutal user (this is for wheter to display the `follow button`)
    userId = Meteor.userId()
    courseName = getCourseName()
    variant = getExerciseSetName()
    return false unless userId? and courseName? and variant?
    test = Subscriptions.findOne({$and:[{owner:userId},{courseName},{variant}]},{reactive:false})
    return test?

# -------------
# User interactions


Template.exerciseSet.events
  'click #follow' : (event, template) ->
    courseName = getCourseName()
    variant = getExerciseSetName()
    Meteor.call 'subscribeToExerciseSet', courseName, variant, (error,result)->
      if not error
        Materialize.toast "You are following #{variant}", 4000
      else
        Materialize.toast "Sorry, there was an error signing you up for #{variant}. (#{error.message})", 4000
  
  'click #unfollow' : (event, template) ->
    courseName = getCourseName()
    variant = getExerciseSetName()
    Meteor.call 'unsubscribeToExerciseSet', courseName, variant, (error,result)->
      if not error
        Materialize.toast "You are no longer following #{variant}", 4000
      else
        Materialize.toast "Sorry, there was an error signing you out of #{variant}. (#{error.message})", 4000
    
drawProgressDonut = (chartElemId, stats) ->
  drawChart = () ->
    dataArray = [ 
      ['Status', 'Number' ] 
      ['Correct', stats.correct]
      ['Incorrect', stats.incorrect]
      ['Ungraded', stats.ungraded]
      ['Not yet attempted', Math.max(0,stats.nofExercises - (stats.correct+stats.incorrect+stats.ungraded))]
    ]
    data = google.visualization.arrayToDataTable dataArray
    options = 
      width: 600
      height: 400
      pieHole: 0.4
      colors: ['green','red','orange','grey']
    # Instantiate and draw our chart, passing in some options.
    chart = new google.visualization.PieChart(document.getElementById(chartElemId))
    chart.draw(data, options)
  google.load('visualization', '1.0', {'packages':['corechart'], callback: drawChart})    

