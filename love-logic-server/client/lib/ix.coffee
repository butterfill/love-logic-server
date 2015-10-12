# Functions used across various template helpers or event handlers.
# Note: this runs on the client only.

@ix = {}

# ----
# Meteor general

# Return the `_id` of the current user.
ix.getUserId = () ->
  userId = FlowRouter.getQueryParam('user')
  return userId if userId?
  if Meteor.user()?._id
    return Meteor.user()._id
  return undefined

ix.getUserEmail = () ->
  if Meteor.user()?.emails?[0]?.address?
    return Meteor.user().emails[0].address
  return undefined
  

# Return the current url minus any querystring.
ix.url = () ->
  # # NOTE: this would make calls to ix.url reactive
  # FlowRouter.watchPathChange()
  path = FlowRouter.current().path?.split('?')[0]
  if path 
    return decodeURIComponent(path)
  return undefined

ix.queryString = () ->
  # # NOTE: this would make calls to ix.url reactive
  # FlowRouter.watchPathChange()
  path = FlowRouter.current().path
  if path 
    parts = path.split('?')
    if parts.length >0
      return parts[1]
    return ""
  return undefined
  


# ----
# Relating to Exercises

# Converts a link specifying an exercise to the `exerciseId` used in the database
ix.convertToExerciseId = (exerciseLink) ->
  # Remove any trailing slash
  exerciseLink = exerciseLink.replace /\/?$/, ''
  return (encodeURIComponent(i) for i in exerciseLink.split('/')).join('/')

# Get the exerciseId of the current page (when called from a 
# page like `/ex/proof/from/A%7CB%7CC/to/A%20and%20(B%20and%20C)`)
ix.getExerciseId = () ->
  exerciseLink = ix.url()
  return undefined unless exerciseLink
  # Remove any trailing slash
  exerciseLink = exerciseLink.replace /\/$/, ''
  # Remove the extra bit added when grading
  exerciseLink = exerciseLink.replace /\/grade\/?$/, ''
  return ix.convertToExerciseId(exerciseLink) 


# Returns true if the current user has already submitted the exercise specified by `exerciseLink`
# If `exerciseLink` is not given, uses the current url.
ix.isSubmitted = (exerciseLink) ->
  if not exerciseLink?
    exerciseId = ix.getExerciseId()
  else
    exerciseId = ix.convertToExerciseId exerciseLink
  return SubmittedExercises.find({exerciseId}).count() > 0

ix.submitExercise = (exercise, cb) ->
  Meteor.call('submitExercise', _.defaults(exercise,
    exerciseId : ix.convertToExerciseId(ix.url())
  ), cb)


# ----
# Relating to auto grading

ix.hash = (text) ->
  console.log "to hash is #{text}"
  return XXH(text, 0xFFFA).toString(36)

ix.hashAnswer = (answerDoc) ->
  toHash = answerDoc.answer.content
  if _.isString(toHash)
    # Try to eliminate minor variations in text answer by, e.g.
    # making lower case, removing periods, commas and multiple spaces or tables, trim.
    # (Note: there is a small chance of a clash if the answer is awFOL because case is 
    # significant in awFOL for distinguishing predicates from sentence letters, but it's
    # hard to imagine this mattering within the answers to a single exercise.)
    toHash = toHash.toLowerCase().replace(/\./,'').replace(/,/,'').replace(/\s+/g,' ').trim()
  r = ix.hash(JSON.stringify(toHash))
  console.log "hash is #{r}"
  return r

ix.gradeUsingGradedAnswers = (answerDoc, o) ->
  o ?= {}
  exerciseId = ix.getExerciseId()
  return undefined if GradedAnswers.find({exerciseId}).count() is 0
  answerDoc ?= {answer:{content:ix.getAnswer()}}
  answerHash = ix.hashAnswer(answerDoc)
  thisAnswersGrades = GradedAnswers.find({exerciseId, answerHash})
  if o.uniqueAnswer and thisAnswersGrades.count() is 0
    if GradedAnswers.find({exerciseId, isCorrect:true}).count() isnt 0
      # We already checked the answer doesn’t match any graded answer, 
      # so whether the answer is not the unique correct answer.
      return { isCorrect:false }
    
  if thisAnswersGrades.count() is 0
    if answerDoc.answerPNFsimplifiedSorted?
      # Where there is an awFOL expression in PNF, we will grade by checking for equivalence.
      return _gradePNF(answerDoc)
    else
      return undefined 
  isCorrect = undefined
  comment = ''
  conflict = false
  for grade in thisAnswersGrades.fetch()
    if isCorrect isnt undefined and isCorrect isnt grade.isCorrect
      conflict = true
    isCorrect = grade.isCorrect
    if grade.comment?
      comment += grade.comment
  result = {}
  if comment? and comment isnt ''
    result.comment = comment
  if not conflict and isCorrect?
    result.isCorrect = isCorrect
  return result

