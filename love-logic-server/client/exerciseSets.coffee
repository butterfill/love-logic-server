DAYSAGO7 = moment().subtract(7, "days").toDate()

beReactive = () ->
  return true if (window.location.pathname.indexOf('/edit') isnt -1)
  return false if (window.location.pathname.indexOf('/exerciseSet') isnt -1)
  return true if ix.isInstructorOrTutor()
getExerciseSetName = () ->
  return decodeURIComponent(FlowRouter.getParam('_variant') or '')
nameIsOkToUseAsURIComponent = (name) ->
  return false if name.indexOf(':') isnt -1
  return false if name.indexOf('/') isnt -1
  return false if name.indexOf('?') isnt -1
  return true



Template.courses.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('courses')


Template.courses.helpers
  courses : () -> 
    return Courses.find({}, {reactive:beReactive()})
  isInstructorOrTutor : ix.isInstructorOrTutor

Template.courses.events
  'click .createNewCourse' : (event, target) ->
    MaterializeModal.form
      title : "Create New Course"
      bodyTemplate : "createNewCourseModal"
      submitLabel : "create"
      closeLabel : "cancel"
      callback : (error, response) ->
        if response.submit 
          name = response?.form?.name?.trim?()
          description = response?.form?.description?.trim?()
          unless name? and description? and name isnt '' and description isnt ''
            Materialize.toast "Error: specify name and description", 4000
            return
          unless nameIsOkToUseAsURIComponent(name)
            Materialize.toast "Error: illegal characters in name", 4000
            return
          Meteor.call 'createNewCourse', name, description, (error, result)->
            if not error
              name = result.name
              Materialize.toast "Created #{name}", 4000
              FlowRouter.go("/course/#{name}")
            else
              Materialize.toast "Sorry, there was an error creating #{name}. (#{error.message})", 4000


Template.exerciseSetsForCourse.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    self.subscribe('course', courseName)
    self.subscribe('exercise_sets', courseName)

getCourse = () ->
  courseName = FlowRouter.getParam('_courseName')
  return Courses.findOne({name:courseName},{reactive:beReactive()})
  
Template.exerciseSetsForCourse.helpers
  courseName : () -> FlowRouter.getParam('_courseName')
  courseDescription : () ->
    return getCourse()?.description
  exerciseSets : () -> 
    courseName = FlowRouter.getParam('_courseName')
    return ExerciseSets.find({courseName:courseName}, {reactive:beReactive()})
  isInstructorOrTutor : ix.isInstructorOrTutor
  canDeleteCourse : () ->
    courseName = FlowRouter.getParam('_courseName')
    countExSets = ExerciseSets.find({courseName:courseName}, {reactive:beReactive()}).count()
    return countExSets is 0
  clipboardHasExerciseSet : () ->
    return (ix.clipboard.get('exerciseSet') isnt undefined)
  

