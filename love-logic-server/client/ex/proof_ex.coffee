# Work in progress will be saved in the session and in WorkInProgress.
# (Should we only save it in the session?  And could make session persistent?)
# Note: the session is used in two ways: the key `codeMirrorContent` contains 
# the current values of the editor (and is constantly updated by the CodeMirror component);
# the key that is the value of `ix.getExerciseId()` contains the student’s current answer.
# TODO: move saving work in progress to the codemirror template.
if ix.getExerciseId()
  Session.setDefault(ix.getExerciseId(), '')

# We will store the editor here.
# TODO: this is not initialised on first page load!
# (Will be fine once logic is moved to the template?)
editorObj = {}

# -------------
# Subscriptions and setup the editor




Template.proof_ex.onCreated () ->
  self = this
  self.autorun () ->
    # We need this to ensure the CodeMirror thing gets updated.
    FlowRouter.watchPathChange()
    
    courseName = FlowRouter.getQueryParam 'courseName'
    variant = FlowRouter.getQueryParam 'variant'
    self.subscribe 'exercise_set', courseName, variant
    exerciseId = ix.getExerciseId()
    self.subscribe 'submitted_exercise', exerciseId
    self.subscribe 'work_in_progress', exerciseId, ()  ->
      Session.set("codeMirrorContent", getEditorInitialText())
      Meteor.defer () ->
        if editorObj.editor? and not editorObj.initDone
          initCodemirrorEditor()

# -------------
# Template helpers

# Extract premises from the URL.  Remove any premises which are `true`
# (so you can set proofs with no premises).  Add an error if any 
# sentences cannot be parsed.
# Return a list of awFOL objects.
getPremisesFromParams = () ->
  _premises = FlowRouter.getParam('_premises')
  txtList = decodeURIComponent(_premises).split('|')
  try
    folList = (fol.parse(t) for t in txtList)
  catch e
    return ["Sorry, there is an error with the URL you gave (#{e})."]
  folList = (e for e in folList when not (e.type is 'value' and e.value is true))
  return folList

# Extract the conclusion from the URL.
# Return it as an awFOL object.
getConclusionFromParams = () ->
  _conclusion = FlowRouter.getParam('_conclusion')
  try
    e = fol.parse(decodeURIComponent(_conclusion))
  catch error
    return "Sorry, there is an error with the URL you gave (#{error})."
  return e

# Extract the proof to be written from the params.  
getProofFromParams = () ->
  premiseTxt = (t.toString({replaceSymbols:true}) for t in getPremisesFromParams()).join('\n| ')
  conclusionTxt = getConclusionFromParams().toString({replaceSymbols:true})
  return "| #{premiseTxt}\n|---\n| \n| \n| #{conclusionTxt}"  
  



initCodemirrorEditor = () ->
  editor = editorObj.editor
  return unless editor

  editor.on("keyHandled", (instance, name, event) ->
    if name in ['Up']
      lineNumber = getCurrentLineNumberInEditor(editor) 
      ix.saveWorkInProgress(editor.getValue())
      checkLines(lineNumber, lineNumber+1, editor)
    if name in ['Down','Enter']
      lineNumber = getCurrentLineNumberInEditor(editor) 
      ix.saveWorkInProgress(editor.getValue())
      checkLines(lineNumber, lineNumber-1, editor)
  )
  editorObj.initDone = true

getEditorInitialText = () ->
  proofFromParams = getProofFromParams()
  proofText  =  Session.get(ix.getExerciseId())
  if proofText and proofText.trim() isnt ''
    console.log "proof from session"
    return proofText
  else
    wip = ix.getWorkInProgress()
    if wip?.text?
      console.log "proof from wip"
      return wip.text
    else
      console.log "proof from `getProofFromParams()`"
      return proofFromParams

