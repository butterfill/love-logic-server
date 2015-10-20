
# -------------

getExerciseSetName = () ->
  return decodeURIComponent(FlowRouter.getParam('_variant') or '')
getCourseName = () ->
  return Courses.findOne()?.name

Template.courses.onCreated () ->
  self = this
  self.autorun () ->
    self.subscribe('courses')


Template.courses.helpers
  courses : () -> 
    return Courses.find()


Template.exerciseSetsForCourse.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    self.subscribe('course', courseName)
    self.subscribe('exercise_sets', courseName)


Template.exerciseSetsForCourse.helpers
  courseName : () ->
    return Courses.findOne()?.name
  courseDescription : () ->
    return Courses.findOne()?.description
  exerciseSets : () -> 
    return ExerciseSets.find()


Template.exerciseSet.onCreated () ->
  self = this
  self.autorun () ->
    courseName = FlowRouter.getParam('_courseName')
    variant = FlowRouter.getParam('_variant')
    self.subscribe('course', courseName)
    self.subscribe('exercise_set', courseName, variant)
    # This subscription provides all `SubmittedExercises` for the user but only some fields.
    userId = ix.getUserId()
    self.subscribe('dates_exercises_submitted', userId)
    self.subscribe('tutee_user_info', userId)
    if userId is Meteor.userId()
      # This is only used to check whether the user wants to follow or stop following
      # an exercise set.
      self.subscribe('subscriptions')


isSubmitted = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  return ( SubmittedExercises.find({exerciseId}).count() > 0 )
dateSubmitted = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  return SubmittedExercises.findOne({exerciseId}, {sort:{created:-1}}).created

exerciseIsCorrect = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  ex = SubmittedExercises.findOne({exerciseId}, {sort:{created:-1}})
  return true if ex?.humanFeedback?.isCorrect
  return true if ex?.machineFeedback?.isCorrect
  return false
exerciseIsIncorrect = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  ex = SubmittedExercises.findOne({exerciseId}, {sort:{created:-1}})
  return true if ex?.humanFeedback?.isCorrect is false
  return true if ex?.machineFeedback?.isCorrect is false
  return false
exerciseIsUngraded = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  ex = SubmittedExercises.findOne({exerciseId}, {sort:{created:-1}})
  return false unless ex?.created?
  return false if ex?.humanFeedback?.isCorrect?
  return false if ex?.machineFeedback?.isCorrect?
  return true
  
Template.exerciseSet.helpers
  courseName : () ->
    return getCourseName() 
  courseDescription : () ->
    return Courses.findOne()?.description
  exerciseSetName : () ->
    return getExerciseSetName()
  exerciseSetDescription : () ->
    return ExerciseSets.findOne()?.description
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
  lectures : () ->
    FlowRouter.watchPathChange()
    theLectures = ExerciseSets.findOne()?.lectures
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
    for l in theLectures
      l.htmlAnchor = encodeURIComponent(l.name)
      l.exerciseSetLectureURL = ''
      if ix.url().indexOf('/unit/') is -1 and ix.url().indexOf('/lecture/') is -1
          l.exerciseSetLectureURL = "#{ix.url().replace(/\/$/,'')}/lecture/#{l.name}#{document.location.search}"
      if ix.url().indexOf('/unit/') isnt -1
        # move up from unit to lecture
        l.exerciseSetLectureURL = ix.url().replace(/\/unit\/.+/, '')
      for unit in l.units
        unit.htmlAnchor = encodeURIComponent(unit.name)
        unit.exerciseSetUnitURL = ''
        if ix.url().indexOf('/unit/') is -1
          if ix.url().indexOf('/lecture/') is -1
            unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'')}/lecture/#{l.name}/unit/#{unit.name}#{document.location.search}"
          else
            unit.exerciseSetUnitURL = "#{ix.url().replace(/\/$/,'')}/unit/#{unit.name}#{document.location.search}"
        unit.exercises = (
          {
            name:e.replace('/ex/','')
            link:ix.convertToExerciseId(e)
            isSubmitted:isSubmitted(e)
            dateSubmitted:(moment(dateSubmitted(e)).fromNow() if isSubmitted(e))
            exerciseIsCorrect : exerciseIsCorrect(e)
            exerciseIsIncorrect : exerciseIsIncorrect(e)
            exerciseIsUngraded : exerciseIsUngraded(e)
          } for e in unit.rawExercises
        )
        if unit.rawReading?.length >0
          unit.reading = "Sections §#{unit.rawReading.join(', §')} of Language, Proof and Logic (Barwise & Etchemendy; the course textbook)."
        else 
          unit.reading =""
    return theLectures
    
  stats : () ->
    theLectures = ExerciseSets.findOne()?.lectures
    return {} if not theLectures
    
    # Filter the document if a particular lecture or unit is specified
    if FlowRouter.getParam('_lecture')?
      lectureToShow = FlowRouter.getParam('_lecture')
      theLectures = (l for l in theLectures when l.name is lectureToShow)
    if FlowRouter.getParam('_unit')? 
      unitToShow = FlowRouter.getParam('_unit')
      for lecture in theLectures
        lecture.units = (u for u in lecture.units when u.name is unitToShow)
    
    stats = 
      nofExercises: 0
      submitted: 0
      correct: 0
      incorrect: 0
      ungraded: 0 
    for l in theLectures
      for unit in l.units
        for e in unit.rawExercises
          stats.nofExercises += 1
          stats.submitted += 1 if isSubmitted(e)
          stats.correct += 1 if exerciseIsCorrect(e)
          stats.incorrect += 1 if exerciseIsIncorrect(e)
          stats.ungraded += 1 if exerciseIsUngraded(e)
    return stats
    
  'gradeURL' : () -> (@link.replace(/\/$/, ''))+"/grade"
  isAlreadyFollowing : () ->
    # Here we get the acutal user (this is for wheter to display the `follow button`)
    userId = Meteor.userId()
    courseName = getCourseName()
    variant = getExerciseSetName()
    return false unless userId? and courseName? and variant?
    test = Subscriptions.findOne({$and:[{owner:userId},{courseName},{variant}]})
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
    
    