Template.exerciseSetsForCourse.events
  'click .deleteCourse' : (event, target) ->
    courseName = FlowRouter.getParam('_courseName')
    Meteor.call 'deleteCourse', courseName, (error,result) ->
      if not error
        Materialize.toast "Deleted #{courseName}", 4000
        FlowRouter.go('/courses')
      else
        Materialize.toast "Sorry, there was an error deleting #{courseName}. (#{error.message})", 4000
      
  'click .createNewExerciseSet' : (event, target) ->
    MaterializeModal.form
      title : "Create New Exercise Set"
      bodyTemplate : "createNewExerciseSetModal"
      submitLabel : "create"
      closeLabel : "cancel"
      callback : (error, response) ->
        if response.submit
          variant = response?.form?.variant?.trim?()
          description = response?.form?.description?.trim?()
          unless variant? and description? and variant isnt '' and description isnt ''
            Materialize.toast "Error: specify name and description", 4000
            return
          unless nameIsOkToUseAsURIComponent(variant)
            Materialize.toast "Error: illegal characters in name", 4000
            return
          courseName = FlowRouter.getParam('_courseName')
          return unless courseName?
          Meteor.call 'createNewExerciseSet', courseName, variant, description, (error,result)->
            if not error
              Materialize.toast "Created #{variant}", 4000
              FlowRouter.go("/course/#{courseName}/exerciseSet/#{variant}/edit")
            else
              Materialize.toast "Sorry, there was an error creating #{variant}. (#{error.message})", 4000
          
  'click .pasteExerciseSet' : (event, target) ->
    newExSet = ix.clipboard.get('exerciseSet')
    unless newExSet?
      Materialize.toast "Sorry, there is no exercise set on the clipboard", 4000
      return
    courseName = FlowRouter.getParam('_courseName')
    newExSet = _.clone(newExSet)
    delete newExSet._id
    newExSet.owner = Meteor.userId()
    newExSet.courseName = courseName
    exSets = ExerciseSets.find({courseName:courseName}).fetch()
    existingNames = (e.variant for e in exSets)
    name = newExSet.variant
    num = 0
    while name in existingNames
      num += 1
      name = "#{newExSet.variant}-#{num}"
    newExSet.variant = name
    Meteor.call 'pasteExerciseSet', newExSet, (error,result)->
      if not error
        Materialize.toast "Pasted #{newExSet.variant}", 4000
        FlowRouter.go("/course/#{courseName}/exerciseSet/#{newExSet.variant}/edit")
      else
        Materialize.toast "Sorry, there was an error creating #{newExSet.variant}. (#{error.message})", 4000


Template.listExercises.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    variant = FlowRouter.getParam('_variant')
    self.subscribe('course', courseName)
    self.exerciseSet = self.subscribe 'exercise_set', courseName, variant


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
    self.exerciseSet = self.subscribe('exercise_set', courseName, variant)



# ====
# Helpers and event handlers common to exerciseSet and exerciseSetEdit
 
commonHelpers = 
  paramsSpecifyExerciseSet : () -> FlowRouter.getParam('_variant' )?
  paramsSpecifyLecture : () -> FlowRouter.getParam('_lecture' )?
  lectureName :  () -> FlowRouter.getParam('_lecture' )
  paramsSpecifyUnit : () -> FlowRouter.getParam('_unit' )?
  unitName : () -> FlowRouter.getParam('_unit' )
  isTutor : ix.userIsTutor
  isInstructorOrTutor : ix.isInstructorOrTutor
  
  # These are copied from `myTuteesProgress.coffee`
  courseName : () -> FlowRouter.getParam('_courseName')
  courseDescription : () ->
    return Courses.findOne({},{reactive:beReactive()})?.description
  exerciseSetName : () ->
    return getExerciseSetName()
  exerciseSetDescription : () ->
    return ix.getExerciseSet({reactive:beReactive()})?.description
    
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
  
  exerciseSetExists : () -> ix.getExerciseSet()?
  
  isEditing : () -> window.location.pathname.indexOf('/edit') isnt -1
  clipboardHasLecture : () ->
    return (ix.clipboard.get('lecture') isnt undefined)
  clipboardHasUnit : () ->
    return (ix.clipboard.get('unit') isnt undefined)
  canDeleteExerciseSet : () ->
    exerciseSet = ix.getExerciseSet()
    return exerciseSet?.lectures?.length is 0
  
Template.listExercises.helpers commonHelpers
Template.exerciseSet.helpers commonHelpers
Template.exerciseSetInner.helpers commonHelpers
Template.exerciseSetEdit.helpers commonHelpers
Template.exerciseSetEditInner.helpers commonHelpers
Template.deleteCopyPasteButtons.helpers commonHelpers



