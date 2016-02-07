


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
  
    # First check that the world is a possible situation
    # (It might not be; e.g. the same name is given to two objects.)
    # TODO: inefficient because this is done again by ix.possibleWorld.checkSentencesTrue
    isCorrect = true
    try
      possibleSituation = ix.possibleWorld.getSituationFromSerializedWord( ix.possibleWorld.serialize($grid) )
    catch error
      comment = "#{error}"
      isCorrect = false 
  
    if isCorrect
      # There are two possibilities.
      # First possibility: user has to make all the sentences true
      if ix.getSentencesFromParam()?
        isCorrect = isCorrect and ix.possibleWorld.checkSentencesTrue($grid)
        comment = "Your submitted possible situation is #{('not' if not isCorrect) or ''} correct."
      # Second possibility: user has to give a counterexample to argument
      if ix.getConclusionFromParams()?
        try
          isCorrect = isCorrect and ix.possibleWorld.checkSentencesAreCounterexample($grid)
          comment = "Your submitted possible situation is #{('not' if not isCorrect) or ''} a counterexample."
        catch e
          isCorrect = false
          comment = "#{e}"
        
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
  isSentences : () -> 
    FlowRouter.watchPathChange()
    return ix.getSentencesFromParam(@)? and ix.getSentencesFromParam(@).length > 0
  isArgument : () -> 
    FlowRouter.watchPathChange()
    return ix.getConclusionFromParams(@)?
  sentences : () ->
    FlowRouter.watchPathChange()
    folSentences = ix.getSentencesFromParam(@) or []
    return ({theSentence:x.toString({replaceSymbols:true})} for x in folSentences)
  premises : () -> 
    FlowRouter.watchPathChange()
    premises = ix.getPremisesFromParams(@)
    # Premises may be awFOL objects or strings.
    # But because strings have `.toString`, this works either way.
    (e.toString({replaceSymbols:true}) for e in premises)
  conclusion : () -> ix.getConclusionFromParams(@).toString({replaceSymbols:true})


Template.create_ex_display_answer.helpers
  exSubtypeIsValid : exSubtypeIsValid
  exSubtypeIsInconsistent : exSubtypeIsInconsistent 
  displayCreateWorld : () -> 
    FlowRouter.watchPathChange()
    return @answer.content.world? or @answer.content.counterexample?
  sentences : () ->
    FlowRouter.watchPathChange()
    answerTorF = @answer.content.TorF?[0]
    if ix.isExerciseSubtype('orValid', @) and answerTorF?
      return [{theSentence:'The argument is logically valid.', idx:0, value:"#{answerTorF}"}]
    if ix.isExerciseSubtype('orInconsistent', @) and answerTorF?
      return [{theSentence:'The sentences are logically inconsistent.', idx:0, value:"#{answerTorF}"}]

# This is used by both /ex/create and /ex/counter,
# so it must cope with .world and .counterexample answer objects.
Template.reveal_incorrect_truth_values.helpers
  incorrectTruthValues : () ->
    FlowRouter.watchPathChange()
    counterexample = @answer.content.counterexample
    if not counterexample?
      worldAbbreviated = @answer.content.world
      world = ix.possibleWorld.unabbreviate( worldAbbreviated )
      try
        counterexample = ix.possibleWorld.getSituationFromSerializedWord( world )
      catch error
        return []
    sentences = ix.getSentencesFromParam(@)
    isArgument = false
    if not sentences?
      isArgument = true
      sentences = ix.getPremisesFromParams(@)
    return [] unless counterexample? and sentences?
    result = []
    for s in sentences
      try
        isTrue = s.evaluate(counterexample) or 'F'
      catch error
        isTrue = '[not evaluable]'
      if isTrue isnt true
        result.push( {sentence:s.toString({replaceSymbols:true}), isTrue:isTrue} )
    if isArgument
      conclusion = ix.getConclusionFromParams(@)
      try
        conclusionTruthValue = conclusion.evaluate(counterexample)
        conclusionTruthValue = 'T' if conclusionTruthValue is true
      catch error
        conclusionTruthValue = '[not evaluable]'
      unless conclusionTruthValue is false
        result.push( {sentence:conclusion.toString({replaceSymbols:true}), isTrue:conclusionTruthValue} )
    return result
    
