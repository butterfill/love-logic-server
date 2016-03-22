DAYSAGO7 = moment().subtract(7, "days").toDate()

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


Template.listExercises.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    variant = FlowRouter.getParam('_variant')
    self.subscribe('course', courseName)
    self.exerciseSet = self.subscribe 'exercise_set', courseName, variant


getExerciseSet = (o) ->
  courseName = FlowRouter.getParam('_courseName')
  variant = FlowRouter.getParam('_variant')
  return ExerciseSets.findOne({courseName, variant},o)

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


Template.exerciseSetEdit.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    variant = FlowRouter.getParam('_variant')
    self.subscribe('course', courseName)
    self.exerciseSet = self.subscribe 'exercise_set', courseName, variant
    

# merely displays the questions (no progress or anything)
Template.listExercises.helpers
  courseName : () ->
    return getCourseName() 
  courseDescription : () ->
    return Courses.findOne({},{reactive:false})?.description
  displayQuestion : () ->
    return "#{@type}_ex_display_question"

  
  # TODO: this is mostly copied from its counterpart in Template.exerciseSet.helpers
  # minus the bits about a student’s progress
  lectures : () ->
    FlowRouter.watchPathChange()
    theLectures = getExerciseSet({reactive:false})?.lectures
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
          l.exerciseSetLectureURL = "#{ix.url().replace(/\/$/,'').replace(/\/listExercises/,'')}/lecture/#{l.name}/listExercises#{document.location.search}"
      if ix.url().indexOf('/unit/') isnt -1
        # move up from unit to lecture
        l.exerciseSetLectureURL = "#{ix.url().replace(/\/unit\/.+/, '').replace(/\/listExercises/,'')}/listExercises#{document.location.search}"
      for unit in l.units
        unit.htmlAnchor = encodeURIComponent(unit.name)
        unit.exerciseSetUnitURL = ''
        if ix.url().indexOf('/unit/') is -1
          if ix.url().indexOf('/lecture/') is -1
            unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'').replace(/\/listExercises/,'')}/lecture/#{l.name}/unit/#{unit.name}/listExercises#{document.location.search}"
          else
            unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'').replace(/\/listExercises/,'')}/unit/#{unit.name}/listExercises#{document.location.search}"
        exercises = []
        for e in unit.rawExercises
          exDoc = 
            exerciseId:e
            type:e.split('/')[2]
            name:e.replace('/ex/','')
            link:ix.convertToExerciseId(e)
          exercises.push exDoc
          exDict[exDoc.link] = exDoc
        unit.exercises = exercises
        if unit.rawReading?.length >0
          unit.reading = "Sections §#{unit.rawReading.join(', §')} of Language, Proof and Logic (Barwise & Etchemendy; the course textbook)."
        else 
          unit.reading =""
    
    return theLectures
 
commonHelpers = 
  paramsSpecifyExerciseSet : () -> FlowRouter.getParam('_variant' )?
  exerciseSetName : () -> "the #{FlowRouter.getParam('_variant' )} exercises for #{FlowRouter.getParam('_courseName' )}"
  paramsSpecifyLecture : () -> FlowRouter.getParam('_lecture' )?
  lectureName :  () -> FlowRouter.getParam('_lecture' )
  paramsSpecifyUnit : () -> FlowRouter.getParam('_unit' )?
  unitName : () -> FlowRouter.getParam('_unit' )
  isTutor : ix.userIsTutor
  
  # These are copied from `myTuteesProgress.coffee`
  courseName : () ->
    return getCourseName() 
  courseDescription : () ->
    return Courses.findOne({},{reactive:false})?.description
  exerciseSetName : () ->
    return getExerciseSetName()
  exerciseSetDescription : () ->
    return getExerciseSet({reactive:false})?.description
    
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
  
Template.exerciseSet.helpers commonHelpers
Template.exerciseSetEdit.helpers commonHelpers
  
