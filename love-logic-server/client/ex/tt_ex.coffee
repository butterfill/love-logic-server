# Return true if the student is being asked to construct truth tables for an argument,
# or false if the student is being asked to construct truth tables for one or more sentences.
exerciseSpecifiesAnArgument = (self) -> ix.getConclusionFromParams(self)?

# Return the sentences that the student must answer ‘true or false’ to.
# Param `self` is not necessary if the current page URL is an exercise link, but otherwise
# it should be an object with a `.exerciseId` key (such as a SubmittedExercise).
# This allows the function to be called both from exercise pages and when displaying answers
# to multiple exercises on a single page.
getQuestionsAboutTruthTable = (self) ->
  return [] if dontAskQuestions(self)
  if exerciseSpecifiesAnArgument(self)
    ss = [{theSentence:'The argument is logically valid.', idx:0, doNotDisplayNumbers:true}]
    answerTT = ix.getAnswer()?.tt
    if answerTT?
      # tt.length is the number of rows filled in
      for _ignore, idx in answerTT
        ss.push {theSentence:"Row #{idx+1} of the truth table is a counterexample to the argument.", idx:idx+1, doNotDisplayNumbers:true}
    return ss
  nofSentences = ix.getSentencesFromParam(self)?.length
  if nofSentences is 1
    ss = [
      {theSentence:'The sentence is a <span class="hint--bottom" data-hint="a sentence that is false in every possible situation">contradiction</span>.', idx:0, doNotDisplayNumbers:true}
      {theSentence:'The sentence is a <span class="hint--bottom" data-hint="a sentence that is true in every possible situation">logical truth</span>.', idx:1, doNotDisplayNumbers:true}
      {theSentence:'The sentence is a <span class="hint--top" data-hint="a sentence that is true in at least one possible situation">logical possibility</span>.', idx:2, doNotDisplayNumbers:true}
    ]
    return ss
  if nofSentences is 2
    ss = [
      {theSentence:'The two sentences are <span class="hint--bottom" data-hint="Two sentences are logically equivalent just if there’s no possible situation where one is true and the other false.">logically equivalent</span>.', idx:0, doNotDisplayNumbers:true}
      {theSentence:'The first sentence <span class="hint--bottom" data-hint="One sentence logically entails another just if there is no possible situation where the first is true and the second false">logically entails</span> the second.', idx:1, doNotDisplayNumbers:true}
      {theSentence:'The second sentence <span class="hint--top" data-hint="One sentence logically entails another just if there is no possible situation where the first is true and the second false">logically entails</span>  the first.', idx:2, doNotDisplayNumbers:true}
    ]
    return ss
  # There are no sentences to display
  return []

dontAskQuestions = (self) ->
  url = self?.exerciseId or ix.url()
  return url.indexOf('/noQ/') isnt -1
    

thereAreQuestionsToAsk = (self) -> getQuestionsAboutTruthTable(self)?.length > 0


Template.tt_ex.helpers
  isAskQuestions : thereAreQuestionsToAsk
  sentences : () ->
    FlowRouter.watchPathChange()
    return getQuestionsAboutTruthTable(@)
      


