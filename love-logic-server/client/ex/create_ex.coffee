

Template.create_ex.events 
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    # We assume there is only one
    $grid = $('.grid-stack')
    
    # There are two possibilities.
    # First possibility: user has to make all the sentences true
    if ix.getSentencesFromParam()?
      isCorrect = ix.possibleWorld.checkSentencesTrue($grid)
      comment = "Your submitted possible situation is #{('not' if not isCorrect) or ''} correct."
    # Second possibility: user has to give a counterexample to argument
    if ix.getConclusionFromParams()?
      isCorrect = ix.possibleWorld.checkSentencesAreCounterexample($grid)
      comment = "Your submitted possible situation is #{('not' if not isCorrect) or ''} a counterexample."
    machineFeedback = { isCorrect, comment }
    ix.submitExercise({
        answer : 
          type : 'create'
          content : ix.possibleWorld.serializeAndAbbreviate($grid)
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your possible situation has been submitted.", 4000
    )
  


# ===================
# display question template


Template.create_ex_display_question.helpers 
  isSentences : () -> ix.getSentencesFromParam()? and ix.getSentencesFromParam().length > 0
  isArgument : () -> ix.getConclusionFromParams()?
  sentences : () ->
    folSentences = ix.getSentencesFromParam()
    return ({theSentence:x.toString({replaceSymbols:true})} for x in folSentences)
  premises : () -> 
    premises = ix.getPremisesFromParams()
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> ix.getConclusionFromParams().toString({replaceSymbols:true})

