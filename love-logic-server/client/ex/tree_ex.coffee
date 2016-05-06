# TODO
# have paths like /ex/tree/require/complete/from/...
#                 /ex/tree/require/counterexample/from/...
#                 /ex/tree/require/closed/from/...
#
# Allow that  /from/... as well as /setMembers/...
#
# Check that premises and conclusion of the tree proof are correct,
# or that the setMembers specified in the URL are the only ones in the proof.
#
# Figure out how to make it work with dialects (verify must use the 
# tree proof rules!)

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
  return ix.getConclusionFromParams(@)?.toString({replaceSymbols:true})
getPremisesAsText = () ->
  FlowRouter.watchPathChange()
  folList = ix.getPremisesFromParams(@) or []
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
    
Template.tree_ex_display_question.helpers
  conclusion : getConclusionAsText
  premises : getPremisesAsText
  hasPremises : () -> 
    FlowRouter.watchPathChange()
    return ix.getPremisesFromParams(@)?.length > 0
  
Template.tree_ex_display_answer.helpers
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
    if isCorrect
      machineFeedback = 
        comment : "Your submitted tree proof does not contain any errors."
    else
      machineFeedback = 
        isCorrect : false
        comment : "Your submitted tree proof is not correct. #{errorMessages}"
    doc = {
      answer : 
        type : 'tree'
        content : {tree:treeProof.toBareTreeProof()}
      machineFeedback : machineFeedback
    }
    dialectNameAndVersion = fol.getCurrentDialectNameAndVersion()
    if dialectNameAndVersion?
      doc.answer.content.dialectName = dialectNameAndVersion.name
      doc.answer.content.dialectVersion = dialectNameAndVersion.version
    ix.submitExercise(doc, () ->
        Materialize.toast "Your tree proof has been submitted.", 4000
    )
  
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


Template.tree_ex_display_answer.helpers
  proofRulesName : () -> "#{@answer.content.dialectName or '[unspecified]'} (version #{@answer.content.dialectVersion})"