_gradePNF = (answerDoc) ->
  console.log "using PNF to check for equivalence"
  isCorrect = undefined
  comment = ''
  conflict = false
  answerPNF = answerDoc.answerPNFsimplifiedSorted
  for graded in GradedAnswers.find().fetch()
    gradedPNF = graded.answerPNFsimplifiedSorted
    a = fol.parse(answerPNF)
    g = fol.parse(gradedPNF)
    test = a.isPNFExpressionEquivalent(g)
    if test
      if isCorrect isnt undefined and isCorrect isnt graded.isCorrect
        conflict = true
      isCorrect = graded.isCorrect
      if graded.comment?
        comment += graded.comment
  result = {}
  if comment? and comment isnt ''
    result.comment = comment
  if isCorrect? and not conflict
    result.isCorrect = isCorrect
  return result

# Return an object specifying the lecture and unit in which the present 
# exercise occurs, and also the next exercise in the series (if any).
# Used by the `next_exercise` template.
# Note: this should be called in a context where there is a subscription to a 
# single `ExerciseSet`.
ix.getExerciseContext = () ->
  currentExLink = decodeURIComponent(ix.getExerciseId())
  exSet = ExerciseSets.findOne()
  return undefined unless exSet?.lectures?
  for lecture, lectureIdx in exSet.lectures
    for unit, unitIdx in lecture.units
      for link, linkIdx in unit.rawExercises
        if link is currentExLink
          next = undefined
          if unit.rawExercises.length > linkIdx+1
            next = unit.rawExercises[linkIdx+1]
          else
            if lecture.units.length > unitIdx+1
              next = lecture.units[unitIdx+1].rawExercises[0]
            else
              if exSet.lectures.length > lectureIdx+1
                next = exSet.lectures[lectureIdx+1].units[0].rawExercises[0]
          return {
            lecture
            unit
            next
            exerciseSet : exSet
          }

# The student’s work in progress (in an editor) is stored under this key.
ix.getSessionKeyForUserExercise = () ->
  return "#{ix.getUserId()}/#{ix.getExerciseId()}"
ix.getAnswer = () ->
  Session.get(ix.getSessionKeyForUserExercise())
ix.setAnswer = (answer) ->
  Session.setPersistent(ix.getSessionKeyForUserExercise(), answer)




# ====
# proofs


# Extract premises from the URL.  Remove any premises which are `true`
# (so you can set proofs with no premises).  Add an error if any 
# sentences cannot be parsed.
# Return a list of awFOL objects.
ix.getPremisesFromParams = () ->
  _premises = FlowRouter.getParam('_premises')
  return undefined unless _premises?
  txtList = decodeURIComponent(_premises).split('|')
  try
    folList = (fol.parse(t) for t in txtList)
  catch e
    # The premises may occasionally be sentences of English or another natural language.
    return (_fixEnglishSentence(x) for x in txtList)
  folList = (e for e in folList when not (e.type is 'value' and e.value is true))
  return folList

# Extract the conclusion from the URL.
# Return it as an awFOL object.
ix.getConclusionFromParams = () ->
  _conclusion = FlowRouter.getParam('_conclusion')
  return undefined unless _conclusion?
  try
    e = fol.parse(decodeURIComponent(_conclusion))
  catch error
    return _fixEnglishSentence(_conclusion)
  return e

# Extract the proof to be written from the params.  
ix.getProofFromParams = () ->
  premiseTxt = (t.toString({replaceSymbols:true}) for t in ix.getPremisesFromParams()).join('\n| ')
  conclusionTxt = ix.getConclusionFromParams().toString({replaceSymbols:true})
  return "| #{premiseTxt}\n|---\n| \n| \n| #{conclusionTxt}"  

ix.getTTrowFromParam = () ->
  _raw = FlowRouter.getParam('_TTrow')
  return undefined unless _raw?
  assignments = decodeURIComponent(_raw).split('|')
  row = {}
  for a in assignments
    [key,value] = a.split(':')
    row[key]=value
  return row
    

