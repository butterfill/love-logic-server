Template.proof_ex.onCreated () ->
  self=this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

  
# -------------
# Template helpers

Template.proof_ex.helpers
  exSubtypeIsOrInvalid : () -> 
    FlowRouter.watchPathChange()
    ix.isExerciseSubtype('orInvalid', @)
  sentences : () ->
    if ix.isExerciseSubtype('orInvalid', @)
      return [{theSentence:'The argument is logically valid.', idx:0}]
  displayProofEditor : () ->
    FlowRouter.watchPathChange()
    answer = ix.getAnswer()
    if answer?.TorF?[0] is false and ix.isExerciseSubtype('orInvalid') 
      return false
    return true


Template.proof_ex_display_question.helpers
  conclusion : () ->
    FlowRouter.watchPathChange()
    ix.setDialectFromExerciseSet()
    return ix.getConclusionFromParams(@)?.toString({replaceSymbols:true})
  premises : () -> 
    FlowRouter.watchPathChange()
    folList = ix.getPremisesFromParams(@) or []
    ix.setDialectFromExerciseSet()
    return (e.toString({replaceSymbols:true}) for e in folList)
  hasPremises : () -> 
    FlowRouter.watchPathChange()
    return ix.getPremisesFromParams(@)?.length > 0
  exSubtypeIsOrInvalid : () -> 
    FlowRouter.watchPathChange()
    ix.isExerciseSubtype('orInvalid', @)
  
    
    
    
      
# -------------
# User interactions


Template.proof_ex.events
  # The html is in the `submit_btn` template
  'click button#submit' : (event, template) ->
    #First work out what kind of answer we are submitting.
    
    # First possibility: the answer is that the argument is not valid
    if ix.isExerciseSubtype('orInvalid') 
      answerTorF = ix.getAnswer()?.TorF?[0]
      if answerTorF is false 
        doc = 
          answer : 
            type : 'proof'
            content : {TorF:[answerTorF]}
        humanFeedback = ix.gradeUsingGradedAnswers(doc)
        if humanFeedback?
          doc.humanFeedback = humanFeedback
        ix.submitExercise doc, (error, result) ->
          if error
            Materialize.toast "There was an error submitting your answer. #{error.message}", 4000
          else
            Materialize.toast "Your answer has been submitted.", 4000
        return      
    
    # Other possibility: the answer is a proof
    proofText = ix.getAnswer()?.proof
    theProof = proof.parse(proofText)
    if _.isString(theProof)
      # The proof could not be parsed.
      message = theProof
      isCorrect = false
    else
      isCorrect = theProof.verify()
      message = ('' if isCorrect) or theProof.listErrorMessages()
      
      # finally, check the premises and conclusion are correct
      premisesAndConclusionOk = ix.checkPremisesAndConclusionOfProof(theProof)
      if _.isString premisesAndConclusionOk
        message += premisesAndConclusionOk
        isCorrect = false
      
    machineFeedback = {
      isCorrect : isCorrect
      comment : "Your submitted proof is #{('not' if not isCorrect) or ''} correct.  #{message}"
    }
    doc = {
      answer : 
        type : 'proof'
        content : {proof:proofText}
      machineFeedback : machineFeedback
    }
    dialectNameAndVersion = fol.getCurrentDialectNameAndVersion()
    if dialectNameAndVersion?
      doc.answer.content.dialectName = dialectNameAndVersion.name
      doc.answer.content.dialectVersion = dialectNameAndVersion.version
    ix.submitExercise(doc, () ->
        Materialize.toast "Your proof has been submitted.", 4000
    )

  
  




Template.proof_ex_display_answer.helpers
  proofRulesName : () -> "#{@answer.content.dialectName or '[unspecified]'} (version #{@answer.content.dialectVersion})"
  displayProof : () -> @answer.content.proof?
  answerLines : () ->
    return '' unless @answer.content.proof?
    ix.setDialectFromThisAnswer(@answer)
    theProof = proof.parse(@answer.content.proof)
    if _.isString theProof
      return ({line:x, lineNumber:"  #{idx+1} ".slice(-4)} for x, idx in @answer.content.proof?.split('\n'))
    else
      return ({line:x} for x in theProof.toString({numberLines:true}).split('\n') )
  exSubtypeIsOrInvalid : () -> ix.isExerciseSubtype('orInvalid', @)
  sentences : () ->
    answerTorF = @answer.content.TorF?[0]
    if ix.isExerciseSubtype('orInvalid', @) and answerTorF?
      return [{theSentence:'The argument is logically valid.', idx:0, value:"#{answerTorF}"}]

