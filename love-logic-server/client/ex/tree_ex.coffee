# TODO
# have paths like /ex/tree/require/complete/from/...
#                 /ex/tree/require/counterexample/from/...
#                 /ex/tree/require/closed/from/...


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
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")

getConclusionAsText = () ->
  FlowRouter.watchPathChange()
  ix.setDialectFromExerciseSet()
  return ix.getConclusionFromParams()?.toString({replaceSymbols:true})
getPremisesAsText = () ->
  FlowRouter.watchPathChange()
  folList = ix.getPremisesFromParams() or []
  ix.setDialectFromExerciseSet()
  return (e.toString({replaceSymbols:true}) for e in folList)

displayTreeProofEditable = (treeProof) ->
  doWhenTreeUpdates = () ->
    ix.setAnswerKey(treeProof.toBareTreeProof(), 'tree')
  treeProof.displayEditable('#treeEditor', doWhenTreeUpdates)


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
        treeProof = tree.makeTreeProof('')
      displayTreeProofEditable(treeProof)
    return 'loading'


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
  stateIfValid : (treeProof) ->
    # assumes `complete` is also a requirement
    # TODO!!!
    return {isCorrect: false, errorMessage: "[This function is not implemented yet]"}
  stateIfConsistent : (treeProof) ->
    # assumes `complete` is also a requirement
    # TODO!!!
    return {isCorrect: false, errorMessage: "[This function is not implemented yet]"}

Template.tree_ex_display_question.helpers
  conclusion : getConclusionAsText
  premises : getPremisesAsText
  hasPremises : () -> 
    FlowRouter.watchPathChange()
    return ix.getPremisesFromParams(@)?.length > 0
  requireComplete : () -> 'complete' in getRequirements()
  requireClosed : () -> 'closed' in getRequirements()
  requireStateIfValid : () -> 'stateIfValid' in getRequirements()
  
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
    
    
    
      
# -------------
# User interactions

submitEx = (treeProof, machineFeedback) ->
  doc = {
    answer : 
      type : 'tree'
      content : {tree:treeProof.toBareTreeProof()}
    machineFeedback : machineFeedback
  }
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
    
    for r in getRequirements()
      test = reqCheckers[r](treeProof)
      console.log test
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
          treeProof = tree.makeTreeProof('')
          displayTreeProofEditable(treeProof)


