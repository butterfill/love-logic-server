
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
  ctx = Template.instance().exerciseContext.get()
  return '' unless ctx
  return "Sections §#{ctx.unit.rawReading.join(', §')} of Language, Proof and Logic"
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
    
  
    