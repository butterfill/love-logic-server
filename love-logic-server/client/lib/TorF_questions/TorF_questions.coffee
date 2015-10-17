Template.TorF_questions.onRendered () ->
  templateInstance = this
  
  # Allow the answer to be updated by setting the session variable
  # (as when the user hits the ‘load answer’ link) --- we need this 
  # because of the way radios render and checkboxes don't get updated (we can’t 
  # easily make the ‘checked’ property reactive).
  @autorun () ->
    # We need to `watchPathChange` so that the answer also gets updated when we change page.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer()?.TorF
    if savedAnswer?.length? and savedAnswer?.length > 0
      arrayToRadio(savedAnswer)
    if not savedAnswer?
      clearRadios()
      
Template.TorF_questions.helpers
  isTrueChecked : () -> 
    return (ix.getAnswer()?.TorF?[@idx] is true) 
  isFalseChecked : () -> (ix.getAnswer()?.TorF?[@idx] is false)
  
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
  
Template.TorF_questions.events 
  'click input' : () -> 
    answer = ix.getAnswer()
    answer ?= {}
    answer.TorF = ix.radioToArray()
    ix.setAnswer(answer)