Template.proof_ex.helpers
  conclusion : () ->
    return getConclusionFromParams().toString({replaceSymbols:true})
  premises : () -> 
    folList = getPremisesFromParams()
    return (e.toString({replaceSymbols:true}) for e in folList)
  hasPremises : () -> 
    return getPremisesFromParams()?.length > 0

  # Helpers for the CodeMirror editor
  editorOptions : () ->
    return {
      theme : 'blackboard'
      smartIndent : true
      tabSize : 2
      lineNumbers : true
      autofocus : true
      matchBrackets : true
      gutters : ["error-light"]
    }
  # This is a crude hack so we can update the editor object
  # from this template (TODO: )
  getEditorObj : () ->
    return editorObj
    
  # Helpers that are common to several templates
  isSubmitted : () ->
    return ix.isSubmitted()
  dateSubmitted : () ->
    return ix.dateSubmitted()
  isMachineFeedback : () ->
    return ix.getSubmission().machineFeedback?
  machineFeedback : () ->
    return ix.getSubmission().machineFeedback.comment
    
  # Helpers relating to ExerciseSets that are common to several templates
  courseName : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return ctx.exerciseSet.courseName
  variant : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return ctx.exerciseSet.variant
  unitTitle : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return ctx.unit.name
  slidesForThisUnit : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return ctx.unit.slides
  readingForThisUnit : () ->
    ctx = ix.getExerciseContext()
    return '' unless ctx
    return "Sections §#{ctx.unit.rawReading.join(', §')} of Language, Proof and Logic"
  isNextExercise : () ->
    ctx = ix.getExerciseContext()
    return ctx?.next?
    

    
    
    
      
# -------------
# User interactions

# Extract the proof from the editor and parse it.
getProof = () ->
  proofText = getEditorText()
  theProof = proof.parse(proofText)
  return theProof

# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")

getCurrentLineNumberInEditor = (editor) ->
  {line, ch} = editor.getCursor()
  lineNumber = line+1
  return lineNumber

checkLines = (currentLineNumber, prevLineNumber, editor) ->
  # Save the proof in the session.
  Session.set(ix.getExerciseId(), getEditorText())
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
  addMarker(prevLineNumber, 'chartreuse', editor) if prevLineIsCorrect
  addMarker(prevLineNumber, '#FF3300', editor) if not prevLineIsCorrect

# Make a dot to show whether a line of the proof is correct.
addMarker = (lineNumber, color = "#822", editor) ->
  if not editor?
    editor = editorObj.editor
  marker = document.createElement("div")
  marker.style.color = color
  marker.style.marginLeft = '15px'
  marker.innerHTML = "●"
  # `-1` because `.setGutterMarker` expects 0-based line numbers
  editor.setGutterMarker(lineNumber-1, "error-light", marker)

setEditorText = (text) ->
  Session.set("codeMirrorContent", text)

getEditorText = () ->
  return Session.get("codeMirrorContent")
  
Template.proof_ex.onRendered () ->
  # configure the modal (uses http://materializecss.com/modals.html)
  $("#reset").leanModal()

Template.proof_ex.events
  'click button#checkProof' : (event, template) ->
    theProof = getProof()
    result = theProof.verify()
    giveFeedback "Is your proof correct? #{result}!"
    
    # Add the red/green dots to the proof
    for lineNumber in [1..getEditorText().split('\n').length]
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
    ix.submitExercise({
        answer : 
          type : 'proof'
          content : getEditorText()
        machineFeedback : machineFeedback
      }, () ->
        giveFeedback "Your proof has been submitted."
        Materialize.toast "Your proof has been submitted.", 4000
    )

  'click #view-answer' : (event, template) ->
    submission = ix.getSubmission()
    setEditorText(submission.answer.content)
  
  'click #reset-confirm' : (event, template) ->
    setEditorText( getProofFromParams() )
  
  'click .next-exercise' : (event, template) ->
    ctx = ix.getExerciseContext()
    return unless ctx?.next?
    qs = ix.queryString()
    if qs
      queryString = "?#{qs}"
    else
      queryString = ""
    FlowRouter.go("#{ctx.next}#{queryString}")
    
    


