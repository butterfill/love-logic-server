Template.next_exercise.onCreated () ->
  # self is `Template.instance()`
  self = this
  self.autorun () ->
    FlowRouter.watchPathChange()
    courseName = FlowRouter.getQueryParam 'courseName'
    variant = FlowRouter.getQueryParam 'variant'
    if courseName? And variant?
      self.subscribe 'exercise_set', courseName, variant

Template.next_exercise.helpers
  isNextExercise : () ->
    FlowRouter.watchPathChange()
    ctx = ix.getExerciseContext()
    return ctx?.nextExercise?

Template.next_exercise.events
  'click .next-exercise' : (event, template) ->
    ctx = ix.getExerciseContext()
    if not ctx?.nextExercise?
      # You have reached the end
      ctx = ix.getExerciseContext()
      courseName = ctx?.exerciseSet?.courseName or ''
      variant = ctx?.exerciseSet?.variant or ''
      MaterializeModal.alert
        title: "The End",
        message: "You have reached the end of the #{variant} exercises for #{courseName}."
    qs = ix.queryString()
    if qs
      queryString = "?#{qs}"
      queryString = queryString.replace(/unitName=[^&]+/, "unitName=#{ctx.nextUnit.name}")
      queryString = queryString.replace(/lectureName=[^&]+/, "lectureName=#{ctx.nextLecture.name}")
    else
      queryString = ""
    nextUrl = ctx.nextExercise
    nextUrl = ix.convertToExerciseId(nextUrl)
    # Check we aren't grading (in which case we need to add `/grade` to the nextUrl)
    url = ix.url()
    if url.match /\/grade\/?/
      nextUrl = nextUrl.replace /\/$/, ''
      nextUrl += '/grade'
    FlowRouter.go("#{nextUrl}#{queryString}")
    
    


