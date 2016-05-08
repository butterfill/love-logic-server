

Template.tree_ex.onCreated () ->
  self=this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

  
# -------------
# Template helpers

giveFeedback = (message) ->
  $('#feedback').text(message)

getConclusionAsText = () ->
  FlowRouter.watchPathChange()
  ix.setDialectFromExerciseSet()
  return ix.getConclusionFromParams()?.toString({replaceSymbols:true})
getPremisesAsText = () ->
  FlowRouter.watchPathChange()
  folList = ix.getPremisesFromParams() or []
  ix.setDialectFromExerciseSet()
  return (e.toString({replaceSymbols:true}) for e in folList)
getSentencesAsText = () ->
  FlowRouter.watchPathChange()
  folList = ix.getSentencesFromParam() or []
  ix.setDialectFromExerciseSet()
  return (e.toString({replaceSymbols:true}) for e in folList)
getTreeFromParams = () ->
  ss = getSentencesAsText()
  if ss.length is 0
    prfTxt = ''
  else
    prfTxt = ("#{s}    SM" for s in ss).join('\n')
  return tree.makeTreeProof(prfTxt)


# `bareTreeInEditor` will help us keep track of which tree is in the editor
# so we know when to re-draw on `ix.setAnswer(...` happening
bareTreeInEditor = undefined
displayTreeProofEditable = (treeProof) ->
  if treeProof.displayEditable?
    bareTreeInEditor = treeProof.toBareTreeProof()
  else
    bareTreeInEditor = treeProof
    treeProof = tree.decorateTreeProof( _.clone(treeProof) )
  doWhenTreeUpdates = () ->
    bareTreeInEditor = treeProof.toBareTreeProof()
    ix.setAnswerKey(bareTreeInEditor, 'tree')
  treeProof.displayEditable('#treeEditor', doWhenTreeUpdates)


Template.tree_ex.onRendered () ->
  # Allow the value of the tree editor to be updated by setting the session 
  # variable. (This is necessary for the `load answer` button to work.)
  @autorun ->
    FlowRouter.watchPathChange()
    answerTreeProof = ix.getAnswer()?.tree or getTreeFromParams()
    if answerTreeProof?
      unless answerTreeProof is bareTreeInEditor
        if tree.areDistinctProofs(answerTreeProof, bareTreeInEditor)
          # console.log "answerTreeProof autorun re-drawing tree!"
          displayTreeProofEditable(answerTreeProof)
          # Clear feedback because the answer has been changed from outside
          giveFeedback ""


Template.tree_ex.helpers
  # WARNING: has DOM side effects (uses Treant to update DOM)
  displayEditableTreeInDiv : () ->
    Meteor.defer () ->
      # premises = getPremisesAsText()
      # conclusion = getConclusionAsText()
      oldTree = ix.getAnswer()?.tree
      if oldTree?
        treeProof = tree.decorateTreeProof(oldTree)
      else
        treeProof = getTreeFromParams()
      displayTreeProofEditable(treeProof)
    return 'loading'
  requireStateIfValid : () -> 'stateIfValid' in getRequirements()
  requireStateIfConsistent : () -> 'stateIfConsistent' in getRequirements()
  stateIfValidSentences : () -> 
    answerTorF = ix.getAnswer()?.TorF?[0]
    return [{theSentence:'The argument is logically valid.', idx:0, value:"#{answerTorF}"}]
  stateIfConsistentSentences : () -> 
    answerTorF = ix.getAnswer()?.TorF?[0]
    return [{theSentence:'The sentences are logically consistent.', idx:0, value:"#{answerTorF}"}]
    

getRequirements = () -> FlowRouter.getParam('_requirements').split('|')
# These functions will be called on submission to check
# that the requirements specified in the `exerciseId` are met.
# Keys are the values of the `:_requirements` route parameter.
reqCheckers =
  complete : (treeProof) ->
    test = treeProof.areAllBranchesClosedOrOpen()
    if test
      return {isCorrect: true}
    else
      return {isCorrect: false, errorMessage: "your tree proof is not complete (remember to mark all branches open or closed)."}
  closed : (treeProof) ->
    test = treeProof.areAllBranchesClosed()
    if test
      return {isCorrect: true}
    else
      return {isCorrect: false, errorMessage: "your tree proof is not closed (remember to mark all closed branches closed)."}
  closedOrCompleteOpenBranch : (treeProof) ->
    if treeProof.areAllBranchesClosed() or treeProof.hasOpenBranch()
      return {isCorrect: true}
    else
      return {isCorrect: false, errorMessage: "your tree proof does not have a complete open branch nor are all branches closed (remember to mark branches open or closed)."}
  stateIfValid : (treeProof, answerSaysLogicallyValid) ->
    {isCorrect, errorMessage} = reqCheckers.closedOrCompleteOpenBranch(treeProof)
    unless isCorrect
      return {isCorrect, errorMessage}
    isActuallyValid = treeProof.areAllBranchesClosed()
    unless answerSaysLogicallyValid == isActuallyValid
      return {isCorrect: false, errorMessage: "you did not answer the question about logical validity correctly."}
    return {isCorrect:true}
  stateIfConsistent : (treeProof, answerSaysLogicallyConsistent) ->
    {isCorrect, errorMessage} = reqCheckers.closedOrCompleteOpenBranch(treeProof)
    unless isCorrect
      return {isCorrect, errorMessage}
    isActuallyConsistent = not treeProof.areAllBranchesClosed()
    unless answerSaysLogicallyConsistent == isActuallyConsistent
      return {isCorrect: false, errorMessage: "you did not answer the question about logical consistency correctly."}
    return {isCorrect:true}