ix.checkPremisesAndConclusionOfProof = (theProof) ->
    # Now check the conclusion is what its supposed to be.
    conclusionIsOk = theProof.getConclusion().isIdenticalTo( ix.getConclusionFromParams() )
    if not conclusionIsOk 
      return "Your conclusion (#{theProof.getConclusion()}) is not the one you were supposed to prove (#{ix.getConclusionFromParams()})."
    # Finally, check no premises other than those stipulated have been used (but
    # you don't have to use the premises given.)
    proofPremises = theProof.getPremises()
    proofPremisesStr = (p.toString({replaceSymbols:true}) for p in proofPremises)
    actualPremisesList = (p.toString({replaceSymbols:true}) for p in ix.getPremisesFromParams())
    proofPremisesNotInActualPremises = _.difference proofPremisesStr, actualPremisesList
    premisesAreOk = proofPremisesNotInActualPremises.length is 0
    if not premisesAreOk
      return "Your premises (#{proofPremisesStr.join(', ')}) are not the ones you were supposed to start from---you added #{proofPremisesNotInActualPremises.join(', ')}."
    #Everything is  ok
    return true

ix.getSentencesFromParam = (self) ->
  sentencesParam = FlowRouter.getParam('_sentences')
  if sentencesParam?
    sentences = decodeURIComponent(sentencesParam).split('|')
    try
      return (fol.parse(x) for x in sentences)
    catch e
      # The sentences may be English rather than awFOL.
      return (_fixEnglishSentence(s) for s in sentences)
  # Try another method
  if self?.exerciseId?
    exercisesIdParts = self.exerciseId.split('/')
    if 'qq' in exercisesIdParts
      qqIdx = exercisesIdParts.indexOf('qq')
      # The sentences are the part after `qq`
      rawSentences = exercisesIdParts[qqIdx+1]
    else
      rawSentences = exercisesIdParts[3]
    sentences = decodeURIComponent(rawSentences).split('|')
    try
      return (fol.parse(x) for x in sentences)
    catch e
      return (_fixEnglishSentence(s) for s in sentences)
  # give up
  return []

_fixEnglishSentence = (sentence) ->
  if not sentence.endsWith('.')
    sentence += '.'
  # capitalize first letter
  sentence = sentence.charAt(0).toUpperCase() + sentence.slice(1)
  return sentence

ix.getWorldFromParam = () ->
  world = FlowRouter.getParam('_world')
  if world?
    return JSON.parse(decodeURIComponent(world))
  return undefined

# ======
# create a possible situation