Template.exerciseSet.helpers
  isForTutee : () -> Meteor.users.find().count() > 1
  exerciseSetReady : () -> Template.instance().exerciseSet.ready() and Template.instance().datesExercisesSubmitted.ready()
  
  userIsExerciseSetOwner : () ->
    exerciseSet = getExerciseSet()
    return exerciseSet.owner is ix.getUserId()
  
  # NB: has side-effect: draws the chart
  lectures : () ->
    FlowRouter.watchPathChange()
    
    theLectures = getLectures()
    
    # Keys are exId; values are the correctness of the latest submission
    exDict = {}
    allExIncludingResubmits = SubmittedExercises.find({owner:ix.getUserId()},{reactive:false}).fetch()
    exDup = {}  # used to keep track of multiple submissions for one exercise
    for ex in allExIncludingResubmits
      if ex.exerciseId of exDup
        oldEx = exDup[ex.exerciseId]
        if ex.created < oldEx.created
          # Keep the newer exercise
          continue
      exDup[ex.exerciseId] = ex
      exDoc = {}
      exDoc.isSubmitted = true
      exDoc.created = ex.created
      exDoc.dateSubmitted = moment(ex.created).fromNow()
      exDoc.exerciseIsCorrect = ex.humanFeedback?.isCorrect or ex.machineFeedback?.isCorrect
      exDoc.exerciseIsIncorrect = ex.humanFeedback?.isCorrect is false or ex.machineFeedback?.isCorrect is false
      exDoc.exerciseIsUngraded = ex.humanFeedback?.isCorrect? is false and ex.machineFeedback?.isCorrect? is false
      exDict[ex.exerciseId] = exDoc
  
    # Zip through theLectures and add correctness, date submitted etc to each exercise; also add some properties useful for templating.
    for l in theLectures
      progress = 
        correct : 0
        incorrect : 0
        ungraded : 0
        todo : 0
        total : 0
        lastNDays : 
          correct : 0
          incorrect : 0
          ungraded : 0
          total : 0
      l.progress = progress
      for unit in l.units
        progress.total += unit.rawExercises.length    
        for e in unit.exercises
          exDoc = exDict[e.link]
          if not exDoc?
            exDoc = 
              isSubmitted:false
          for own k,v of exDoc
            e[k] = v
          isSinceDate = exDoc.created >= DAYSAGO7
          if isSinceDate
            progress.lastNDays.total += 1
          if exDoc.exerciseIsCorrect
            progress.correct +=1 
            if isSinceDate
              progress.lastNDays.correct +=1 
          if exDoc.exerciseIsIncorrect
            progress.incorrect +=1 
            if isSinceDate
              progress.lastNDays.incorrect +=1 
          if exDoc.exerciseIsUngraded
            progress.ungraded +=1 
            if isSinceDate
              progress.lastNDays.ungraded +=1 
          if exDoc.isSubmitted is false
            progress.todo +=1 
            
    stats = 
      correct : 0
      incorrect : 0
      ungraded : 0
      nofExercises : 0
      lastNDays : 
        correct : 0
        incorrect : 0
        ungraded : 0
        total : 0
    theLectures.stats = stats
    for l in theLectures
      stats.correct += l.progress.correct
      stats.incorrect += l.progress.incorrect
      stats.ungraded += l.progress.ungraded
      stats.nofExercises += l.progress.total
      stats.lastNDays.correct += l.progress.lastNDays.correct
      stats.lastNDays.incorrect += l.progress.lastNDays.incorrect
      stats.lastNDays.ungraded += l.progress.lastNDays.ungraded
    stats.submitted = stats.correct + stats.incorrect + stats.ungraded
    stats.lastNDays.submitted = stats.lastNDays.correct + stats.lastNDays.incorrect + stats.lastNDays.ungraded
    
    # Draw chart (side-effect)
    Meteor.defer () ->
      drawProgressDonut('progressChart', stats)
    
    return theLectures

    
  'gradeURL' : () -> (@link.replace(/\/$/, ''))+"/grade"
  isAlreadyFollowing : () ->
    # Here we get the acutal user (this is for wheter to display the `follow button`)
    userId = Meteor.userId()
    courseName = getCourseName()
    variant = getExerciseSetName()
    return false unless userId? and courseName? and variant?
    test = Subscriptions.findOne({$and:[{owner:userId},{courseName},{variant}]},{reactive:false})
    return test?



Template.exerciseSetEdit.helpers
  exerciseSetReady : () -> Template.instance().exerciseSet.ready() 
  
  lectures : () -> 
    theLectures = getLectures({reactive:true})
    return theLectures 


# -------------
# Events


