# Example URL:
# http://localhost:3000/ex/trans/domain/3things/names/a=thing-1%7Cb=thing-2/predicates/Fish1-x-is-a-fish%7CBetween3-xIsBetweenYAndZ%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish

Session.setDefault 'answer', ''

editor = undefined  #This will be our codemirror thing.

isTranslationToEn = false

# -------------
# Template helpers


checkIfTranslationToEn = () ->
  sentence = ix.getParams()._sentence
  try
    fol.parse sentence
    # If we can parse the sentence given, it is an awFOL sentence to be 
    # translated into English.
    return true
  catch error
    return false

# Predicates are like `Red1` (arity=1, uses the default descriptino)
# or `Between3-xIsBetweenYAndZ`
# or `Between3-x-is-between-y-and-z`
extractPredicteFromParam = (rawPredicate) ->
  parts = rawPredicate.split('-')
  firstBit = parts.shift()
  # Name is the awFOL name of the predicate
  name = firstBit[0..firstBit.length-2]
  # predicateName is the informal name used in the description
  arity = parseInt(firstBit[firstBit.length-1])
  # If any parts remain, use them to describe the predicate.
  if parts.length>0
    predicateDescription = parts.join(' ').replace(/([A-Z])/g, ' $1').toLowerCase().trim()
  else
    predicateName = name.replace(/([A-Z])/g, ' $1').toLowerCase().trim()
    predicateNameNofWords = name.split(' ').length
    predicateDescription = ("x is #{predicateName}" if arity is 1) 
    predicateDescription or= ("x is #{predicateName} y" if arity is 2 and predicateNameNofWords>1) 
    predicateDescription or=  ("x #{predicateName} y" if arity is 2 and predicateNameNofWords is 1) 
    predicateDescription or=  ("x is #{predicateName} y and z" if arity is 3  and predicateNameNofWords>1)
    predicateDescription or=  ("x #{predicateName} y to z" if arity is 3 and predicateNameNofWords is 1) 
  variables = ['x','y','z','z1','z2','z3','z4','z5','z6']
  description = "#{name}(#{variables[0..arity-1]}) : #{predicateDescription}"
  return {name, arity, description}

getPredicatesFromParams = () ->
  raw = ix.getParams()._predicates.split('|')
  predicates = (extractPredicteFromParam(p) for p in raw)
  return predicates

getDomainFromParams = () ->
  parts = ix.getParams()._domain.split('|')
  if parts.length > 1
    return parts
  raw = parts[0]
  checkFormat = raw.match /^([0-9]+)([\s\S]*?)(s?)$/
  if checkFormat is null
    return [raw]
  [_ignore, number, type, _plural] = checkFormat
  return ("#{type}-#{i}" for i in [1..number])
  
Template.trans_ex.helpers
  exTitle : () -> 
    if checkIfTranslationToEn()
      return "Translate awFOL to English"
    return "Translate English to awFOL"
  predicates : () -> getPredicatesFromParams()
  sentence : () -> 
    if checkIfTranslationToEn()
      return fol.parse(ix.getParams()._sentence).toString({replaceSymbols:true})
    return "#{ix.getParams()._sentence}."
  domain : () -> getDomainFromParams()
  names : () -> ix.getParams()._names.replace(/\=/g,' : ').split('|')

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

# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")

checkAnswer = () ->
  # Save the answer in the session.
  rawAnswer = editor.getValue()
  Session.set 'answer', rawAnswer
  if not isTranslationToEn
    try 
      answer = fol.parse( rawAnswer.replace(/\n/g,' ') )
    catch error
      giveFeedback "Your answer is not a correct sentence of awFOL. (#{error})"
      return
    giveFeedback ""
  
  


Template.trans_ex.onRendered () ->
  # Configure the editor
  editor = CodeMirror.fromTextArea($('#editor')[0], {
    theme : 'blackboard'
    smartIndent : true
    tabSize : 2
    lineNumbers : false
    autofocus : true
    matchBrackets : true
  })
  answer  =  Session.get 'answer'
  editor.setValue(answer)

  isTranslationToEn = checkIfTranslationToEn()

  editor.on "keyHandled", (instance, name, event) ->
    if name in ['Down','Up','Enter']
      checkAnswer()

