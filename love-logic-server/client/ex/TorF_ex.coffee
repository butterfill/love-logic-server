
Template.TorF_ex.rendered = () ->
  templateInstance = this
  # Allow the answer to be updated by setting the session variable
  Tracker.autorun () ->
    # We need to `watchPathChange` so that the answer also gets updated when we change page.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer() 
    if savedAnswer?.length? and savedAnswer?.length > 0
      arrayToRadio(savedAnswer) 



Template.TorF_ex.helpers
  sentences : () ->
    folSentences = ix.getSentencesFromParam()
    return ({theSentence:x.toString({replaceSymbols:true}), idx:idx} for x, idx in folSentences)

save = () ->
  ix.setAnswer(radioToArray())

checkAnswer = (answer) ->
  serializedSituation = ix.getWorldFromParam()
  serializedSituation = ix.possibleWorld.unabbreviate serializedSituation
  world = ix.possibleWorld.getSituationFromSerializedWord serializedSituation
  sentences = ix.getSentencesFromParam()
  truthValues = (s.evaluate(world) for s in sentences)
  errors = []
  for v, idx in truthValues
    if v isnt answer[idx]
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
  

Template.TorF_ex.events 
  'click input' : save
  
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    console.log radioToArray()
    answer = radioToArray()
    result = checkAnswer(answer)
    machineFeedback =
      isCorrect : result.isCorrect
    if result.msg and result.msg isnt ''
      machineFeedback.comment = result.msg
    ix.submitExercise({
        answer :
          type : 'TorF'
          content : answer
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your answer has been submitted.", 4000
    )



# ===================
# TorF_ex_display_answer


Template.TorF_ex_display_answer.helpers
  sentences : () ->
    console.log this
    ss = decodeURIComponent(@exerciseId.split('/')[3]).split('|')
    ss = (fol.parse(x).toString({replaceSymbols:true}) for x in ss)
    return ({value:"#{v}", idx, theSentence:ss[idx]}  for v, idx in @answer.content)

