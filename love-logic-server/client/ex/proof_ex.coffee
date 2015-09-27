# -------------
# Template helpers


  



Template.proof_ex_display_question.helpers
  conclusion : () ->
    return ix.getConclusionFromParams().toString({replaceSymbols:true})
  premises : () -> 
    folList = ix.getPremisesFromParams()
    return (e.toString({replaceSymbols:true}) for e in folList)
  hasPremises : () -> 
    return ix.getPremisesFromParams()?.length > 0


    
    
    
      
# -------------
# User interactions


Template.proof_ex.events
  # The html is in the `submit_btn` template
  'click button#submit' : (event, template) ->
    proofText = ix.getAnswer()
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
    ix.submitExercise({
        answer : 
          type : 'proof'
          content : proofText
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your proof has been submitted.", 4000
    )

  
  




Template.proof_ex_display_answer.helpers
  answerLines : () ->
    return ({line:x} for x in @answer.content.split('\n'))