Template.tt_ex.events 
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    valuesFromTable = ix.truthTable.getValuesFromTable()
    result = ix.truthTable.checkAnswer(valuesFromTable)
    machineFeedback =
      isCorrect : result.isCorrect
    if result.message and result.message isnt ''
      machineFeedback.comment = result.message
    answerDoc = 
      answer :
        type : 'tt'
        content : {tt:valuesFromTable}
      machineFeedback : machineFeedback
    
    if thereAreQuestionsToAsk()
      # update answers (should not be necessary but is because
      # changing size of truthtable changes how many TorF questions there are.)
      ix.setAnswerKey( ix.radioToArray(), 'TorF')
      answerTorF = ix.getAnswer()?.TorF
      answerDoc.answer.content.TorF = answerTorF

    # If the truth table is correct and the exercise type involves an argument,
    # we will have asked the student to say whether the argument is valid and 
    # which rows are counteexamples.  So check the answers about whether the 
    # argument is logically valid and which rows are counterexamples are also correct.
    if machineFeedback.isCorrect and thereAreQuestionsToAsk() and ix.getConclusionFromParams()?
      nofLetters = ix.truthTable.getSentenceLetters().length
      # check answers are correct
      rowIsCounterexample = []
      for aRow in valuesFromTable
        rowClone = aRow[..]
        conclusion = rowClone.pop()
        premises = rowClone[nofLetters..]
        if false in premises
          rowIsCounterexample.push false
        else
          rowIsCounterexample.push( conclusion is false )
      correctIsValid = not (true in rowIsCounterexample)
      correctTorFAnswers = [correctIsValid].concat(rowIsCounterexample)
      # console.log("correctTorFAnswers #{correctTorFAnswers}")
      machineFeedback.isCorrect = _.isEqual(correctTorFAnswers, answerTorF)
      if not machineFeedback.isCorrect
        machineFeedback.comment = "Your truth table is correct but you did not answer all of the questions about validity and counterexamples correctly."

    # If the truth table is correct and the exercise is to give a truth table for one 
    # sentence, we will have asked the student to say whether the argument is a 
    # contradiction, a logical truth, or a logical possibility.
    # So check these answers.
    if machineFeedback.isCorrect and thereAreQuestionsToAsk() and ix.getSentencesFromParam()?.length is 1
      truthValuesOfSentence = (x[x.length-1] for x in valuesFromTable)
      correctTorFAnswers = [
        (not (true in truthValuesOfSentence))
        (not (false in truthValuesOfSentence))
        (true in truthValuesOfSentence)
      ]
      machineFeedback.isCorrect = _.isEqual(correctTorFAnswers, answerTorF)
      if not machineFeedback.isCorrect
        machineFeedback.comment = "Your truth table is correct but you did not answer all of the questions about the sentence correctly."
      
    # If the truth table is correct and the exercise is to give a truth table for  
    # two sentences, we will have asked the student to say whether the sentences
    # are logically equivalent, or whether one entails the other.
    # So check these answers.
    if machineFeedback.isCorrect and thereAreQuestionsToAsk() and ix.getSentencesFromParam()?.length is 2
      truthValuesOfSentence2 = (x[x.length-1] for x in valuesFromTable)
      truthValuesOfSentence1 = (x[x.length-2] for x in valuesFromTable)
      truthValuesOfSentences = _.zip(truthValuesOfSentence1, truthValuesOfSentence2)
      sentence1DoesntEntailSentence2 = true in ( (x is true and y is false) for [x,y] in truthValuesOfSentences)
      sentence2DoesntEntailsSentence1 = true in ( (x is true and y is false) for [y,x] in truthValuesOfSentences)
      correctTorFAnswers = [
        (_.isEqual(truthValuesOfSentence1, truthValuesOfSentence2))
        not sentence1DoesntEntailSentence2
        not sentence2DoesntEntailsSentence1
      ]
      machineFeedback.isCorrect = _.isEqual(correctTorFAnswers, answerTorF)
      if not machineFeedback.isCorrect
        machineFeedback.comment = "Your truth table is correct but you did not answer all of the questions about the two sentences correctly."
      
    
        
    ix.submitExercise answerDoc, (error, result) ->
      if error
        Materialize.toast "Sorry, could not submit answer. #{error.message}", 4000
      else
        Materialize.toast "Your answer has been submitted.", 4000

# ===================
# TorF_ex_display_answer

Template.tt_ex_display_question.helpers
  isSentences : () -> 
    sentences = ix.getSentencesFromParam(@)
    return sentences? and sentences.length? and sentences.length > 0
  isOneSentence : () ->
    sentences = ix.getSentencesFromParam(@)
    return sentences?.length is 1
  isArgument : () -> exerciseSpecifiesAnArgument(@)
  sentences : () ->
    ss = ix.getSentencesFromParam(@)
    ix.setDialectFromExerciseSet()
    ss = (x.toString({replaceSymbols:true}) for x in ss)
    ssObj = ({theSentence:x, idx} for x, idx in ss)
    return ssObj
  premises : () -> 
    premises = ix.getPremisesFromParams(@)
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    ix.setDialectFromExerciseSet()
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> 
    ix.setDialectFromExerciseSet()
    ix.getConclusionFromParams(@).toString({replaceSymbols:true})

Template.tt_ex_display_answer.helpers
  isAskQuestions : () -> thereAreQuestionsToAsk(@)
  sentences : () ->
    questionSentences = getQuestionsAboutTruthTable(@)
    answerTorF = @answer.content.TorF
    for value, idx in answerTorF
      if questionSentences[idx]?
        questionSentences[idx].value = "#{value}"
    return questionSentences
    