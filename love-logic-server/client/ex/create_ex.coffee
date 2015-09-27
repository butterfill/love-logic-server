

Template.create_ex.events 
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    # We assume there is only one
    $grid = $('.grid-stack')
    isCorrect = ix.possibleWorld.checkSentencesTrue($grid)
    machineFeedback = {
      isCorrect : isCorrect
      comment : "Your submitted possible situation is #{('not' if not isCorrect) or ''} correct."
    }
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
  sentences : () ->
    folSentences = ix.getSentencesFromParam()
    return ({theSentence:x.toString({replaceSymbols:true})} for x in folSentences)