commonEventHandlers = 
  'click .copyExerciseSet' : (event, target) ->
    exerciseSet = ix.getExerciseSet()
    ix.clipboard.set(exerciseSet, 'exerciseSet')
    Materialize.toast "Exercise set ‘#{exerciseSet.variant}’ copied to clipboard", 4000
  'click .copyLecture' : (event, target) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @idx
    lecture = exerciseSet.lectures[lectureIdx]
    ix.clipboard.set(lecture, 'lecture')
    Materialize.toast "‘#{lecture.name}’ copied to clipboard", 4000
  'click .copyUnit' : (event, target) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @idx
    console.log exerciseSet
    console.log "#{lectureIdx} #{unitIdx}"
    unit = exerciseSet.lectures[lectureIdx].units[unitIdx]
    ix.clipboard.set(unit, 'unit')
    Materialize.toast "‘#{unit.name}’ copied to clipboard", 4000

Template.exerciseSet.events commonEventHandlers
Template.exerciseSetEdit.events commonEventHandlers



# ====
# listExercises

# merely displays the questions (no progress or anything)
Template.listExercises.helpers
  displayQuestion : () ->
    return "#{@type}_ex_display_question"

  lectures : () ->
    return getLectures()



# ====
# exerciseSet

Template.exerciseSet.helpers
  exerciseSetReady : () -> Template.instance().exerciseSet.ready() and Template.instance().datesExercisesSubmitted.ready()

Template.exerciseSetInner.helpers
  isForTutee : () -> Meteor.users.find().count() > 1
  
  userIsExerciseSetOwner : () ->
    exerciseSet = ix.getExerciseSet()
    return exerciseSet?.owner is ix.getUserId()
  
  # NB: has side-effect: draws the chart
  lectures : () ->
    FlowRouter.watchPathChange()
    theLectures = getLectures()
    
    # Keys are exId; values are the correctness of the latest submission
    exDict = {}
    allExIncludingResubmits = SubmittedExercises.find({owner:ix.getUserId()},{reactive:beReactive()}).fetch()
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
    courseName = FlowRouter.getParam('_courseName')
    variant = getExerciseSetName()
    return false unless userId? and courseName? and variant?
    test = Subscriptions.findOne({$and:[{owner:userId},{courseName},{variant}]},{reactive:beReactive()})
    return test?



Template.exerciseSetEdit.helpers
  exerciseSetReady : () -> Template.instance().exerciseSet.ready() 
  
  
Template.exerciseSetEditInner.helpers
  dialectNameForExerciseSet : () -> ix.getExerciseSet()?.dialectName
  textbook : () -> ix.getExerciseSet()?.textbook
  lectures : () -> 
    theLectures = getLectures({reactive:beReactive()})
    return theLectures 


# -------------
# Events


Template.exerciseSet.events
  'click #follow' : (event, template) ->
    courseName = FlowRouter.getParam('_courseName')
    variant = getExerciseSetName()
    Meteor.call 'subscribeToExerciseSet', courseName, variant, (error,result) ->
      if not error
        Materialize.toast "You are following #{variant}", 4000
      else
        Materialize.toast "Sorry, there was an error signing you up for #{variant}. (#{error.message})", 4000
  
  'click #unfollow' : (event, template) ->
    courseName = FlowRouter.getParam('_courseName')
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


