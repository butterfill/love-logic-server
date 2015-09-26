
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
    self.subscribe('submitted_exercises')
    self.subscribe('subscriptions')


isSubmitted = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  return ( SubmittedExercises.find({exerciseId}).count() > 0 )
dateSubmitted = (exerciseLink) ->
  exerciseId = ix.convertToExerciseId(exerciseLink)
  return SubmittedExercises.findOne({exerciseId}, {sort:{created:-1}}).created

Template.exerciseSet.helpers
  courseName : () ->
    return getCourseName() 
  courseDescription : () ->
    return Courses.findOne()?.description
  exerciseSetName : () ->
    return getExerciseSetName()
  exerciseSetDescription : () ->
    return ExerciseSets.findOne()?.description
  lectures : () ->
    theLectures = ExerciseSets.findOne()?.lectures
    return [] if not theLectures
    for l in theLectures
      for unit in l.units
        unit.exercises = (
          {
            name:e
            link:ix.convertToExerciseId(e)
            isSubmitted:isSubmitted(e)
            dateSubmitted:(moment(dateSubmitted(e)).fromNow() if isSubmitted(e))
          } for e in unit.rawExercises
        )
        if unit.rawReading?.length >0
          unit.reading = "Sections §#{unit.rawReading.join(', §')} of Language, Proof and Logic (Barwise & Etchemendy; the course textbook)."
        else 
          unit.reading =""
    return theLectures
  isAlreadyFollowing : () ->
    userId = ix.getUserId()
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
    Meteor.call('subscribeToExerciseSet', courseName, variant, (error,result)->
      if not error
        Materialize.toast "You are following #{variant}", 4000
      else
        Materialize.toast "Sorry, there was an error signing you up for #{variant}. (#{error.message})", 4000
    )