ix.possibleWorld = 
  checkSentencesTrue : ($grid, giveFeedback) ->
    allTrue = true
    try
      possibleSituation = ix.possibleWorld.getSituationFromSerializedWord( ix.possibleWorld.serialize($grid) )
    catch error
      #TODO THIS BELONGS ELSEWHERE
      giveFeedback?("Warning: #{error.message}")
      console.log "Warning: #{error.message}"
      return false
    for sentence, idx in ix.getSentencesFromParam()
      try
        isTrue = sentence.evaluate(possibleSituation)
      catch error
        giveFeedback?("Warning: #{error.message}")
        console.log "Warning: #{error.message}"
        #TODO: this is part of another template!
        $(".sentenceIsTrue:eq(#{idx})").text('[not evaluable in this world]')
        return false
      allTrue = allTrue and isTrue 
      #TODO: this is part of another template!
      $(".sentenceIsTrue:eq(#{idx})").text(('T' if isTrue) or 'F')
    return allTrue
    
  # Create a possible situation against which awFOL sentences can be evaluated.
  # For example:
  #   `{domain:[1,2,3], predicates:{F:[[1],[3]]}, names:{a:1, b:2}})`
  getSituationFromSerializedWord : (data) ->
    domain = []
    predicates = {}
    names = {}
    assignedNames = []
    for item, idx in data
      domain.push idx

      # names
      if item.name? and item.name isnt ''
        itemNames = item.name.split(/[\s,]+/)
        for aName in itemNames
          if aName in assignedNames
            throw new Error "You cannot give the name ‘#{aName}’ to two objects."
          assignedNames.push aName
          names[aName] = idx
        
      #unary predicates
      newPredicates = ix.possibleWorld.getPredicatesFromSerializedObject(item)
      for p in newPredicates
        if p not of predicates
          predicates[p] = []
        predicates[p].push [idx]
  
    # binary predicates
    for predicateName, test of ix.possibleWorld.binaryPredicates
      predicates[predicateName] = []
      for a, aIdx in data
        for b, bIdx in data
          if test(a,b)
            predicates[predicateName].push [aIdx,bIdx]
    return {
      domain
      predicates
      names
    }
  
  # Given an HTML element representing a `thing`, return monadic predictates that describe this thing.  
  getPredicatesFromSerializedObject : (object) ->
    eyesSymbol = object.face[0]
    noseSymbol = object.face[1]
    mouthSymbol = object.face[2]
    predicates = [
      ix.possibleWorld.getPredicate(mouthSymbol, ix.possibleWorld.mouths)?.split(',')
      ix.possibleWorld.getPredicate(eyesSymbol, ix.possibleWorld.eyes)?.split(',')
      ix.possibleWorld.getPredicate(noseSymbol, ix.possibleWorld.nose)?.split(',')
    ]
    predicates = _.flatten(predicates)
    colourName = object.colour
    colourPredicate = colourName[0].toUpperCase() + colourName.split('').splice(1).join('')
    predicates.push colourPredicate
    predicates.push (("Tall" if object.height is 3) or "Short")
    predicates.push (("Wide" if object.width is 3) or "Narrow")
    return (x for x in predicates when x?)
  
  mouths : [
    {symbol:')', predicate:'Happy'}
    {symbol:'|', predicate:'Neutral'}
    {symbol:'(', predicate:'Sad'}
    {symbol:'D', predicate:'Laughing,Happy'}
    {symbol:'()', predicate:'Surprised'}
    {symbol:'{}', predicate:'Angry'}
  ]
  eyes : [
    {symbol:':', predicate:null}
    {symbol:'}:', predicate:'Frowning'}
    {symbol:';', predicate:'Winking'}
    {symbol:":'", predicate:'Crying'}
    {symbol:"|%", predicate:'Confused'}
  ]
  nose : [
    {symbol:'-', predicate:null}
    {symbol:'>', predicate:'HasLargeNose'}
    {symbol:"^", predicate:null}
  ]
  
  binaryPredicates : 
    LeftOf : (a,b) ->
      return (a.x+a.width) <= b.x
    RightOf : (a,b) ->
      return a.x >= (b.x+b.width)
    Above : (a,b) ->
      return (a.y+a.height) <= b.y
    Below : (a,b) ->
      return a.y >= (b.y+b.height)
    HorizontallyAdjacent : (a,b) ->
      if (a.x + a.width is b.x) or (b.x + b.width is a.x)
        if (a.y >= b.y and a.y <= (b.y+b.height)) or (b.y >= a.y and b.y <= (a.y+a.height))
          return true
      return false
    VerticallyAdjacent : (a,b) ->
      if (a.y + a.height is b.y) or (b.y + b.height is a.y)
        if (a.x >= b.x and a.x <= (b.x+b.width)) or (b.x >= a.x and b.x <= (a.x+a.width))
          return true
      return false
    Adjacent : (a,b) ->
      return ix.possibleWorld.binaryPredicates.HorizontallyAdjacent(a,b) or ix.possibleWorld.binaryPredicates.VerticallyAdjacent(a,b)
    WiderThan : (a,b) ->
      return a.width > b.width
    NarrowerThan : (a,b) ->
      return a.width < b.width
    TallerThan : (a,b) ->
      return a.height > b.height
    ShorterThan : (a,b) ->
      return a.height < b.height
    SameShape : (a,b) ->
      return (a.height is b.height) and (a.width is b.width)
    SameSize : (a,b) ->
      return (a.height * a.width) is (b.height * b.width)

  getPredicate : (symbol, type) ->
    symbolIdx = (x.symbol for x in type).indexOf(symbol.trim())
    if symbolIdx is -1
      return undefined
    return type[symbolIdx]?.predicate

  # Given an HTML element representing a `thing`, return its name (if any)
  getNameFromDiv : (el) ->
    return $('input', el).val()

  getColourFromDiv : (el) ->
    classes = $('.grid-stack-item-content', el).attr('class')
    if not classes
      return 'white'
    for label in ix.possibleWorld.ELEMENT_COLOURS
      if classes.indexOf(label) isnt -1
        return label

  ELEMENT_COLOURS : ( () ->  
    list = ['white','yellow','red','pink','purple','green','blue','indigo','cyan','teal','lime','orange']
    defaultNodeColourIdx = -1
    list.next = () ->
      defaultNodeColourIdx += 1
      if defaultNodeColourIdx >= list.length
        defaultNodeColourIdx = 0
      return list[defaultNodeColourIdx]
    return list
  )()

  serialize : ($grid) ->
    _.map $('.grid-stack-item:visible', $grid), (el) ->
      el = $(el)
      node = el.data('_gridstack_node')
      return {
        x: node.x,
        y: node.y,
        width: node.width,
        height: node.height
        name : ix.possibleWorld.getNameFromDiv(el)
        colour : ix.possibleWorld.getColourFromDiv(el)
        face : ($(".#{cls}", el).text().trim() for cls in ['eyes','nose','mouth'])
      }

  serializeAndAbbreviate : ($grid) ->
    return (ix.possibleWorld.abbreviate(x) for x in ix.possibleWorld.serialize($grid))

  # Abbreviation service.  We want to refer to properties like `width` and `face`;
  # but we also want to pop possible situations into URLs.  So we abbreviate before 
  # serializing and unabbreviate on deseializing.
  ABBRV : 
    'width':'w'
    'height':'h'
    'name':'n'
    'colour':'c'
    'face':'f'
  _abbreviate : (dict, keyMap) ->
    if _.isArray(dict)
      return (ix.possibleWorld._abbreviate(x,keyMap) for x in dict)
    res = {}
    for own k,v of dict
      if k of keyMap
        res[keyMap[k]] = v
      else
        res[k]=v
    return res
  abbreviate : (dict) ->
    return ix.possibleWorld._abbreviate(dict, ix.possibleWorld.ABBRV)
  unabbreviate : (dict) ->
    return ix.possibleWorld._abbreviate(dict, ix.possibleWorld.UNABBRV)

