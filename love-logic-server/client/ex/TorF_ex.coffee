
Template.TorF_ex.onCreated () ->
  self = this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

Template.TorF_ex.onRendered () ->
  templateInstance = this
  # Allow the answer to be updated by setting the session variable
  @autorun () ->
    # We need to `watchPathChange` so that the answer also gets updated when we change page.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer() 
    if savedAnswer?.length? and savedAnswer?.length > 0
      arrayToRadio(savedAnswer) 
    if not savedAnswer?
      clearRadios()


Template.TorF_ex_display_question.helpers
  isArgument : () ->
    # There is an argument exactly when there is a conclusion.
    return ix.getConclusionFromParams()?
  isWorld : () -> ix.getWorldFromParam()?
  isTTrow : () -> ix.getTTrowFromParam()?
  TTletters : () ->
    row = ix.getTTrowFromParam()
    return (k for own k of row)
  TTvalues : () ->
    row = ix.getTTrowFromParam()
    return (v for own k,v of row)
  isJustOneSentence : () ->
    sentences = ix.getSentencesFromParam()
    return sentences.length is 1

Template.display_argument.helpers  
  premises : () -> 
    premises = ix.getPremisesFromParams()
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> ix.getConclusionFromParams().toString({replaceSymbols:true})


Template.TorF_ex.helpers
  sentences : () ->
    sentences = ix.getSentencesFromParam()
    return ({theSentence:x.toString({replaceSymbols:true}), idx:idx} for x, idx in sentences)

# The world might either come from a TTrow or a possible situation
getWorld = () ->
  # First try - do we have a possible situation?
  serializedSituation = ix.getWorldFromParam()
  if serializedSituation?
    serializedSituation = ix.possibleWorld.unabbreviate serializedSituation
    world = ix.possibleWorld.getSituationFromSerializedWord serializedSituation
    return world
  # Second try - do we have a truth table row?
  row = ix.getTTrowFromParam()
  if row?
    world = {}
    for key, value of row
      world[key] = (value is 'T')
    return world
  # Can't do it.
  return undefined 


checkOneAnswer = (answer, sentence) ->
  world = getWorld()
  return undefined unless world?
  # Can we just evaluate the sentence against the world?
  if sentence.evaluate?
    truthValue = sentence.evaluate(world) 
    return (answer is truthValue)
  # Is the sentence is about whether the situation is a counterexample to the argument?
  if _.isString(sentence) and (sentence.indexOf('counterexample') isnt -1)
    premises = ix.getPremisesFromParams()
    conclusion = ix.getConclusionFromParams()
    # Check that premises and conclusion are all awFOL sentences.
    return undefined unless conclusion.evaluate?
    for p in premises
      return undefined unless p.evaluate?
    isCounterexample = true
    for p in premises
      isCounterexample = false unless p.evaluate(world)
    isCounterexample = false if conclusion.evaluate(world)
    if (sentence.indexOf('not') is -1) and (sentence.indexOf("isn't") is -1) and (sentence.indexOf("isn’t") is -1)
      return (answer is isCounterexample)
    else 
      return (answer isnt isCounterexample)
  # Give up
  return undefined

checkAllAnswers = (answers) ->
  sentences = ix.getSentencesFromParam()
  errors = []
  for s, idx in sentences
    result = checkOneAnswer(answers[idx], s)
    return undefined unless result?
    if result is false
      errors.push(idx)
  msg = ''
  if errors.length > 0
    proportion = Math.floor (100*((sentences.length - errors.length) / sentences.length))
    msg = "You got #{proportion}% right."
  return {
    isCorrect: errors.length is 0
    msg : msg
  }
  
  
radioToArray = () ->
  $el = $('.trueOrFalseInputs')
  result = []
  $el.each (idx, $item) ->
    value = $('input:checked', $item).val()
    if value isnt undefined
       value = ((value + '').toLowerCase() is 'true')
    result.push value
  return result

arrayToRadio = (array) ->
  $el = $('.trueOrFalseInputs')
  $el.each (idx, $item) ->
    if array[idx] is true
      $('input.true', $el.eq(idx)).prop('checked', true)
    if array[idx] is false
      $('input.false', $el.eq(idx)).prop('checked', true)

clearRadios = () ->
  $el = $('.trueOrFalseInputs')
  $el.each (idx, $item) ->
    $('input.true', $el.eq(idx)).prop('checked', false)
    $('input.false', $el.eq(idx)).prop('checked', false)
  

Template.TorF_ex.events 
  'click input' : () -> ix.setAnswer(radioToArray())
  
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    answer = radioToArray()

    doc = 
      answer :
        type : 'TorF'
        content : answer
    
    # Try to get machine feedback
    result = checkAllAnswers(answer)
    if result?
      machineFeedback =
        isCorrect : result.isCorrect
      if result.msg and result.msg isnt ''
        machineFeedback.comment = result.msg
      doc.machineFeedback = machineFeedback
    else
      # Try to get human feedback from the grade and comments on a previous student’s answer.
      humanFeedback = ix.gradeUsingGradedAnswers(doc, {uniqueAnswer:true})
      if humanFeedback?
        doc.humanFeedback = humanFeedback
    ix.submitExercise(doc, () ->
        Materialize.toast "Your answer has been submitted.", 4000
    )




Template.TorF_ex_display_answer.helpers
  sentences : () ->
    ss = ix.getSentencesFromParam(this)
    ss = (x.toString({replaceSymbols:true}) for x in ss)
    return ({value:"#{v}", idx, theSentence:ss[idx]}  for v, idx in @answer.content)

