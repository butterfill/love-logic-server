
editor = undefined  #This will be our codemirror thing.

# Extract premises from the URL.  Remove any premises which are `true`
# (so you can set proofs with no premises).  Add an error if any 
# sentences cannot be parsed.
# Return a list of awFOL objects.
getPremises = () ->
  controller = Iron.controller()
  params = controller.getParams()
  txtList = decodeURIComponent(params._premises).split('|')
  try
    folList = (fol.parse(t) for t in txtList)
  catch e
    return ["Sorry, there is an error with the URL you gave (#{e})."]
  folList = (e for e in folList when not (e.type is 'value' and e.value is true))
  return folList

# Extract the conclusion from the URL.
# Return it as an awFOL object.
getConclusion = () ->
  controller = Iron.controller()
  params = controller.getParams()
  try
    e = fol.parse(decodeURIComponent(params._conclusion))
  catch error
    return "Sorry, there is an error with the URL you gave (#{error})."
  return e

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

checkLine = (lineNumber) ->
  theProof = getProof()
  # Are there errors in parsing the proof?
  if _.isString(theProof)
    $('#feedback').text(theProof)
    return
  aLine = theProof.getLine(lineNumber)
  result = aLine.verify()
  giveFeedback "Is line (#{lineNumber}) correct? #{result}!  #{aLine.status.getMessage()}"


Template.proof.helpers
  conclusion : () ->
    return getConclusion().toString({replaceSymbols:true})
  premises : () -> 
    folList = getPremises()
    return (e.toString({replaceSymbols:true}) for e in folList)
  textareaText : () ->
    premiseTxt = (t.toString({replaceSymbols:true}) for t in getPremises()).join('\n| ')
    conclusionTxt = getConclusion().toString({replaceSymbols:true})
    return "| #{premiseTxt}\n|---\n| \n| \n| #{conclusionTxt}"
    
      

Template.proof.onRendered () ->
  # Configure the editor
  editor = CodeMirror.fromTextArea($('#editor')[0], {
    theme : 'blackboard'
    smartIndent : true
    tabSize : 2
    lineNumbers : true
    autofocus : true
    matchBrackets : true
  })
  editor.on("keyHandled", (instance, name, event) ->
    if name in ['Down','Up']
      lineNumber = getCurrentLineNumberInEditor() 
      checkLine(lineNumber)
    if name in ['Enter']
      lineNumber = getCurrentLineNumberInEditor() - 1
      checkLine(lineNumber)
  )


Template.proof.events
  'click button#checkLine' : (event, template) ->
    lineNumber = getCurrentLineNumberInEditor()
    checkLine(lineNumber)
    
  'click button#checkProof' : (event, template) ->
    theProof = getProof()
    result = theProof.verify()
    giveFeedback "Is your proof correct? #{result}!"
    # Now check the premises and conclusion match.
    conclusionIsOk = theProof.getConclusion().isIdenticalTo( getConclusion() )
    if not conclusionIsOk 
      giveMoreFeedback "But your conclusion (#{theProof.getConclusion()}) is not the one you were supposed to prove (#{getConclusion()})."
      return undefined
    proofPremises = theProof.getPremises()
    proofPremisesStr = (p.toString({replaceSymbols:true}) for p in proofPremises)
    actualPremisesList = (p.toString({replaceSymbols:true}) for p in getPremises())
    premisesAreOk = false
    if not premisesAreOk
      giveMoreFeedback "#{('And' unless result) or 'But'} your premises (#{proofPremisesStr}) are not the ones you were supposed to start from (#{actualPremisesList})."
      
    
  'click button#submit' : (event, template) ->
    giveFeedback "Error submitting your proof (method not written yet)."