Template.exerciseSetEdit.events
  'click .pasteUnit' : (event, target) ->
    newUnit = ix.clipboard.get('unit')
    unless newUnit?
      Materialize.toast "Sorry, there is no unit on the clipboard", 4000
      return
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @idx
    lecture = exerciseSet.lectures[lectureIdx]
    units = lecture.units or []
    existingUnitNames = (u.name for u in units)
    name = newUnit.name
    num = 0
    while name in existingUnitNames
      num += 1
      name = "#{newUnit.name} #{num}"
    newUnit.name = name
    toSet = {"lectures.#{lectureIdx}.units.#{units.length}":newUnit}
    updateExerciseSetField exerciseSet, toSet, "pasting ‘#{newUnit.name}’ at the end of the list"
  'click .pasteLecture' : (event, target) ->
    newLecture = ix.clipboard.get('lecture')
    unless newLecture?
      Materialize.toast "Sorry, there is no lecture on the clipboard", 4000
      return
    exerciseSet = ix.getExerciseSet()
    lectures = exerciseSet.lectures or []
    existingLectureNames = (l.name for l in lectures)
    name = newLecture.name
    num = 0
    while name in existingLectureNames
      num += 1
      name = "#{newLecture.name} #{num}"
    newLecture.name = name
    toSet = {"lectures.#{lectures.length}":newLecture}
    updateExerciseSetField exerciseSet, toSet, "pasting ‘#{newLecture.name}’ at the end of the list"
    
  'click .deleteExerciseSet' : (event, target) ->
    courseName = FlowRouter.getParam('_courseName')
    variant = getExerciseSetName()
    Meteor.call 'deleteExerciseSet', courseName, variant, (error,result) ->
      if not error
        Materialize.toast "Deleted #{variant}", 4000
        console.log "/course/#{courseName}"
        FlowRouter.go("/course/#{courseName}")
      else
        Materialize.toast "Sorry, there was an error deleting #{variant}. (#{error.message})", 4000
      
  # editing contentEditable fields
  # NB: currently this messes up because Subscriptions 
  # specify variant by name!
  'blur .exerciseSetName' : (event, template) ->
    # check it has no followers, otherwise deny update.
    exerciseSet = ix.getExerciseSet()
    updateHasFailed = (msg) ->
      event.target.innerText = exerciseSet.variant
      Materialize.toast msg, 4000
    newName = event.target.innerText?.trim()
    unless newName?.length > 0 and nameIsOkToUseAsURIComponent(newName)
      updateHasFailed('Name contains invalid characters.')
      return
    Meteor.call 'exerciseSetHasFollowers', exerciseSet.courseName, exerciseSet.variant, (error, result) ->
      if error
        updateHasFailed("Sorry, there was an error checking followers. (#{error.message})")
      else
        console.log result
        unless result is false
          updateHasFailed("Sorry, cannot change name because this exercise set already has followers.")
        else
          toSet = {"variant":newName}
          updateExerciseSetField exerciseSet, toSet, 'updating the name of the exercise set'
          # changing name changes url:
          FlowRouter.go ix.url().replace(/\/[^\/]*\/edit$/,"/#{newName}/edit")
  'blur .exerciseSetDescription' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    newName = event.target.innerText?.trim()
    unless newName?.length > 0
      event.target.innerText = exerciseSet.description
      return
    toSet = {"description":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the description of the exercise set'
  'blur .textbook' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    newName = event.target.innerText?.trim()
    if newName?.length is 0
      toSet = {"textbook":null}
    else
      toSet = {"textbook":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the textbook for this exercise set'
  'blur .unitName' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx
    unitIdx = @idx
    newName = event.target.innerText?.trim()
    unless newName?.length > 0 and nameIsOkToUseAsURIComponent(newName)
      event.target.innerText = exerciseSet.lectures[lectureIdx].units[unitIdx].name
      return
    toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.name":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the name of the unit'
    # changing name changes url:
    FlowRouter.go ix.url().replace(/\/[^\/]*$/,"/#{newName}")
  'blur .lectureName' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @idx
    newName = event.target.innerText?.trim()
    unless newName?.length > 0 and nameIsOkToUseAsURIComponent(newName)
      event.target.innerText = exerciseSet.lectures[lectureIdx].name
      return
    toSet = {"lectures.#{lectureIdx}.name":newName}
    updateExerciseSetField exerciseSet, toSet, 'updating the name of the lecture'
    # changing name changes url:
    FlowRouter.go ix.url().replace(/\/[^\/]*$/,"/#{newName}")
  
  # moving things up and down
  'click .moveExerciseDown' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
    return undefined unless exerciseSet?
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
    exerciseSet = ix.getExerciseSet()
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
    exerciseSet = ix.getExerciseSet()
    lectures = exerciseSet.lectures
    lectureIdx = @idx
    lecture = lectures[lectureIdx]
    deleteLecture = () ->
      lectures.splice(lectureIdx,1)
      toSet = {"lectures":lectures}
      updateExerciseSetField exerciseSet, toSet, 'deleting the lecture'
    units = lectures[lectureIdx].units
    if units?.length is 0
      # no units; delete without asking
      deleteLecture()
      return
    MaterializeModal.confirm
      title: "Delete Lecture"
      message: "Do you want to delete the <em>#{lecture.name}</em>? This cannot be undone."
      submitLabel : "delete"
      callback: (error, result) ->
        if result?.submit
          deleteLecture()
  'click .deleteUnit' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
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
      message: "Do you want to delete the unit <em>#{unit.name}</em>? This cannot be undone."
      submitLabel : "delete"
      callback: (error, result) ->
        if result?.submit
          deleteUnit()

  'click .editSlides' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx
    if @lectureIdx?
      # This is for a unit
      lecture = exerciseSet.lectures[lectureIdx]
      unitIdx = @idx
      unit = lecture.units[unitIdx]
      slides = unit.slides
      message = "Specify the url of the slides for <em>#{unit.name}</em>."
      toSetField = "lectures.#{lectureIdx}.units.#{unitIdx}.slides"
    else
      # This is for a lecture
      lectureIdx = @idx
      lecture = exerciseSet.lectures[lectureIdx]
      slides = lecture.slides
      message = "Specify the url of the slides for <em>#{lecture.name}</em>."
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
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx
    if @lectureIdx?
      # This is for a unit
      lecture = exerciseSet.lectures[lectureIdx]
      unitIdx = @idx
      unit = lecture.units[unitIdx]
      handout = unit.handout
      message = "Specify the url of the handout for <em>#{unit.name}</em>."
      toSetField = "lectures.#{lectureIdx}.units.#{unitIdx}.handout"
    else
      # This is for a lecture
      lectureIdx = @idx
      lecture = exerciseSet.lectures[lectureIdx]
      handout = lecture.handout
      message = "Specify the url of the slides for <em>#{lecture.name}</em>."
      toSetField = "lectures.#{lectureIdx}.handout"
    MaterializeModal.form
      title : "Handout"
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
          
  'click .addExerciseUsingExerciseBuilder' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx 
    lecture = exerciseSet.lectures[lectureIdx]
    unitIdx = @idx
    unit = lecture.units[unitIdx]
    # We are going to send this to the `exerciseBuilder` template
    # It will carry the data we need back here
    result = {}
    MaterializeModal.form
      title : "Add Exercise"
      bodyTemplate : "exerciseBuilder"
      footerTemplate : "exerciseBuilderFooter"
      # fullscreen : true
      fixedFooter: true
      result : result
      callback : (error, response) ->
        if result.exerciseURI
          exercise = parseExercise(result.exerciseURI)
          rawExercises = unit.rawExercises or []
          rawExercises.push exercise
          toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises" : rawExercises}
          updateExerciseSetField exerciseSet, toSet, 'adding the exercise'

  # 'click .addExercise' : (event, template) ->
  #   exerciseSet = ix.getExerciseSet()
  #   lectureIdx = @lectureIdx
  #   lecture = exerciseSet.lectures[lectureIdx]
  #   unitIdx = @idx
  #   unit = lecture.units[unitIdx]
  #   MaterializeModal.form
  #     title : "Add Exercise"
  #     bodyTemplate : "exerciseModal"
  #     submitLabel : "create"
  #     closeLabel : "cancel"
  #     exercise : ''
  #     callback : (error, response) ->
  #       if response.submit
  #         exercise = response.form.exercise
  #         exercise = parseExercise(exercise)
  #         rawExercises = unit.rawExercises or []
  #         rawExercises.push exercise
  #         toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises" : rawExercises}
  #         updateExerciseSetField exerciseSet, toSet, 'adding the exercise'
  #
  # 'click .editExercise' : (event, template) ->
  #   exerciseSet = ix.getExerciseSet()
  #   lectureIdx = @lectureIdx
  #   lecture = exerciseSet.lectures[lectureIdx]
  #   unitIdx = @unitIdx
  #   unit = lecture.units[unitIdx]
  #   exerciseIdx = @idx
  #   exercise = unit.rawExercises[exerciseIdx]
  #   exerciseText = exercise.replace(/^\/ex\//,'')
  #   MaterializeModal.form
  #     title : "Edit Exercise"
  #     bodyTemplate : "exerciseModal"
  #     submitLabel : "update"
  #     closeLabel : "cancel"
  #     exercise : exerciseText
  #     callback : (error, response) ->
  #       if response.submit
  #         newExerciseText = response.form.exercise?.trim?() or ''
  #         if newExerciseText isnt ''
  #           newExerciseText = parseExercise(newExerciseText)
  #           toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises.#{exerciseIdx}" : newExerciseText}
  #           actionMsg = 'updating the exercise'
  #         else
  #           # user entered blank string : delete exercise
  #           rawExercises = unit.rawExercises
  #           rawExercises.splice(exerciseIdx,1)
  #           toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises" : rawExercises}
  #           actionMsg = 'deleting the exercise'
  #         updateExerciseSetField exerciseSet, toSet, actionMsg

  'click .editExerciseUsingExerciseBuilder' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx 
    lecture = exerciseSet.lectures[lectureIdx]
    unitIdx = @unitIdx
    unit = lecture.units[unitIdx]
    exerciseIdx = @idx
    exercise = unit.rawExercises[exerciseIdx]
    exerciseText = exercise.replace(/^\/ex\//,'')
    result = {}
    MaterializeModal.form
      title : "Edit Exercise"
      bodyTemplate : "exerciseBuilder"
      footerTemplate : "exerciseBuilderFooter"
      # fullscreen : true
      fixedFooter: true
      exerciseText : exerciseText
      result : result
      callback : (error, response) ->
        if result.exerciseURI
          newExerciseText = parseExercise(result.exerciseURI)
          toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises.#{exerciseIdx}" : newExerciseText}
          updateExerciseSetField exerciseSet, toSet, 'updating the exercise'
        else if result.deleteExercise is true
          rawExercises = unit.rawExercises
          rawExercises.splice(exerciseIdx, 1)
          toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.rawExercises" : rawExercises}
          updateExerciseSetField exerciseSet, toSet, 'deleting the exercise'

  'click .editDialectUnit' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    lectureIdx = @lectureIdx 
    lecture = exerciseSet.lectures[lectureIdx]
    unitIdx = @idx
    unit = lecture.units[unitIdx]
    dialectName = unit.dialectName or ''
    MaterializeModal.form
      title : "Set Dialect for Unit"
      bodyTemplate : "setDialectModal"
      submitLabel : "update"
      closeLabel : "cancel"
      dialectName : dialectName
      message : "Specify a dialect to use for just this unit."
      postMessage : "<em>(Set a dialect for the whole exercise set from the top page of the exercise set.)</em>"
      callback : (error, response) ->
        if response.submit
          newDialectName = response.form.dialectName
          # Check the name is correct:
          allDialectNamesAndDescriptions = fol.getAllDialectNamesAndDescriptions()
          allNames = (x.name for x in allDialectNamesAndDescriptions)
          unless newDialectName in allNames
            Materialize.toast "No dialect called ‘#{newDialectName}’ exists.", 4000
            return
          toSet = {"lectures.#{lectureIdx}.units.#{unitIdx}.dialectName" : newDialectName}
          updateExerciseSetField exerciseSet, toSet, 'updating the dialect for the unit'
          fol.setDialect(newDialectName)
    
  'click .editDialectExerciseSet' : (event, template) ->
    exerciseSet = ix.getExerciseSet()
    dialectName = exerciseSet.dialectName or ''
    MaterializeModal.form
      title : "Set Dialect"
      bodyTemplate : "setDialectModal"
      submitLabel : "update"
      closeLabel : "cancel"
      dialectName : dialectName
      message : "Specify a dialect to use for this exercise set."
      postMessage : "<em>(You can set different dialects for individual units.)</em>"
      callback : (error, response) ->
        if response.submit
          newDialectName = response.form.dialectName
          # Check the name is correct:
          allDialectNamesAndDescriptions = fol.getAllDialectNamesAndDescriptions()
          allNames = (x.name for x in allDialectNamesAndDescriptions)
          unless newDialectName in allNames
            Materialize.toast "No dialect called ‘#{newDialectName}’ exists.", 4000
            return
          toSet = {"dialectName" : newDialectName}
          updateExerciseSetField exerciseSet, toSet, 'updating the dialect for the exercise set'
          fol.setDialect(newDialectName)
          if exerciseSet.textbook? is false or exerciseSet.textbook is ''
            textbook = fol.getTextbookForDialect(newDialectName)
            updateExerciseSetField exerciseSet, {textbook}, 'updating the textbook for the exercise set'
            
    
    
parseExercise = (ex) ->
  ex = ex.trim()
  # add `/ex/` at the start
  unless ex.match /^\/ex\//
    if ex.startsWith('/')
      ex = "/ex#{ex}" 
    else
      ex = "/ex/#{ex}"
  return ex


# Build an object useful for
# displaying and edit ExerciseSets
# (essentially: elaborate them by adding properties).
getLectures = (options) ->
  options ?= {reactive:beReactive()}
  exerciseSet = ix.getExerciseSet(options)
  theLectures = exerciseSet?.lectures
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
          exerciseId : e
          link : ix.convertToExerciseId(e)
          name : e.replace(/^\/ex\//,'')
          type : e.split('/')[2]
          isFirst : eidx is 0
          isLast : eidx is unit.rawExercises.length-1
        exercises.push exDoc
      unit.exercises = exercises
      unit.reading = ix.getReading(exerciseSet, unit)
      # if unit.rawReading?.length >0
      #   unit.reading = "Sections §#{unit.rawReading.join(', §')} of Language, Proof and Logic (Barwise & Etchemendy; the course textbook)."
      # else
      #   unit.reading =""
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
    el = document.getElementById(chartElemId)
    if el?
      chart = new google.visualization.PieChart(el)
      chart.draw(data, options)
  google.load('visualization', '1.0', {'packages':['corechart'], callback: drawChart})    



Template.setDialectModal.onRendered () ->
  allDialectNamesAndDescriptions = fol.getAllDialectNamesAndDescriptions()
  $('.dialectName.typeahead').typeahead({
    hint : true
    minLength : 0
    highlight : true
    limit : 10
  },{
    name : 'dialectNames'
    async : false
    limit : 10
    display : (o) -> o.name
    source : (query, syncResults) ->
      queryWords = query.toLowerCase().split(/\s+/)
      maxScore = 0
      for d in allDialectNamesAndDescriptions
        d.score = 0
        for qw in queryWords
          d.score += 1 if d.description.toLowerCase().indexOf(qw) isnt -1
          d.score += 1 if d.name.toLowerCase().indexOf(qw) isnt -1
        if d.score > maxScore
          maxScore = d.score
      res = []
      if maxScore isnt 0
        res = (d for d in allDialectNamesAndDescriptions when d.score is maxScore)
      fewerWordsFirstSorter = (a,b) ->
        aWords = a.description.split(' ').length
        bWords = b.description.split(' ').length
        return aWords - bWords
      res.sort( fewerWordsFirstSorter )
      syncResults( res )
    templates : 
      empty : [
          '<div class="empty-message">',
            'unable to find any dialects matching the current query',
          '</div>'
        ].join('\n')
      suggestion : (o) ->
        return "<div><strong>#{o.name}</strong> - #{o.description}<div>"
  })

