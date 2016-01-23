


Template.create_ex.onCreated () ->
  self=this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

Template.create_ex.onRendered () ->
  @autorun () ->
    FlowRouter.watchPathChange()
    $grid = $('.grid-stack')
    ix.possibleWorld.checkSentencesTrue($grid)


exSubtypeIsValid = () -> 
  FlowRouter.watchPathChange()
  return true if ix.isExerciseSubtype('orValid', @)
exSubtypeIsInconsistent = () -> 
  FlowRouter.watchPathChange()
  return true if ix.isExerciseSubtype('orInconsistent', @)

Template.create_ex.helpers
  exSubtypeIsValid : exSubtypeIsValid
  exSubtypeIsInconsistent : exSubtypeIsInconsistent 
  sentences : () ->
    FlowRouter.watchPathChange()
    if ix.isExerciseSubtype('orValid', @)
      return [{theSentence:'The argument is logically valid.', idx:0}]
    if ix.isExerciseSubtype('orInconsistent', @)
      return [{theSentence:'The sentences are logically inconsistent.', idx:0}]
  displayCreateWorld : () ->
    FlowRouter.watchPathChange()
    answer = ix.getAnswer()
    if answer?.TorF?[0] is true and ix.isExerciseSubtype('orValid') 
      return false
    if answer?.TorF?[0] is true and ix.isExerciseSubtype('orInconsistent')
      return false
    return true
    
  
  

Template.create_ex.events 
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    #First work out what kind of answer we are submitting.
    answerTorF = ix.getAnswer()?.TorF?[0]
    if (ix.isExerciseSubtype('orValid') or ix.isExerciseSubtype('orInconsistent')) and answerTorF is true
      doc = 
        answer : 
          type : 'create'
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
          content : {world:ix.possibleWorld.serializeAndAbbreviate($grid)}
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your possible situation has been submitted.", 4000
    )
  


# ===================
# display question template


Template.create_ex_display_question.helpers 
  exSubtypeIsValid : exSubtypeIsValid
  exSubtypeIsInconsistent : exSubtypeIsInconsistent 
  isSentences : () -> ix.getSentencesFromParam(@)? and ix.getSentencesFromParam(@).length > 0
  isArgument : () -> ix.getConclusionFromParams(@)?
  sentences : () ->
    folSentences = ix.getSentencesFromParam(@) or []
    return ({theSentence:x.toString({replaceSymbols:true})} for x in folSentences)
  premises : () -> 
    premises = ix.getPremisesFromParams(@)
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> ix.getConclusionFromParams(@).toString({replaceSymbols:true})

Template.create_ex_display_answer.helpers
  exSubtypeIsValid : exSubtypeIsValid
  exSubtypeIsInconsistent : exSubtypeIsInconsistent 
  displayCreateWorld : () -> @answer.content.world?
  sentences : () ->
    answerTorF = @answer.content.TorF?[0]
    if ix.isExerciseSubtype('orValid', @) and answerTorF?
      return [{theSentence:'The argument is logically valid.', idx:0, value:"#{answerTorF}"}]
    if ix.isExerciseSubtype('orInconsistent', @) and answerTorF?
      return [{theSentence:'The sentences are logically inconsistent.', idx:0, value:"#{answerTorF}"}]
