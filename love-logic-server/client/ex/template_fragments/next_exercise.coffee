Template.next_exercise.onCreated () ->
  # self is `Template.instance()`
  self = this
  self.autorun () ->
    courseName = FlowRouter.getQueryParam 'courseName'
    variant = FlowRouter.getQueryParam 'variant'
    if courseName? And variant?
      self.subscribe 'exercise_set', courseName, variant

Template.next_exercise.helpers
  isNextExercise : () ->
    ctx = ix.getExerciseContext()
    return ctx?.next?
  # These are only used in the .modal telling the user they reached the end.
  courseName : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return ctx.exerciseSet.courseName
  variant : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return ctx.exerciseSet.variant

Template.next_exercise.events
  'click .next-exercise' : (event, template) ->
    ctx = ix.getExerciseContext()
    if not ctx?.next?
      $('#no_next_modal').openModal()
      return undefined
    qs = ix.queryString()
    if qs
      queryString = "?#{qs}"
    else
      queryString = ""
    nextUrl = ctx.next
    nextUrl = ix.convertToExerciseId(nextUrl)
    # Check we aren't grading (in which case we need to add `/grade` to the nextUrl)
    url = ix.url()
    if url.match /\/grade\/?/
      nextUrl = nextUrl.replace /\/$/, ''
      nextUrl += '/grade'
    FlowRouter.go("#{nextUrl}#{queryString}")
    
    


