
doSubscriptions = () ->
  templateInstance = this
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
Template.ask_for_help.onCreated doSubscriptions
Template.topic_header.onCreated doSubscriptions


Template.ask_for_help.onRendered () ->
  $("#request-help").leanModal()


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
