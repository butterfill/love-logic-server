
Template.evaluate_ex.onCreated () ->
  self = this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

Template.evaluate_ex.onRendered () ->
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

Template.evaluate_ex_display_question.helpers
  isArgument : () ->
    # There is an argument exactly when there is a conclusion.
    return ix.getConclusionFromParams()?
  isWorld : () -> ix.getWorldFromParam()?
  isTTrow : () -> ix.getTTrowFromParam()?
  premises : () -> 
    premises = ix.getPremisesFromParams()
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> ix.getConclusionFromParams().toString({replaceSymbols:true})
  TTletters : () ->
    row = ix.getTTrowFromParam()
    return (k for own k of row)
  TTvalues : () ->
    row = ix.getTTrowFromParam()
    return (v for own k,v of row)
  isJustOneSentence : () ->
    sentences = ix.getSentencesFromParam()
    return sentences.length is 1


Template.evaluate_ex.helpers
  sentences : () ->
    sentences = ix.getSentencesFromParam()
    return ({theSentence:x, idx:idx} for x, idx in sentences)

  
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
  

Template.evaluate_ex.events 
  'click input' : () -> ix.setAnswer(radioToArray())
  
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    console.log radioToArray()
    answer = radioToArray()
    # Try to get human feedback from the grade and comments on a previous student’s answer.
    doc = 
      answer :
        type : 'evaluate'
        content : answer
    humanFeedback = ix.gradeUsingGradedAnswers(doc, {uniqueAnswer:true})
    if humanFeedback?
      doc.humanFeedback = humanFeedback
    ix.submitExercise(doc, () ->
        Materialize.toast "Your answer has been submitted.", 4000
    )



# ===================
# TorF_ex_display_answer


Template.evaluate_ex_display_answer.helpers
  sentences : () ->
    ss = ix.getSentencesFromParam(this)
    ss = (x.toString({replaceSymbols:true}) for x in ss)
    return ({value:"#{v}", idx, theSentence:ss[idx]}  for v, idx in @answer.content)

