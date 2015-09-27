# This is a collection of templates using CodeMirror editors that will save state
# It depends on `codemirror`
# Modified from https://github.com/perak/codemirror/blob/master/lib/component/component.js

# ====
# Functions used across several variants

# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")



# =======
# editSentence

# Enchanced for sentences of FOL: includes a feedback line and a `convert to symbols` button.
Template.editSentence.rendered = () ->
  o = @data.options or {}
  options = _.defaults o, {
    theme : 'blackboard'
    smartIndent : true
    tabSize : 2
    lineNumbers : false
    autofocus : true
    matchBrackets : true
  }
  textarea = @find('textarea')
  editor = CodeMirror.fromTextArea(textarea, options)
  
  # TODO: this should go? (Superflous given the autorun below)
  savedAnswer = ix.getAnswer()
  if savedAnswer? and savedAnswer.trim() isnt ''
    editor.setValue(savedAnswer)
  
  editor.on 'change', (doc) ->
    val = doc.getValue()
    textarea.value = val
    ix.setAnswer(val)
  
  # Allow the value of the editor to be updated by setting the session variable
  Tracker.autorun () ->
    # We need to `watchPathChange` so that the editor gets updated.
    FlowRouter.watchPathChange()
    val = ix.getAnswer() or ''
    if val != editor.getValue()
      # Clear feedback because the answer has been changed from outside
      giveFeedback ""     
      editor.setValue val
  
  
Template.editSentence.destroyed = () ->
  @$('textarea').parent().find('.CodeMirror').remove()
  return


Template.editSentence.helpers
  'editorId': () ->
    return @editorId or 'code-mirror-textarea'
  'defaultContent' : () ->
    return @defaultContent
  'sentenceIsAwFOL' : () ->
    # The value should be in the template data context (provided on invocation)
    return @sentenceIsAwFOL


Template.editSentence.events
  'click #convert-to-symbols' : (event, template) ->
    answer = Session.get(ix.getSessionKeyForUserExercise())
    try
      answerFOL = fol.parse( answer.replace(/\n/g,' ') )
    catch error
      giveFeedback "Your answer is not a correct sentence of awFOL. (#{error})"
      return
    giveFeedback ""
    ix.setAnswer( answerFOL.toString({replaceSymbols:true}) )






# =======
# editProof
# TODO: reduce duplication between this and editSentence



# Extract the proof from the editor and parse it.
getProof = () ->
  proofText = ix.getAnswer()
  theProof = proof.parse(proofText)
  return theProof

getCurrentLineNumberInEditor = (editor) ->
  {line, ch} = editor.getCursor()
  lineNumber = line+1
  return lineNumber

checkLines = (currentLineNumber, prevLineNumber, editor) ->
  theProof = getProof()
  # Are there errors in parsing the proof?
  if _.isString(theProof)
    giveFeedback theProof
    return
  aLine = theProof.getLine(currentLineNumber)
  lineIsCorrect = aLine.verify()
  giveFeedback "Line #{currentLineNumber}: #{("no errors found" if lineIsCorrect) or "not correct"}.  #{aLine.status.getMessage()}"
  prevLine = theProof.getLine(prevLineNumber)
  prevLineIsCorrect = prevLine.verify()
  addMarker(prevLineNumber, 'chartreuse', editor) if prevLineIsCorrect
  addMarker(prevLineNumber, '#FF3300', editor) if not prevLineIsCorrect

# Make a dot to show whether a line of the proof is correct.
addMarker = (lineNumber, color = "#822", editor) ->
  marker = document.createElement("div")
  marker.style.color = color
  marker.style.marginLeft = '15px'
  marker.innerHTML = "●"
  # `-1` because `.setGutterMarker` expects 0-based line numbers
  editor.setGutterMarker(lineNumber-1, "error-light", marker)



# Enchanced for sentences of FOL: includes a feedback line and a `convert to symbols` button.
# Also gets editor content from URL if not stored in session
Template.editProof.rendered = () ->
  o = @data.options or {}
  options = _.defaults o, {
    theme : 'blackboard'
    smartIndent : true
    tabSize : 2
    lineNumbers : true
    autofocus : true
    matchBrackets : true
    gutters : ["error-light"]
  }
  textarea = @find('textarea')
  editor = CodeMirror.fromTextArea(textarea, options)
  Template.instance().editor = editor
  savedAnswer = ix.getAnswer()
  if savedAnswer? and savedAnswer.trim() isnt ''
    editor.setValue(savedAnswer)
  
  editor.on 'change', (doc) ->
    val = doc.getValue()
    textarea.value = val
    ix.setAnswer(val)
  
  editor.on "keyHandled", (instance, name, event) ->
    if name in ['Up']
      lineNumber = getCurrentLineNumberInEditor(editor) 
      checkLines(lineNumber, lineNumber+1, editor)
    if name in ['Down','Enter']
      lineNumber = getCurrentLineNumberInEditor(editor) 
      checkLines(lineNumber, lineNumber-1, editor)
  
  $("#resetProof").leanModal()
  
  # Allow the value of the editor to be updated by setting the session variable
  Tracker.autorun ->
    # We need to `watchPathChange` so that the editor gets updated.
    FlowRouter.watchPathChange()
    val = ix.getAnswer() or ix.getProofFromParams() or ''
    if val != editor.getValue()
      # Clear feedback because the answer has been changed from outside
      giveFeedback ""
      editor.setValue val
  
  
Template.editProof.destroyed = () ->
  @$('textarea').parent().find('.CodeMirror').remove()
  return


Template.editProof.helpers
  'editorId': () ->
    return @editorId or 'code-mirror-textarea'
  'defaultContent' : () ->
    return @defaultContent
  'sentenceIsAwFOL' : () ->
    # The value should be in the template data context (provided on invocation)
    return @sentenceIsAwFOL
    
Template.editProof.events
  'click button#checkProof' : (event, template) ->
    proofText = ix.getAnswer()
    theProof = proof.parse(proofText)
    
    if _.isString theProof
      # The proof could not be parsed.
      giveFeedback "There is a problem with the formatting of your proof.  #{theProof}"
      return
    result = theProof.verify()
    giveFeedback "Is your proof correct? #{result}!"

    # Add the red/green dots to the proof
    for lineNumber in [1..ix.getAnswer().split('\n').length]
      line = theProof.getLine(lineNumber)
      lineIsCorrect = line.verify()
      addMarker(lineNumber, 'chartreuse', template.editor) if lineIsCorrect
      addMarker(lineNumber, '#FF3300', template.editor) if not lineIsCorrect
    
    # finally, check the premises and conclusion are correct
    result = ix.checkPremisesAndConclusionOfProof(theProof)
    if _.isString result
      giveMoreFeedback result
    
  'click #resetProof-confirm' : (event, template) ->
    giveFeedback ""
    ix.setAnswer( ix.getProofFromParams() )
    
