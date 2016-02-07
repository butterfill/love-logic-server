Template.counter_ex.onCreated () ->
  self=this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId
    savedAnswer = ix.getAnswer()?.counterexample
    unless savedAnswer?
      ix.setAnswerKey( buildMinimalAnswer(), 'counterexample' )

buildMinimalAnswer = () ->
  domain = [0]
  
  allSentences = ix.getSentencesFromParam()
  unless allSentences?.length > 0
    allSentences = ix.getPremisesFromParams()
    allSentences.push( ix.getConclusionFromParams() )
  
  names = {}
  predicates = {}
  for sentence in allSentences
    for name in sentence.getNames()
      names[name] = 0
    for predicate in sentence.getPredicates()
      predicates[predicate.name] = []
  
  return {domain, names, predicates}


Template.counter_ex.onRendered () ->
  @autorun () ->
    FlowRouter.watchPathChange()
    updateDisplayWhetherSentencesTrue()

# Tell the user which sentences are T and which F in /counter/qq exercises
# TODO Partially duplicates ix.possibleWorld.checkSentencesTrue (which is not used here but is used in /create/qq exercises.)
updateDisplayWhetherSentencesTrue = () ->
  sentences = ix.getSentencesFromParam()
  counterexample = ix.getAnswer().counterexample
  return undefined unless sentences? and counterexample?
  for sentence, idx in sentences
    try
      isTrue = sentence.evaluate(counterexample)
    catch error 
      $(".sentenceIsTrue:eq(#{idx})").text('[not evaluable in this situation]')
    #TODO: this is part of another template (create_ex_display_question)!
    $(".sentenceIsTrue:eq(#{idx})").text(('T' if isTrue) or 'F')






exSubtypeIsValid = () -> 
  FlowRouter.watchPathChange()
  return true if ix.isExerciseSubtype('orValid', @)
exSubtypeIsInconsistent = () -> 
  FlowRouter.watchPathChange()
  return true if ix.isExerciseSubtype('orInconsistent', @)

Template.counter_ex.helpers
  exSubtypeIsValid : exSubtypeIsValid
  exSubtypeIsInconsistent : exSubtypeIsInconsistent 
  sentences : () ->
    FlowRouter.watchPathChange()
    if ix.isExerciseSubtype('orValid', @)
      return [{theSentence:'The argument is logically valid.', idx:0}]
    if ix.isExerciseSubtype('orInconsistent', @)
      return [{theSentence:'The sentences are logically inconsistent.', idx:0}]
  displayCreateCounterexample : () ->
    FlowRouter.watchPathChange()
    answer = ix.getAnswer()
    if answer?.TorF?[0] is true and ix.isExerciseSubtype('orValid') 
      return false
    if answer?.TorF?[0] is true and ix.isExerciseSubtype('orInconsistent')
      return false
    return true
  namesToAssign : () -> 
    FlowRouter.watchPathChange()
    return _.keys( ix.getAnswer().counterexample.names )
  getNameReferent : () -> 
    FlowRouter.watchPathChange()
    return ix.getAnswer().counterexample.names[@]
  predicatesToAssign : () ->  
    FlowRouter.watchPathChange()
    return _.keys( ix.getAnswer().counterexample.predicates )
  getPredicateExtension : () -> 
    FlowRouter.watchPathChange()
    return extensionToString(ix.getAnswer().counterexample.predicates[@])
  getDomain : () -> 
    FlowRouter.watchPathChange()
    return ix.getAnswer().counterexample.domain



Template.counter_ex_display_answer.helpers
  exSubtypeIsValid : exSubtypeIsValid
  exSubtypeIsInconsistent : exSubtypeIsInconsistent 
  displayCounterexample : () -> 
    @answer.content.counterexample?
  sentences : () ->
    answerTorF = @answer.content.TorF?[0]
    if ix.isExerciseSubtype('orValid', @) and answerTorF?
      return [{theSentence:'The argument is logically valid.', idx:0, value:"#{answerTorF}"}]
    if ix.isExerciseSubtype('orInconsistent', @) and answerTorF?
      return [{theSentence:'The sentences are logically inconsistent.', idx:0, value:"#{answerTorF}"}]
  namesToAssign : () -> 
    FlowRouter.watchPathChange()
    return _.keys( @answer.content.counterexample.names )
  getNameReferent : () -> 
    FlowRouter.watchPathChange()
    name = @
    answer = Template.parentData().answer
    return answer.content.counterexample.names[name]
  predicatesToAssign : () ->  
    FlowRouter.watchPathChange()
    return _.keys( @answer.content.counterexample.predicates )
  getPredicateExtension : () -> 
    FlowRouter.watchPathChange()
    predicateName = @
    answer = Template.parentData().answer
    return extensionToString(answer.content.counterexample.predicates[predicateName])
  getDomain : () -> 
    FlowRouter.watchPathChange()
    return @answer.content.counterexample.domain
    


    

