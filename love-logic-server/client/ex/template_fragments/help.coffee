getExerciseSet = (options) ->
  FlowRouter.watchPathChange()
  options ?= {}
  courseName = FlowRouter.getQueryParam 'courseName'
  variant = FlowRouter.getQueryParam 'variant'
  return ExerciseSets.findOne({courseName, variant}, options)

doSubscriptions = (templateInstance) ->
  templateInstance ?= this
  templateInstance.autorun () ->
    courseName = FlowRouter.getQueryParam 'courseName'
    variant = FlowRouter.getQueryParam 'variant'
    templateInstance.subscribe 'exercise_set', courseName, variant

  # Tell the templates to update when the current unit changes by
  # creating a reactive var which they can observe.
  templateInstance.exerciseContext = new ReactiveVar()
  templateInstance.autorun () ->
    FlowRouter.watchPathChange()
    ctx = ix.getExerciseContext()
    templateInstance.exerciseContext.set(ctx)

Template.help_with_this_exercise.onCreated doSubscriptions
Template.topic_header.onCreated doSubscriptions
Template.ask_for_help.onCreated () ->
  templateInstance = this
  doSubscriptions(templateInstance)
  templateInstance.autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    templateInstance.subscribe 'help_request', exerciseId, onReady : () ->
      requesterId = Meteor.userId()
      unseenHelpRequestAnswers = HelpRequest.find({exerciseId, requesterId, answer:{$exists:true}, studentSeen:{$exists:false} })
      for helpReq in unseenHelpRequestAnswers.fetch()
        Meteor.call "studentSeenHelpRequestAnswer", helpReq
      


# ====
# template helpers

      
slidesForThisUnit = () ->
  # Because `Session` is a reactive var, this call ensures the templates are updated when
  # the current unit changes.
  ctx = Template.instance().exerciseContext.get()
  return '' unless ctx
  return ctx.unit.slides
readingForThisUnit = () ->
  exerciseSet = getExerciseSet()
  ctx = Template.instance().exerciseContext.get()
  unit = ctx?.unit
  return '' unless exerciseSet? and unit?
  return ix.getReading(exerciseSet, unit)
slidesOrReadingForThisUnit = () ->
  slides = slidesForThisUnit()
  return true if slides? and slides isnt ''
  reading = readingForThisUnit()
  return true if reading? and reading isnt ''
  return false
  
unitTitle = () ->
  ctx = Template.instance().exerciseContext.get()
  return '' unless ctx
  return ctx.unit.name

notYetSubmitted = () ->
  exerciseId = ix.getExerciseId()
  owner = Meteor.userId()
  SubmittedExercises.find({exerciseId, owner}).count() is 0

Template.help_with_this_exercise.helpers
  slidesForThisUnit : slidesForThisUnit
  readingForThisUnit : readingForThisUnit
  slidesOrReadingForThisUnit : slidesOrReadingForThisUnit
  unitTitle : unitTitle

Template.ask_for_help.helpers
  slidesForThisUnit : slidesForThisUnit
  readingForThisUnit : readingForThisUnit
  unitTitle : unitTitle
  notYetSubmitted : notYetSubmitted 
  helpRequests : () ->
    exerciseId = ix.getExerciseId()
    requesterId = Meteor.userId()
    return HelpRequest.find({exerciseId, requesterId}, {sort:{'created':-1}})
  # This is called when a particluar `HelpRequest` is the data context
  helpRequestDate : () -> moment(@created).fromNow()
  isHelpRequestAnswered : () -> @answer?
  helpAnswerDate : () -> moment(@dateAnswered).fromNow()

Template.topic_header.helpers
  unitTitle : unitTitle
  courseName : () ->
    ctx = Template.instance().exerciseContext.get()
    return '' unless ctx
    return ctx.exerciseSet.courseName
  variant : () ->
    ctx = Template.instance().exerciseContext.get()
    return ctx?.exerciseSet?.variant or ''

Template.requestHelpModal.helpers


# ====
# template events

Template.ask_for_help.events
  'click #request-help' : (event, template) ->
    if notYetSubmitted()
      Materialize.toast "Please submit your answer (even if blank) before requesting help.", 4000
      return
    MaterializeModal.form
      title : "Ask for help"
      bodyTemplate : "requestHelpModal"
      submitLabel : "send"
      closeLabel : "cancel"
      slidesForThisUnit : slidesForThisUnit()
      readingForThisUnit : readingForThisUnit()
      unitTitle : unitTitle()
      callback : (error, response) ->
        if response.submit
          requestHelp(response.form)

  'click .showCorrectAnswer' : (event, template) ->
    q = 
      exerciseId : ix.getExerciseId()
      owner : Meteor.userId()
    hasSubmitted = SubmittedExercises.find(q,{limit:1}).count() > 0
    unless hasSubmitted
      Materialize.toast "First submit your answer.", 4000
      return
    Meteor.call 'getCorrectAnswer', ix.getExerciseId(), (error, response) ->
      if error
        Materialize.toast "Sorry, there was an error. [#{error.message}]", 4000
        return
      unless response?
        Materialize.toast "Sorry, could not find a correct answer.", 4000
        return
      console.log response
      url = ix.url()
      type = url.split('/')[2]
      displayAnswer = "#{type}_ex_display_answer"
      Tracker.autorun () ->
        MaterializeModal.message
          title : "Here is a correct answer"
          bodyTemplate : displayAnswer
          answer : response.answer
          # displayAnswer : displayAnswer
          # submitLabel : "send"
          # closeLabel : "cancel"
    

requestHelp = (data) ->
  owner = Meteor.userId()
  exerciseId = ix.getExerciseId()
  submittedExerciseId = SubmittedExercises.findOne({owner, exerciseId}, {sort:{'created':-1}})._id
  doc = 
    exerciseId : exerciseId
    submittedExerciseId : submittedExerciseId
    reviewedLectureSlides : data.reviewedLectureSlides
    readTextbook : data.readTextbook
    question : data.description?.trim() or ''
  if doc.question is ''
    return undefined
  Meteor.call "createHelpRequest", doc, (error) ->
    if error
      Materialize.toast error.message, 4000
    else
      Materialize.toast "Your request for help has been recorded.", 4000
    
  
    