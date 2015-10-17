

Template.tt_ex.helpers
  isArgument : () -> ix.getConclusionFromParams()?
  sentences : () ->
    FlowRouter.watchPathChange()
    ss = [{theSentence:'The argument is logically valid.', idx:0}]
    answerTT = ix.getAnswer()?.tt
    if answerTT?
      # tt.length is the number of rows filled in
      for _ignore, idx in answerTT
        ss.push {theSentence:"Row #{idx+1} is a counterexample to the argument.", idx:idx+1, doNotDisplayNumbers:true}
    return ss


Template.tt_ex.events 
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    values = ix.truthTable.getValuesFromTable()
    result = ix.truthTable.checkAnswer(values)
    machineFeedback =
      isCorrect : result.isCorrect
    if result.message and result.message isnt ''
      machineFeedback.comment = result.message
    answerDoc = 
      answer :
        type : 'tt'
        content : {tt:values}
      machineFeedback : machineFeedback
    
    if ix.getConclusionFromParams()?
      answerTorF = ix.getAnswer()?.TorF
      answerDoc.answer.content.TorF = answerTorF

    # If the truth table is correct and the exercise type involves an argument,
    # we will have asked the student to say whether the argument is valid and 
    # which rows are counteexamples.  So check the answers about whether the 
    # argument is logically valid and which rows are counterexamples are also correct.
    if machineFeedback.isCorrect and ix.getConclusionFromParams()?
      nofLetters = ix.truthTable.getSentenceLetters().length
      # check answers are correct
      rowIsCounterexample = []
      for aRow in values
        rowClone = aRow[..]
        conclusion = rowClone.pop()
        premises = rowClone[nofLetters..]
        if false in premises
          rowIsCounterexample.push false
        else
          rowIsCounterexample.push( conclusion is false )
      correctIsValid = not (true in rowIsCounterexample)
      correctTorFAnswers = [correctIsValid].concat(rowIsCounterexample)
      console.log("correctTorFAnswers #{correctTorFAnswers}")
      machineFeedback.isCorrect = _.isEqual(correctTorFAnswers, answerTorF)
      if not machineFeedback.isCorrect
        machineFeedback.comment = "Your truth table is correct but you did not answer all of the questions about validity and counterexamples correctly."
        
    ix.submitExercise answerDoc, (error, result) ->
      if error
        Materialize.toast "Sorry, could not submit answer. #{error.message}", 4000
      else
        Materialize.toast "Your answer has been submitted.", 4000

# ===================
# TorF_ex_display_answer

Template.tt_ex_display_question.helpers
  isSentences : () -> ix.getSentencesFromParam()? and ix.getSentencesFromParam().length > 0
  isArgument : () -> ix.getConclusionFromParams()?
  sentences : () ->
    ss = ix.getSentencesFromParam()
    ss = (x.toString({replaceSymbols:true}) for x in ss)
    ssObj = ({theSentence:x, idx} for x, idx in ss)
    return ssObj
  premises : () -> 
    premises = ix.getPremisesFromParams()
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> ix.getConclusionFromParams().toString({replaceSymbols:true})

Template.tt_ex_display_answer.helpers
  isArgument : () -> ix.getConclusionFromParams(@)?
  sentences : () ->
    answerTorF = @answer.content.TorF
    ss = []
    if answerTorF?[0]?
      [answerIsValid, answerIsCounterexample...] = answerTorF
      ss = [
        {theSentence:'The argument is logically valid.', idx:0, value:"#{answerIsValid}"}
      ]
      for ans, idx in answerIsCounterexample
        ss.push {theSentence:"Row #{idx+1} is a counterexample to the argument.", idx:idx+1, value:"#{ans}"}
    return ss
    