Template.scope_ex.onRendered () ->
  # Allow the answer to be updated by setting the session variable
  templateInstance = this
  @autorun () ->
    # We need to `watchPathChange` so that the answer also gets updated when we change page.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer()?.scope
    if savedAnswer? and _.isArray(savedAnswer) and savedAnswer.length>0
      setAnswer(savedAnswer, templateInstance)
    else
      # clear answer
      unselectSymbols($(templateInstance.find('.theScopeSentences')))

getAnswer = () ->
  result = []
  $sentences = $('.sentenceParent')
  $sentences.each (idx, el) ->
    $sentence = $(el)
    $symbol = $('._scopeSelected', $sentence)
    if $symbol.length isnt 1
      result.push {}
    else
      result.push {
        scopeDepth : $symbol.parents('._expressionWrap').length
        symbolNum : $symbol.attr('data-symbolNum')
      }
  return result
  
setAnswer = (answers, template) ->
  $sentences = $(template.findAll('.sentenceParent'))
  $sentences.each (idx, el) ->
    $sentence = $(el)
    ans = answers[idx]
    return unless ans?.symbolNum?
    $symbols = $('._symbolWrap', $sentence)
    $symbols.each (idx, el) ->
      $sym = $(el)
      selectSymbol($sym) if $sym.attr('data-symbolNum') is ans.symbolNum

selectSymbol = ($el) ->
  # First deselect all symbols in this sentence ...
  $sentence = $el.parents('.sentenceParent')
  unselectSymbols($sentence)
  $('._symbolWrap', $sentence).css({background:'white',color:'black'}).removeClass('_scopeSelected')
  # ... then select the specified element.
  $el.css({background:'black',color:'white',borderRadius:'999px'}).addClass('_scopeSelected')
  # Finally, save the answer to localStorage (or whatever).
  ix.setAnswerKey(getAnswer(), 'scope')

unselectSymbols = ($parent) ->
  $('._symbolWrap', $parent).css({background:'white',color:'black'}).removeClass('_scopeSelected')

Template.scope_ex.events
  'click ._symbolWrap' : (event, template) ->
    $el = $(event.target)
    selectSymbol($el)

  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    answer = getAnswer()
    answerTorF = (a.scopeDepth is 1 for a in answer)
    isCorrect = not (false in answerTorF)
    if isCorrect
      comment = "Well done!"
    else
      nofIncorrect = 0
      for val in answerTorF
        nofIncorrect += 1 if val is false
      comment = "You got #{nofIncorrect} wrong."

    machineFeedback = {
      isCorrect
      comment 
    }
    
    answerDoc = 
      answer :
        type : 'scope'
        content : {scope:answer}
      machineFeedback : machineFeedback
    
    ix.submitExercise answerDoc, (error, result) ->
      if error
        Materialize.toast "Sorry, could not submit answer. #{error.message}", 4000
      else
        Materialize.toast "Your answer has been submitted.", 4000

    


Template.scope_ex_display_sentences.helpers
  sentences : () ->
    ss = ix.getSentencesFromParam(@)
    ix.setDialectFromExerciseSet()
    ss = (x.toString({replaceSymbols:true, wrapWithDivs:true}) for x in ss)
    ssObj = ({theSentence:x, idx} for x, idx in ss)
    return ssObj

# Called from the `/grade` url to display multiple students’ answers on the same page
Template.scope_ex_display_answer.onRendered () ->
  answer = @data.answer.content.scope
  setAnswer(answer, @)