ix.possibleWorld.UNABBRV = (() ->
  res = {}
  for own k,v of ix.possibleWorld.ABBRV
    res[v]=k
  return res
)()


# ======
# truth tables

ix.truthTable = 
  checkAnswer : (values) ->
    values ?= ix.truthTable.getValuesFromTable()
    result = ix.truthTable.checkAnswerCorrectNofRows(values)
    return result unless result.isCorrect
    res2 = ix.truthTable.checkAnswerCorrectRowOrder(values)
    if not res2
      result.message += 'You did not order the rows correctly.'
      result.isCorrect = false
  
    lttrs = ix.truthTable.getSentenceLetters()
    sentences = ix.getSentencesFromParam()
    correctAnswers = []
    for row, rowIdx in values
      world = {}
      for l, idx in lttrs
        world[l] = row[idx]
      thisRowCorrect = []
      for s, idx in sentences
        submittedValue = row[idx+lttrs.length]
        actualValue = s.evaluate(world)
        # console.log "row #{rowIdx} sentence #{idx} : you = #{submittedValue}, actual = #{actualValue}"
        thisRowCorrect.push(submittedValue is actualValue)
      correctAnswers = correctAnswers.concat thisRowCorrect
    if false in correctAnswers
      result.isCorrect = false
      result.message += 'You did not provide the correct truth values in all rows.'
    return result

  checkAnswerCorrectNofRows : (values) ->
    lttrs = ix.truthTable.getSentenceLetters()
    expectedNofRows = Math.pow(2,lttrs.length)
    message = ''
    if expectedNofRows > values.length
      message = 'You have too few rows.'
    if expectedNofRows < values.length
      message = 'You have too many rows.'
    return {
      isCorrect: expectedNofRows is values.length
      message
    }
  checkAnswerCorrectRowOrder : (values) ->
    values = (_.clone(r) for r in values)
    lttrs = ix.truthTable.getSentenceLetters()
    expectedNofRows = Math.pow(2,lttrs.length)
    for num in [expectedNofRows-1..0]
      binaryStr = ix.truthTable.pad0(num.toString(2), lttrs.length)
      expected = (x is "1" for x in binaryStr)
      idx = (expectedNofRows-1)-num
      actual = values[idx].splice(0,lttrs.length)
      return false unless _.isEqual(expected, actual)
    return true
    
  pad0 : (n, len) ->
    return n if n.length >= len
    # Thankyou http://stackoverflow.com/questions/10073699/pad-a-number-with-leading-zeros-in-javascript
    return new Array(len - n.length + 1).join('0') + n
  
  getSentenceLetters : (self) ->
    lttrs = []
    for s in ix.getSentencesFromParam(self)
      moreLttrs = s.getSentenceLetters()
      lttrs = lttrs.concat moreLttrs
    return _.uniq(lttrs)
  
  getValuesFromTable : () ->
    result = []
    $rows = $('.truthtable tbody tr')
    $rows.each (idx, tr) ->
      resultRow = []
      $inputs = $('input', $(tr))
      $inputs.each (idx, input) ->
        resultRow.push true if ($(input).val() is "T")
        resultRow.push false if ($(input).val() is "F")
        resultRow.push null if not ($(input).val() in ["T","F"])
      result.push resultRow
    return result