parseExtension = (txt) ->
  try
    return eval(txt.replace(/</g,'[').replace(/>/g,']').replace(/^{/,'[').replace(/\}$/,"]"))
  catch e
    return undefined

extensionToString = (extension) ->
  return '{  }' unless extension?
  return JSON.stringify(extension).replace(/^\[/,'{ ').replace(/\]$/,' }').replace(/\[/g,' <').replace(/\]/g,'> ')

Template.counter_ex.events 

  'click .addToDomain' : (event, template) ->
    w = ix.getAnswer().counterexample
    w.domain.push( w.domain.length )
    ix.setAnswerKey(w, 'counterexample')
  
  'click .removeFromDomain' : (event, template) ->
    w = ix.getAnswer().counterexample
    if w.domain.length > 1 
      removed = w.domain.pop()
      namedObjects =  _.values(w.names)
      extensionObjects = []
      for extension in _.values(w.predicates)
        for tuple in extension
          extensionObjects = extensionObjects.concat(tuple)
      if removed in namedObjects or removed in extensionObjects
        w.domain.push(removed)
        Materialize.toast "You cannot remove an object (#{removed}) from the domain if it is named or in the extension of a predicate.", 4000
      else
        ix.setAnswerKey(w, 'counterexample')
    else
      Materialize.toast "Any possible situations must contain at least one object.", 4000
  
  'blur .names' : (event, template) ->
    name = event.target.name.split('-')[1]
    value = parseInt(event.target.value)
    w = ix.getAnswer().counterexample
    if value? and value in w.domain
      w.names[name] = value
      ix.setAnswerKey(w, 'counterexample')
    else
      event.target.value = w.names[name]
      Materialize.toast "Names can only refer to objects in the domain.", 4000
      
  'blur .predicates' : (event, template) ->
    predicate = event.target.name.split('-')[1]
    extension = parseExtension(event.target.value)
    w = ix.getAnswer().counterexample
    unless extension?
      Materialize.toast "Your extension was not correctly formatted.", 4000
      event.target.value = extensionToString(w.predicates[predicate])
      return
    extensionIsOk = _.isArray(extension)
    if extensionIsOk
      for tuple in extension
        extensionIsOk = false unless _.isArray(tuple)
        for elem in tuple
          extensionIsOk = false unless elem in w.domain
    unless extensionIsOk
      Materialize.toast "An extension can only contain tuples of objects from the domain.", 4000
      event.target.value = extensionToString(w.predicates[predicate])
      return
    w.predicates[predicate] = extension
    ix.setAnswerKey(w, 'counterexample')
       
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    #First work out what kind of answer we are submitting.
    answerTorF = ix.getAnswer()?.TorF?[0]
    if (ix.isExerciseSubtype('orValid') or ix.isExerciseSubtype('orInconsistent')) and answerTorF is true
      doc = 
        answer : 
          type : 'counter'
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
      
    counterexample = ix.getAnswer().counterexample
    
    # There are two possibilities.
    # First possibility: user has to make all the sentences true
    if ix.getSentencesFromParam()?
      isCorrect = counterexample?
      if isCorrect
        sentences = ix.getSentencesFromParam()
        for sentence in sentences
          isCorrect = isCorrect and sentence.evaluate(counterexample)
      comment = "Your submitted possible situation is #{('not' if not isCorrect) or ''} correct.  Can you make all the sentences true?"
    # Second possibility: user has to give a counterexample to argument
    if ix.getConclusionFromParams()?
      isCorrect = counterexample?
      if isCorrect
        # premises must be true in the counterexample
        sentences = ix.getPremisesFromParams()
        for sentence in sentences
          isCorrect = isCorrect and sentence.evaluate(counterexample)
        if isCorrect
          # conclusion must be false in the counterexample
          conclusion = ix.getConclusionFromParams() 
          isCorrect = isCorrect and not conclusion.evaluate(counterexample)
          unless isCorrect
            comment = "You did make the premises true. But can you also make the conclusion false?"
        else
          comment = "The premises are not all true.  Can you make the premises true?"
    machineFeedback = { isCorrect, comment }
    ix.submitExercise({
        answer : 
          type : 'counter'
          content : {counterexample:counterexample}
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your possible situation has been submitted.", 4000
    )
  


