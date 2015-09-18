# TODO: configure so that work in progress is saved.
Session.setDefault 'proofText', ''

editor = undefined  #This will be our codemirror thing.


# -------------
# Template helpers

# Extract premises from the URL.  Remove any premises which are `true`
# (so you can set proofs with no premises).  Add an error if any 
# sentences cannot be parsed.
# Return a list of awFOL objects.
getPremisesFromParams = () ->
  params = ix.getParams()
  txtList = decodeURIComponent(params._premises).split('|')
  try
    folList = (fol.parse(t) for t in txtList)
  catch e
    return ["Sorry, there is an error with the URL you gave (#{e})."]
  folList = (e for e in folList when not (e.type is 'value' and e.value is true))
  return folList

# Extract the conclusion from the URL.
# Return it as an awFOL object.
getConclusionFromParams = () ->
  params = ix.getParams()
  try
    e = fol.parse(decodeURIComponent(params._conclusion))
  catch error
    return "Sorry, there is an error with the URL you gave (#{error})."
  return e

# Extract the proof to be written from the params.  
getProofFromParams = () ->
  premiseTxt = (t.toString({replaceSymbols:true}) for t in getPremisesFromParams()).join('\n| ')
  conclusionTxt = getConclusionFromParams().toString({replaceSymbols:true})
  return "| #{premiseTxt}\n|---\n| \n| \n| #{conclusionTxt}"  
  

Template.proof_ex.helpers
  conclusion : () ->
    return getConclusionFromParams().toString({replaceSymbols:true})
  premises : () -> 
    folList = getPremisesFromParams()
    return (e.toString({replaceSymbols:true}) for e in folList)
  textareaText : () ->
    return getProofFromParams()
  
  # Helpers that are common to several templates
  isSubmitted : () ->
    return ix.isSubmitted()
  dateSubmitted : () ->
    return ix.dateSubmitted()
  isMachineFeedback : () ->
    return ix.getSubmission().machineFeedback?
  machineFeedback : () ->
    return ix.getSubmission().machineFeedback.comment
    
    
      
# -------------
# User interactions

# Extract the proof from the editor and parse it.
getProof = () ->
  proofText = editor.getValue()
  theProof = proof.parse(proofText)
  return theProof

# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")

getCurrentLineNumberInEditor = () ->
  {line, ch} = editor.getCursor()
  lineNumber = line+1
  return lineNumber

checkLines = (currentLineNumber, prevLineNumber) ->
  # Save the proof in the session.
  Session.set 'proofText', editor.getValue()
  theProof = getProof()
  # Are there errors in parsing the proof?
  if _.isString(theProof)
    $('#feedback').text(theProof)
    return
  aLine = theProof.getLine(currentLineNumber)
  lineIsCorrect = aLine.verify()
  giveFeedback "Line #{currentLineNumber}: #{("no errors found" if lineIsCorrect) or "not correct"}.  #{aLine.status.getMessage()}"
  prevLine = theProof.getLine(prevLineNumber)
  prevLineIsCorrect = prevLine.verify()
  addMarker(prevLineNumber, 'chartreuse') if prevLineIsCorrect
  addMarker(prevLineNumber, '#FF3300') if not prevLineIsCorrect

# Make a dot to show whether a line of the proof is correct.
addMarker = (lineNumber, color = "#822") ->
  marker = document.createElement("div")
  marker.style.color = color
  marker.style.marginLeft = '15px'
  marker.innerHTML = "●"
  # `-1` because `.setGutterMarker` expects 0-based line numbers
  editor.setGutterMarker(lineNumber-1, "error-light", marker)


Template.proof_ex.onRendered () ->
  # configure the modal (uses http://materializecss.com/modals.html)
  $("#reset").leanModal()
  # Configure the editor
  editor = CodeMirror.fromTextArea($('#editor')[0], {
    theme : 'blackboard'
    smartIndent : true
    tabSize : 2
    lineNumbers : true
    autofocus : true
    matchBrackets : true
    gutters : ["error-light"]
  })
  proofText  =  Session.get 'proofText'
  if proofText and proofText isnt ''
    editor.setValue(proofText)
  wip = ix.getWorkInProgress()
  if wip?.text?
    console.log "got wip"
    editor.setValue(wip.text)

  editor.on("keyHandled", (instance, name, event) ->
    if name in ['Up']
      lineNumber = getCurrentLineNumberInEditor() 
      ix.saveWorkInProgress(editor.getValue())
      checkLines(lineNumber, lineNumber+1)
    if name in ['Down','Enter']
      lineNumber = getCurrentLineNumberInEditor() 
      ix.saveWorkInProgress(editor.getValue())
      checkLines(lineNumber, lineNumber-1)
  )


Template.proof_ex.events
  'click button#checkProof' : (event, template) ->
    theProof = getProof()
    result = theProof.verify()
    giveFeedback "Is your proof correct? #{result}!"
    
    # Add the red/green dots to the proof
    for lineNumber in [1..editor.getValue().split('\n').length]
      line = theProof.getLine(lineNumber)
      lineIsCorrect = line.verify()
      addMarker(lineNumber, 'chartreuse') if lineIsCorrect
      addMarker(lineNumber, '#FF3300') if not lineIsCorrect
    
    # Now check the conclusion is what its supposed to be.
    conclusionIsOk = theProof.getConclusion().isIdenticalTo( getConclusionFromParams() )
    if not conclusionIsOk 
      giveMoreFeedback "#{('And' unless result) or 'But'} your conclusion (#{theProof.getConclusion()}) is not the one you were supposed to prove (#{getConclusionFromParams()})."
    # Finally, check no premises other than those stipulated have been used (but
    # you don't have to use the premises given.)
    proofPremises = theProof.getPremises()
    proofPremisesStr = (p.toString({replaceSymbols:true}) for p in proofPremises)
    actualPremisesList = (p.toString({replaceSymbols:true}) for p in getPremisesFromParams())
    proofPremisesNotInActualPremises = _.difference proofPremisesStr, actualPremisesList
    premisesAreOk = proofPremisesNotInActualPremises.length is 0
    if not premisesAreOk
      giveMoreFeedback "#{('And' unless result or not conclusionIsOk) or 'But'} your premises (#{proofPremisesStr.join(', ')}) are not the ones you were supposed to start from---you added #{proofPremisesNotInActualPremises.join(', ')}."
      
    
  'click button#submit' : (event, template) ->
    theProof = getProof()
    result = theProof.verify()
    machineFeedback = {
      isCorrect : result
      comment : "Your submitted proof is #{('not' if result isnt true) or ''} correct."
    }
    ix.submitExercise(
      answer : 
        type : 'proof'
        content : editor.getValue()
      machineFeedback : machineFeedback
    )
    giveFeedback "Your proof has been submitted."
    Materialize.toast "Your proof has been submitted.", 4000

  'click #view-answer' : (event, template) ->
    submission = ix.getSubmission()
    editor.setValue(submission.answer.content)
  
  'click #reset-confirm' : (event, template) ->
    editor.setValue( getProofFromParams() )
    