Template.tree_ex_display_question.helpers
  isForArgument : () -> ix.getConclusionFromParams()?
  conclusion : getConclusionAsText
  premises : getPremisesAsText
  theSentences : () -> getSentencesAsText().join('; ')
  hasPremises : () -> 
    FlowRouter.watchPathChange()
    return ix.getPremisesFromParams(@)?.length > 0
  requireComplete : () -> 'complete' in getRequirements()
  requireClosed : () -> 'closed' in getRequirements()
  requireStateIfValid : () -> 'stateIfValid' in getRequirements()
  requireStateIfConsistent : () -> 'stateIfConsistent' in getRequirements()
  
Template.tree_ex_display_answer.helpers
  dialect : () -> "#{@answer.content.dialectName or '[unspecified]'} (version #{@answer.content.dialectVersion})"
  answerId : () -> 
    res = @._id?._str or @._id
    console.log res
    return res
  # WARNING: has DOM side effects (uses Treant to update DOM)
  displayStaticAnswerInDiv : () ->
    containerId = @._id?._str or @._id
    self = @
    Meteor.defer () ->
      treeProof = self.answer.content.tree
      return unless treeProof?
      tree.decorateTreeProof(treeProof)
      treeProof.convertToSymbols().displayStatic("##{containerId}")
    return 'loading'
  
  requireStateIfValid : () -> 'stateIfValid' in getRequirements()
  requireStateIfConsistent : () -> 'stateIfConsistent' in getRequirements()
  stateIfValidSentences : () -> 
    answerTorF = @answer.content?.TorF?[0]
    return [{theSentence:'The argument is logically valid.', idx:0, value:"#{answerTorF}"}]
  stateIfConsistentSentences : () -> 
    answerTorF = @answer.content?.TorF?[0]
    return [{theSentence:'The sentences are logically consistent.', idx:0, value:"#{answerTorF}"}]
  
    
    
      
# -------------
# User interactions

submitEx = (treeProof, machineFeedback) ->
  doc = {
    answer : 
      type : 'tree'
      content : {tree:treeProof.toBareTreeProof()}
    machineFeedback : machineFeedback
  }
  if ix.getAnswer()?.TorF?
    doc.answer.content.TorF = ix.getAnswer().TorF
  ix.submitExercise(doc, () ->
      Materialize.toast "Your tree proof has been submitted.", 4000
  )


Template.tree_ex.events

  'click #convert-to-symbols' : (event, template) ->
    oldTree = ix.getAnswer()?.tree
    return unless oldTree?
    newTree = tree.decorateTreeProof(oldTree).convertToSymbols()
    ix.setAnswerKey(newTree.toBareTreeProof(), 'tree')
    displayTreeProofEditable(newTree)
  
    
  # The html is in the `submit_btn` template
  'click #submit' : (event, template) ->
    treeProof = ix.getAnswer()?.tree
    unless treeProof?
      Materialize.toast "Error: your tree proof appears to be empty.", 4000
    tree.decorateTreeProof(treeProof)
    machineFeedback = undefined
    {isCorrect, errorMessages} = treeProof.verify()
    unless isCorrect
      machineFeedback = 
        isCorrect : false
        comment : "Your submitted tree proof is not correct. #{errorMessages}"
      return submitEx(treeProof, machineFeedback)
    
    # Check premises / set members are as specified in the question:
    conclusion = ix.getConclusionFromParams()
    if conclusion?
      # The exercise involves an argument.
      allowedPremises = ix.getPremisesFromParams()
      allowedPremises.push( conclusion.negate() )
    else
      # The exercise specifies set members.
      allowedPremises = ix.getSentencesFromParam()
    test = ix.checkPremisesOfProofAreThePremisesAllowed(treeProof, allowedPremises)
    if _.isString(test)
      machineFeedback = 
        isCorrect : false
        comment : "Your submitted tree proof is correct. But you used premises which you are not allowed to use in this question."
      return submitEx(treeProof, machineFeedback)
    
    answerTorF = ix.getAnswer()?.TorF?[0]
    for r in getRequirements()
      test = reqCheckers[r](treeProof, answerTorF)
      unless test.isCorrect
        machineFeedback = 
          isCorrect : false
          comment : "There are no errors in your tree proof.  But #{test.errorMessage}"
        return submitEx(treeProof, machineFeedback)
        
    machineFeedback = 
      isCorrect : true
      comment : "Your answer is correct."
    return submitEx(treeProof, machineFeedback)
  
  'click #checkProof' : (event, template) ->
    treeProof = ix.getAnswer()?.tree
    return unless treeProof?
    tree.decorateTreeProof(treeProof)
    {isCorrect, errorMessages} = treeProof.verify()
    if isCorrect
      giveFeedback('Your tree proof is correct.')
    else
      giveFeedback("Your tree proof is not correct. #{errorMessages}")
    
  'click #resetProof' : (event, template) ->
    MaterializeModal.confirm
      title : "Reset your work on this tree proof"
      message : "Do you want to start again?"
      callback : (error, response) ->
        if response.submit
          giveFeedback ""
          ix.setAnswerKey( getTreeFromParams(), 'tree')
          # treeProof = tree.makeTreeProof('')
          # displayTreeProofEditable(treeProof)


