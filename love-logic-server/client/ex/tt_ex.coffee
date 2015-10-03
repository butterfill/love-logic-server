
Template.tt_ex.events 
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    values = ix.truthTable.getValuesFromTable()
    result = ix.truthTable.checkAnswer(values)
    machineFeedback =
      isCorrect : result.isCorrect
    if result.message and result.message isnt ''
      machineFeedback.comment = result.message
    ix.submitExercise({
        answer :
          type : 'tt'
          content : values
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your answer has been submitted.", 4000
    )

# ===================
# TorF_ex_display_answer

Template.tt_ex_display_question.helpers
  sentences : () ->
    ss = ix.getSentencesFromParam()
    ss = (x.toString({replaceSymbols:true}) for x in ss)
    ssObj = ({theSentence:x, idx} for x, idx in ss)
    return ssObj


