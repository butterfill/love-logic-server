# Example URL:
# http://localhost:3000/ex/trans/domain/3things/names/a=thing-1%7Cb=thing-2/predicates/Fish1-x-is-a-fish%7CBetween3-xIsBetweenYAndZ%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish

editor = undefined  #This will be our codemirror thing.

# This will be configured `.onRender`
isTranslationToEn = false


# ========
# Template: trans_ex_display_question
# (This is a fragment that is used both for students and graders)

Template.trans_ex_display_question.helpers
  isTranslationToEn : () ->
    return checkIfTranslationToEn()
  predicates : () -> getPredicatesFromParams()
  sentence : () -> 
    if checkIfTranslationToEn()
      return fol.parse(decodeURIComponent(FlowRouter.getParam('_sentence'))).toString({replaceSymbols:true})
    return "#{decodeURIComponent(FlowRouter.getParam('_sentence'))}."
  domain : () -> getDomainFromParams()
  names : () -> decodeURIComponent(FlowRouter.getParam('_names')).replace(/\=/g,' : ').split('|')


checkIfTranslationToEn = () ->
  sentence = decodeURIComponent(FlowRouter.getParam('_sentence'))
  try
    fol.parse sentence
    # If we can parse the sentence given, it is an awFOL sentence to be 
    # translated into English.
    return true
  catch error
    return false

getPredicatesFromParams = () ->
  raw = decodeURIComponent(FlowRouter.getParam('_predicates')).split('|')
  predicates = (extractPredicteFromParam(p) for p in raw)
  return predicates

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

getDomainFromParams = () ->
  parts = decodeURIComponent(FlowRouter.getParam('_domain')).split('|')
  if parts.length > 1
    return parts
  raw = parts[0]
  checkFormat = raw.match /^([0-9]+)([\s\S]*?)(s?)$/
  if checkFormat is null
    return [raw]
  [_ignore, number, type, _plural] = checkFormat
  return ("#{type}-#{i}" for i in [1..number])




# ========
# Template: trans_ex

# -------------
# User interactions


getAnswer = () ->
  return Session.get(ix.getSessionKeyForUserExercise())

isAnswerFOLsentence = () ->
  rawAnswer = ix.getAnswer()
  try 
    answer = fol.parse( rawAnswer.replace(/\n/g,' ') )
    return true
  catch error
    return false

getAnswerAsFOLsentence = () ->
  rawAnswer = ix.getAnswer()
  try 
    answer = fol.parse( rawAnswer.replace(/\n/g,' ') )
    return answer
  catch error
    return undefined


Template.trans_ex.onCreated () ->
  self = this
  @autorun () ->
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

Template.trans_ex.onRendered () ->
  isTranslationToEn = checkIfTranslationToEn()

Template.trans_ex.helpers 
  'sentenceIsAwFOL' : () ->
    return not checkIfTranslationToEn()
    
Template.trans_ex.events 
  'click button#submit' : (event, template) ->
    answer = ix.getAnswer()
    
    doc = {
      answer : 
        type : 'trans'
        content : answer
    }
    
    answerShouldBeEnglish = checkIfTranslationToEn()
    if answerShouldBeEnglish
      
      # Try to get human feedback from the grade and comments on a previous student’s answer.
      humanFeedback = ix.gradeUsingGradedAnswers()
      if humanFeedback?
        doc.humanFeedback = humanFeedback
        
      ix.submitExercise(doc, () ->
          Materialize.toast "Your translation has been submitted.", 4000
      )
      return
      
    isFOLsentence = isAnswerFOLsentence()
    answerFOLstring = undefined
    answerPNFSimplifiedSorted = undefined
    machineFeedback = {
      isFOLsentence : isFOLsentence
    }
    if machineFeedback.isFOLsentence
      answerFOLobject = getAnswerAsFOLsentence()
      answerFOLstring = answerFOLobject.toString({replaceSymbols:true})
      freeVariables = answerFOLobject.getFreeVariableNames()
      machineFeedback.hasFreeVariables = (freeVariables.length isnt 0)
      if not machineFeedback.hasFreeVariables
        answerPNFsimplifiedSorted = answerFOLobject.convertToPNFsimplifyAndSort().toString({replaceSymbols:true})
        machineFeedback.comment = "Your answer is a sentence of awFOL."
      else 
        machineFeedback.comment = "Your answer is a sentence of awFOL but it cannot be correct because it contains free variables (#{freeVariables}).  Have you forgotten a quantifier or made a mistake with brackets?"
        machineFeedback.isCorrect = false
    else
      machineFeedback.comment = "Your answer is incorrect because it is not a sentence of awFOL."
      machineFeedback.isCorrect = false
    doc.answerFOL = answerFOLstring
    doc.answerPNFsimplifiedSorted = answerPNFsimplifiedSorted
    doc.machineFeedback = machineFeedback
    
    # Try to get human feedback from the grade and comments on a previous student’s answer.
    humanFeedback = ix.gradeUsingGradedAnswers(doc)
    if humanFeedback?
      doc.humanFeedback = humanFeedback
      
    ix.submitExercise(doc, () ->
        Materialize.toast "Your translation has been submitted.", 4000
    )
