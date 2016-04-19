# Example URL:
# http://localhost:3000/ex/trans/domain/3things/names/a=thing-1%7Cb=thing-2/predicates/Fish1-x-is-a-fish%7CBetween3-xIsBetweenYAndZ%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish

editor = undefined  #This will be our codemirror thing.

# This will be configured `.onRender`
isTranslationToEn = false


# ========
# Template: trans_ex_display_question

# (This is a fragment that is used both for students and graders)
# Returns a list of names and referents for display, e.g. ['a : Ayesha']
getNames = (self, returnRawNames) -> 
  rawNameText = FlowRouter.getParam('_names')
  if not rawNameText?
    if self?.exerciseId?
      parts = self.exerciseId.split('/')
      idx = parts.indexOf('names')+1
      rawNameText = parts[idx]
  nameDescriptions = decodeURIComponent(rawNameText).replace(/\=/g,' : ').split('|')
  return nameDescriptions unless returnRawNames
  rawNames = (x.split(' : ')[0] for x in nameDescriptions)
  return rawNames

# Returns just the names, e.g. ['a', 'b']
getRawNames = (self) ->
  return getNames(self, true)
  
  
Template.trans_ex_display_question.helpers
  isTranslationToEn : () ->
    return checkIfTranslationToEn(@)
  isPredicates : () ->
    predicates = getPredicatesFromParams(@, true)
    return false unless predicates?.length > 0
    if predicates.length is 1
      return false if predicates[0].trim() is "" or predicates[0].trim() is "-"
    return true
  predicates : () -> getPredicatesFromParams(@)
  sentence : () -> 
    if checkIfTranslationToEn(@)
      folSentence = fol.parseUsingSystemParser(ix.getSentenceFromParam(@))
      ix.setDialectFromExerciseSet()
      sentenceTxt = folSentence.toString({replaceSymbols:true})
      return sentenceTxt
    return ix.getSentenceFromParam(@)
  domain : () -> getDomainFromParams(@).join(', ')
  names : () -> getNames(@)
  isNames : () ->
    names = getNames(@)
    return false unless names?.length > 0
    if names.length is 1
      return false if names[0].trim() is "" or names[0].trim() is "-"
    return true


checkIfTranslationToEn = (self) ->
  sentence = ix.getSentenceFromParam(self)
  try
    fol.parseUsingSystemParser sentence
    # If we can parse the sentence given, it is an awFOL sentence to be 
    # translated into English.
    return true
  catch error
    return false

getPredicatesFromParams = (self, returnRawPredicates) ->
  raw = FlowRouter.getParam('_predicates')
  if not raw?
    if self?.exerciseId?
      parts = self.exerciseId.split('/')
      idx = parts.indexOf('predicates')+1
      raw = parts[idx]
  rawParts = decodeURIComponent(raw).split('|')
  return rawParts if returnRawPredicates
  predicates = (extractPredicteFromParam(p) for p in rawParts)
  return predicates

getRawPredicates = () ->
  nameArityList = getPredicatesFromParams(undefined, true)
  _predicates = []
  for nameArity in nameArityList
    # predicate might be "Fish1-x-is-a-fish"
    parts = nameArity.split('-')
    firstBit = parts.shift()
    # Assume arity is a single digit
    name = firstBit[0..firstBit.length-2]
    arity = parseInt(firstBit[firstBit.length-1])
    _predicates.push {name, arity}
  return _predicates
  

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
  predicateAwFOLText = "#{name}(#{variables[0..arity-1]})"
  predicateFOL = fol.parseUsingSystemParser(predicateAwFOLText)
  ix.setDialectFromExerciseSet()
  predicateTxt = predicateFOL.toString({replaceSymbols:true})
  description = "#{predicateTxt} : #{predicateDescription}"
  return {name, arity, description}

getDomainFromParams = (self) ->
  rawDomainText = FlowRouter.getParam('_domain')
  if not rawDomainText?
    if self?.exerciseId?
      urlParts = self.exerciseId.split('/')
      idx = urlParts.indexOf('domain')+1
      rawDomainText = urlParts[idx]
  parts = decodeURIComponent(rawDomainText).split('|')
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

isAnswerFOLsentence = () ->
  rawAnswer = ix.getAnswer()?.sentence
  ix.setDialectFromCurrentAnswer()
  try 
    answer = fol.parse( rawAnswer.replace(/\n/g,' ') )
    return true
  catch error
    return false

getAnswerAsFOLsentence = () ->
  rawAnswer = ix.getAnswer().sentence
  ix.setDialectFromCurrentAnswer()
  try 
    answer = fol.parse( rawAnswer.replace(/\n/g,' ') )
    return answer
  catch error
    return undefined


Template.trans_ex.onCreated () ->
  templateInstance = @
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    templateInstance.subscribe 'graded_answers', exerciseId
    

Template.trans_ex.onRendered () ->
  isTranslationToEn = checkIfTranslationToEn()

Template.trans_ex.helpers 
  'sentenceIsAwFOL' : () ->
    return not checkIfTranslationToEn()
    
Template.trans_ex.events 
  'click button#submit' : (event, template) ->
    answer = ix.getAnswer()?.sentence
    
    doc = {
      answer : 
        type : 'trans'
        content : {sentence:answer}
    }
    dialectNameAndVersion = fol.getCurrentDialectNameAndVersion()
    if dialectNameAndVersion?
      doc.answer.content.dialectName = dialectNameAndVersion.name
      doc.answer.content.dialectVersion = dialectNameAndVersion.version
      
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
      
    # Answer should be an awFOL sentence ...
    
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
        # TODO : replace ‘awFOL’ with the dialectName’s language
        machineFeedback.comment = "Your answer is a sentence of awFOL."
        
        # check whether the answer uses only  names which are allowed.
        namesUsed = answerFOLobject.getNames()
        namesAllowed = getRawNames()
        usedCorrectNames = true
        for name in namesUsed
          continue if name in namesAllowed
          usedCorrectNames = false
          break
        machineFeedback.usedCorrectNames = usedCorrectNames
        unless machineFeedback.usedCorrectNames 
          machineFeedback.comment += " But you used names other than those specified in the question."
          machineFeedback.isCorrect = false
          
        # check whether the answer uses only predicates which are allowed.
        usedCorrectPredicates = true
        predicatesUsed = answerFOLobject.getPredicates()
        predicatesAllowed = getRawPredicates()
        for predicate in predicatesUsed
          continue if _.where(predicatesAllowed, predicate).length > 0
          usedCorrectPredicates = false
          break
        machineFeedback.usedCorrectPredicates = usedCorrectPredicates
        unless machineFeedback.usedCorrectPredicates 
          machineFeedback.comment += " But you used predicates other than those specified in the question."
          machineFeedback.isCorrect = false
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
      # May need to override humanFeedback because of issues with use of toLowerCase in hashing answers (TODO: fix!)
      if (not machineFeedback.isCorrect?) or (machineFeedback.isCorrect is humanFeedback.isCorrect)
        doc.humanFeedback = humanFeedback
      
    ix.submitExercise(doc, () ->
        Materialize.toast "Your translation has been submitted.", 4000
    )