Template.exerciseSet.events
  'click #follow' : (event, template) ->
    courseName = getCourseName()
    variant = getExerciseSetName()
    Meteor.call 'subscribeToExerciseSet', courseName, variant, (error,result) ->
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


updateExerciseSetField = (exerciseSet, toSet, thing) ->
  Meteor.call 'updateExerciseSetField', exerciseSet, toSet, (error, result) ->
    if error
      Materialize.toast "Sorry, there was an error #{thing}", 4000
    else
      Materialize.toast "Success #{thing}", 4000

# TODO : delete these unless used!
dataContextIsExercise = (ctx) ->
  return ctx.unitIdx?
dataContextIsUnit = (ctx) ->
  return false if dataContextIsExercise(ctx)
  return ctx.lectureIdx?
dataContextIsLecture = (ctx) ->
  return false if dataContextIsExercise(ctx)
  return false if dataContextIsUnit(ctx)
  return true
  
Template.exerciseSetEdit.events

  # editing contentEditable fields
  # NB: currently this messes up because Subscriptions 
  # specify variant by name!
  'blur .exerciseSetName' : (event, template) ->
    # TODO : check it has no followers, otherwise deny update.
    exerciseSet = getExerciseSet()
    newName = event.target.innerText?.trim()
    unless newName?.length > 0
      event.target.innerText = exerciseSet.variant
      return
    toSet = {"variant":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the name of the exercise set'
    # changing name changes url:
    FlowRouter.go ix.url().replace(/\/[^\/]*\/edit$/,"/#{newName}/edit")
  'blur .exerciseSetDescription' : (event, template) ->
    exerciseSet = getExerciseSet()
    newName = event.target.innerText?.trim()
    unless newName?.length > 0
      event.target.innerText = exerciseSet.description
      return
    toSet = {"description":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the description of the exercise set'
  'blur .unitName' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @idx
    newName = event.target.innerText?.trim()
    unless newName?.length > 0
      event.target.innerText = exerciseSet.lectures[lectureIdx].units[unitIdx].name
      return
    toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.name":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the name of the unit'
    # changing name changes url:
    FlowRouter.go ix.url().replace(/\/[^\/]*$/,"/#{newName}")
  'blur .lectureName' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @idx
    newName = event.target.innerText?.trim()
    unless newName?.length > 0
      event.target.innerText = exerciseSet.lectures[lectureIdx].name
      return
    toSet = {"lectures.#{lectureIdx}.name":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the name of the lecture'
    # changing name changes url:
    FlowRouter.go ix.url().replace(/\/[^\/]*$/,"/#{newName}")
  
  # moving things up and down
  'click .moveExerciseDown' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @unitIdx
    exIdx = @idx
    exercises = exerciseSet.lectures[lectureIdx].units[unitIdx].rawExercises
    if exIdx >= exercises.length-1
      return
    ex = exercises[exIdx]
    nextEx = exercises[exIdx+1]
    toSet = 
      "lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises.#{exIdx}" : nextEx
      "lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises.#{exIdx+1}" : ex
    updateExerciseSetField exerciseSet, toSet, 'updating the order of the exercise'
  'click .moveExerciseUp' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @unitIdx
    exIdx = @idx
    exercises = exerciseSet.lectures[lectureIdx].units[unitIdx].rawExercises
    if exIdx < 1
      return
    ex = exercises[exIdx]
    prevEx = exercises[exIdx-1]
    toSet = 
      "lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises.#{exIdx}" : prevEx
      "lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises.#{exIdx-1}" : ex
    updateExerciseSetField exerciseSet, toSet, 'updating the order of the exercise'
  'click .moveLectureDown' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @idx
    lectures = exerciseSet.lectures
    if lectureIdx >= lectures.length-1
      return
    lecture = lectures[lectureIdx]
    nextLecture = lectures[lectureIdx+1]
    toSet = 
      "lectures.#{lectureIdx}" : nextLecture
      "lectures.#{lectureIdx+1}" : lecture
    updateExerciseSetField exerciseSet, toSet, 'updating the order of the lecture'
  'click .moveLectureUp' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @idx
    lectures = exerciseSet.lectures
    if lectureIdx < 1
      return
    lecture = lectures[lectureIdx]
    prevLecture = lectures[lectureIdx-1]
    toSet = 
      "lectures.#{lectureIdx}" : prevLecture
      "lectures.#{lectureIdx-1}" : lecture
    updateExerciseSetField exerciseSet, toSet, 'updating the order of the lecture'
  'click .moveUnitDown' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @idx
    units = exerciseSet.lectures[lectureIdx].units
    if unitIdx >= units.length-1
      return
    unit = units[unitIdx]
    nextUnit = units[unitIdx+1]
    toSet = 
      "lectures.#{lectureIdx}.units.#{unitIdx}" : nextUnit
      "lectures.#{lectureIdx}.units.#{unitIdx+1}" : unit
    updateExerciseSetField exerciseSet, toSet, 'updating the order of the unit'
  'click .moveUnitUp' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @idx
    units = exerciseSet.lectures[lectureIdx].units
    if unitIdx < 1
      return
    unit = units[unitIdx]
    prevUnit = units[unitIdx-1]
    toSet = 
      "lectures.#{lectureIdx}.units.#{unitIdx}" : prevUnit
      "lectures.#{lectureIdx}.units.#{unitIdx-1}" : unit
    updateExerciseSetField exerciseSet, toSet, 'updating the order of the unit'

  'click .addLecture' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectures = exerciseSet.lectures
    name = undefined
    
    # Try to follow an existing pattern in creating the name of the lecture
    if lectures? and lectures.length > 0
      lastLectureName = lectures[lectures.length-1].name
      m = lastLectureName.match /(.*?)(\d+)$/
      if m
        prefix = m[1]
        num = parseInt(m[2])
        name = "#{prefix}#{num+1}"
    unless name?
      existingLectureNames = (l.name for l in lectures)
      num = 0
      name = "New Lecture"
      while name in existingLectureNames
        num += 1
        name = "New Lecture #{num}"
    newLecture = {
      type : 'lecture'
      name : name
      units : []
    }
    toSet = {"lectures.#{lectures.length}":newLecture}
    updateExerciseSetField exerciseSet, toSet, 'creating a new lecture at the end of the list'
  'click .addUnit' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @idx
    lecture = exerciseSet.lectures[lectureIdx]
    units = lecture.units or []
    name = "New Unit"
    existingUnitNames = (u.name for u in units)
    num = 0
    while name in existingUnitNames
      num += 1
      name = "New Unit #{num}"
    newUnit = {
      type : 'unit'
      name : name
      rawReading : []
      rawExercises : []
    }
    toSet = {"lectures.#{lectureIdx}.units.#{units.length}":newUnit}
    updateExerciseSetField exerciseSet, toSet, 'creating a new unit at the end of the list'
    
  'click .deleteLecture' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectures = exerciseSet.lectures
    lectureIdx = @idx
    units = lectures[lectureIdx].units
    if units?.length > 0
      Materialize.toast "Sorry, cannot delete lecture because it has units (delete the units first)", 4000
      return
    lectures.splice(lectureIdx,1)
    toSet = {"lectures":lectures}
    updateExerciseSetField exerciseSet, toSet, 'deleting the lecture'
  'click .deleteUnit' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx
    units = exerciseSet.lectures[lectureIdx].units
    unitIdx = @idx
    unit = units[unitIdx]
    deleteUnit = () ->
      units.splice(unitIdx,1)
      toSet = {"lectures.#{lectureIdx}.units":units}
      updateExerciseSetField exerciseSet, toSet, 'deleting the unit'
    unless unit.rawExercises?.length > 0
      # no exercises; can delete immediately
      deleteUnit()
      return
    MaterializeModal.confirm
      title: "Delete Unit"
      message: "Do you want to delete the unit <em>#{unit.name}</em>?"
      callback: (error, result) ->
        if result?.submit
          deleteUnit()

  'click .editSlides' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx or @idx
    lecture = exerciseSet.lectures[lectureIdx]
    if @lectureIdx?
      # This is for a unit
      unitIdx = @idx
      unit = lecture.units[unitIdx]
      slides = unit.slides
      message = "Specify the url of the slides for <em>unit.name</em>."
      toSetField = "lectures.#{lectureIdx}.units.#{unitIdx}.slides"
    else
      slides = lecture.slides
      message = "Specify the url of the slides for <em>lecture.name</em>."
      toSetField = "lectures.#{lectureIdx}.slides"
    MaterializeModal.form
      title : "Slides"
      bodyTemplate : "urlModal"
      submitLabel : "update"
      closeLabel : "cancel"
      message : message
      url : slides
      callback : (error, response) ->
        if response.submit
          url = response.form.url
          toSet = {"#{toSetField}" : url}
          updateExerciseSetField exerciseSet, toSet, 'updating the url of the slides'
          
  'click .editHandout' : (event, template) ->
    exerciseSet = getExerciseSet()
    lectureIdx = @lectureIdx or @idx
    lecture = exerciseSet.lectures[lectureIdx]
    if @lectureIdx?
      # This is for a unit
      unitIdx = @idx
      unit = lecture.units[unitIdx]
      handout = unit.handout
      message = "Specify the url of the handout for <em>unit.name</em>."
      toSetField = "lectures.#{lectureIdx}.units.#{unitIdx}.handout"
    else
      handout = lecture.handout
      message = "Specify the url of the slides for <em>lecture.name</em>."
      toSetField = "lectures.#{lectureIdx}.handout"
    MaterializeModal.form
      title : "Slides"
      bodyTemplate : "urlModal"
      submitLabel : "update"
      closeLabel : "cancel"
      message : message
      url : handout
      callback : (error, response) ->
        if response.submit
          url = response.form.url
          toSet = {"#{toSetField}" : url}
          updateExerciseSetField exerciseSet, toSet, 'updating the url of the handout'
          
    
    

# Build an object useful for
# displaying and edit ExerciseSets
# (essentially: elaborate them by adding properties).
getLectures = (o) ->
  o ?= {reactive:false}
  theLectures = getExerciseSet(o)?.lectures
  return [] unless theLectures?.length > 0

  for l, idx in theLectures
    l.idx = idx
    l.isFirst = (idx is 0)
    l.isLast = (idx is theLectures.length-1)
    for u, uidx in l.units
      u.idx = uidx
      u.isFirst = (uidx is 0)
      u.isLast = (uidx is l.units.length-1)
      u.lectureIdx = idx
      
  # Filter the `theLectures` document if a particular lecture or unit is specified
  if FlowRouter.getParam('_lecture')?
    lectureToShow = FlowRouter.getParam('_lecture')
    theLectures = (l for l in theLectures when l.name is lectureToShow)
  if FlowRouter.getParam('_unit')? 
    unitToShow = FlowRouter.getParam('_unit')
    for lecture in theLectures
      lecture.units = (u for u in lecture.units when u.name is unitToShow)
  
  # Zip through theLectures and add correctness, date submitted etc to each exercise; also add some properties useful for templating.
  for l in theLectures
    l.htmlAnchor = encodeURIComponent(l.name)
    l.exerciseSetLectureURL = ''
    if ix.url().indexOf('/unit/') is -1 and ix.url().indexOf('/lecture/') is -1
        l.exerciseSetLectureURL = "#{ix.url().replace(/\/$/,'')}/lecture/#{l.name}#{document.location.search}"
    if ix.url().indexOf('/unit/') isnt -1
      # move up from unit to lecture
      l.exerciseSetLectureURL = "#{ix.url().replace(/\/unit\/.+/, '')}#{document.location.search}"
    # URL to take you to a list of questions for each lecture
    l.listExercisesURL = "#{ix.url().replace(/\/$/,'')}/listExercises#{document.location.search}"
    
    for unit in l.units
      unit.htmlAnchor = encodeURIComponent(unit.name)
      unit.exerciseSetUnitURL = ''
      if ix.url().indexOf('/unit/') is -1
        if ix.url().indexOf('/lecture/') is -1
          unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'')}/lecture/#{l.name}/unit/#{unit.name}#{document.location.search}"
        else
          unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'')}/unit/#{unit.name}#{document.location.search}"
      exercises = []
      for e, eidx in unit.rawExercises
        exDoc = 
          idx : eidx
          unitIdx : unit.idx
          lectureIdx : l.idx
          name : e.replace('/ex/','')
          link : ix.convertToExerciseId(e)
          isFirst : eidx is 0
          isLast : eidx is unit.rawExercises.length-1
        exercises.push exDoc
      unit.exercises = exercises
      if unit.rawReading?.length >0
        unit.reading = "Sections §#{unit.rawReading.join(', §')} of Language, Proof and Logic (Barwise & Etchemendy; the course textbook)."
      else 
        unit.reading =""
  return theLectures
      
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

