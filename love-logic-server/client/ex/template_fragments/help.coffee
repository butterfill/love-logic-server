
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
    exerciseId = ix.getExerciseId()
    templateInstance.subscribe 'help_request', exerciseId


Template.ask_for_help.onRendered () ->
  $("#request-help").leanModal()


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

Template.help_with_this_exercise.helpers
  slidesForThisUnit : slidesForThisUnit
  readingForThisUnit : readingForThisUnit
  unitTitle : unitTitle

Template.ask_for_help.helpers
  slidesForThisUnit : slidesForThisUnit
  readingForThisUnit : readingForThisUnit
  unitTitle : unitTitle

Template.topic_header.helpers
  unitTitle : unitTitle
  courseName : () ->
    ctx = Template.instance().exerciseContext.get()
    return '' unless ctx
    return ctx.exerciseSet.courseName
  variant : () ->
    ctx = Template.instance().exerciseContext.get()
    return '' unless ctx
    return ctx.exerciseSet.variant


# ====
# template events

Template.ask_for_help.events
  'click #confirm-request-help' : (event, template) ->
    doc = {
      exerciseId : ix.getExerciseId()
      reviewedLectureSlides : $('#reviewed-lecture-slides').is(':checked')
      readTextbook : $('#read-textbook').is(':checked')
      question : $('#request-for-help-description').val().trim()
    }
    delete doc.readTextbook if $('#read-textbook').length is 0
    delete doc.reviewedLectureSlides if $('#reviewed-lecture-slides').length is 0
    if doc.question is ''
      return undefined
    Meteor.call "createHelpRequest", doc, (error) ->
      if error
        Materialize.toast error.message, 4000
      else
        Materialize.toast "Your request for help has been recorded.", 4000
      
    
      