# Define types of exercise for zoxiy.
# Used to create the exerciseBuilder

# Global object: container for useful functions (no data)
@exerciseTypes = {}

# Complication : when creating an exercise, user will write
# in her current dialect (`fol.getCurrentDialectNameAndVersion()`).
# But when the URL is created, we want it to be in awFOL.
# The following FAILS TO ensure just this combination of things.
# This is because we get sentences from URLs (in awFOL regardless of the 
# user’s dialect, and in the users dialect from the input fields)
processFOL = (sentence) ->
  sentence = sentence?.trim?()
  sentence = fol.parse(sentence).toString({replaceSymbols:true, symbols:fol.symbols.default})
  return sentence
processMaybeFOL = (sentence) ->
  sentence = sentence?.trim?()
  try
    sentence = fol.parse(sentence).toString({replaceSymbols:true, symbols:fol.symbols.default})
  return sentence

# Check sentences are awFOL: fol.parse will throw if not
isAwFOL = (sentenceOrSentences) ->
  if _.isArray(sentenceOrSentences)
    (isAwFOL(s) for s in sentenceOrSentences)
    return true
  fol.parse(sentenceOrSentences)
  return true
    

# First define the components from which exercises are built
exComponents =
  premises : 
    title : 'Premises'
    flowFragment : '/from/:_premises'
    type : 'array'
    format : 'table'
    uniqueItems : true
    items : 
      type : 'string'
      title : 'Premise'
      process : processMaybeFOL
    toURI : (sentences) ->
      res = ("#{sentences.join('|')}" if sentences?.length > 0) or '-'
      return "/from/#{res}"
    toData : (txt) -> 
      return [] if (txt is '-') or (txt is '')
      return txt.split('|')
  premisesFOL : 
    title : 'Premises'
    flowFragment : '/from/:_premises'
    type : 'array'
    format : 'table'
    uniqueItems : true
    items : 
      type : 'string'
      title : 'Premise'
      process : processFOL
    toURI : (sentences) ->
      res = ("#{sentences.join('|')}" if sentences?.length > 0) or '-'
      return "/from/#{res}"
    toData : (txt) -> 
      return [] if (txt is '-') or (txt is '')
      sentences = txt.split('|')
      return sentences if isAwFOL(sentences)
  question : 
    title : 'Question'
    flowFragment : '/:_question'
    type : 'string'
    required : true
    toURI : (question) ->
      question = question.trim()
      return "/#{question}"
    toData : (txt) -> txt
  conclusion : 
    title : 'Conclusion'
    flowFragment : '/to/:_conclusion'
    type : 'string'
    required : true
    toURI : (conclusion) ->
      conclusion = processMaybeFOL(conclusion)
      return "/to/#{conclusion}"
    toData : (txt) -> txt
  conclusionFOL : 
    title : 'Conclusion'
    flowFragment : '/to/:_conclusion'
    type : 'string'
    required : true
    toURI : (conclusion) ->
      conclusion = processFOL(conclusion)
      return "/to/#{conclusion}"
    toData : (txt) -> 
      return txt if isAwFOL(txt)
      
  sentence : 
    title : 'Sentence'
    flowFragment : '/sentence/:_sentence'
    type : 'string'
    required : true
    toURI : (sentence) ->
      conclusion = processMaybeFOL(sentence)
      return "/sentence/#{sentence}"
    toData : (txt) -> txt
    
  sentenceFOL : 
    title : 'Sentence'
    flowFragment : '/sentence/:_sentence'
    type : 'string'
    required : true
    toURI : (sentence) ->
      sentence = processFOL(sentence)
      return "/sentence/#{sentence}"
    toData : (txt) -> 
      return txt if isAwFOL(txt)
  
  qq : 
    title : 'Questions'
    flowFragment : '/qq/:_sentences'
    type : 'array'
    format : 'table'
    minItems : 1
    uniqueItems : true
    items : 
      type : 'string'
      title : 'Question'
      process : processMaybeFOL
      minLength: 1
      required : true
    toURI : (sentences) ->
      res = "#{sentences.join('|')}"
      return "/qq/#{res}"
    toData : (txt) -> txt.split('|')
    
  qqFOL : 
    title : 'Sentences'
    flowFragment : '/qq/:_sentences'
    type : 'array'
    format : 'table'
    minItems : 1
    items : 
      type : 'string'
      title : 'Sentence'
      process : processFOL
      minLength: 1
      required : true
    toURI : (sentences) ->
      res = "#{sentences.join('|')}"
      return "/qq/#{res}"
    toData : (txt) -> 
      sentences = txt.split('|')
      return sentences if isAwFOL(sentences)
      
  ttRow : 
    title : 'Truth table row'
    flowFragment : '/TTrow/:_TTrow'
    type : 'array'
    format : 'table'
    minItems : 1
    items : 
      type : 'object'
      process : (obj) ->
        return "#{obj.letter}:#{obj.truthValue}"
      properties : 
        letter : 
          type : 'string'
          title : 'Sentence Letter'
          required : true
        truthValue : 
          type : 'string'
          title : 'Truth Value'
          required : true
          enum : [
            'T'
            'F'
          ]
    toURI : (assignments) ->
      res = "#{assignments.join('|')}"
      return "/TTrow/#{res}"
    toData : (txt) -> 
      parts = txt.split('|')
      res = []
      for item in parts
        letter = item.split(':')[0]
        truthValue = item.split(':')[1]
        res.push({letter, truthValue})
      return res

  domain : 
    title : 'Domain'
    flowFragment : '/domain/:_domain'
    type : 'string'
    required : true
    toURI : (d) ->
      d = d.trim()
      return "/domain/#{d}"
    toData : (txt) -> txt      
    
  names : 
    title : 'Names'
    flowFragment : '/names/:_names'
    type : 'array'
    title : 'Names'
    format : 'table'
    uniqueItems : true
    items : 
      type : 'object'
      title : 'Name'
      process : (obj) ->
        return "#{obj.name}=#{obj.object}"
      properties :
        name : 
          type : 'string'
          title : 'Name'
          required : true
        object :
          type : 'string'
          title : 'Object'
          required : true
    toURI : (assignments) ->
      if assignments? and assignments.length > 0
        res = "#{assignments.join('|')}"
      else
        res = "-"
      return "/names/#{res}"
    toData : (txt) -> 
      return [] if (txt is '-') or (txt is '') or (not txt?)
      parts = txt.split('|')
      res = []
      for item in parts
        bits = item.split('=')
        name = bits[0]
        object = bits[1]
        res.push({name, object})
      return res

  predicates :
    title : 'Predicates'
    flowFragment : '/predicates/:_predicates'
    type : 'array'
    format : 'table'
    title : 'Predicates'
    uniqueItems : true
    items : 
      type : 'object'
      title : 'Predicate'
      process : (obj) ->
        if obj.description?.trim? and obj.description.trim() isnt ''
          return "#{obj.predicateName}#{obj.arity}-#{obj.description.replace(/\s+/g,'-')}"
        else
          return "#{obj.predicateName}#{obj.arity}"
      properties :
        predicateName : 
          type : 'string'
          required : true
          title : 'Predicate Name'
        arity : 
          type : 'integer'
          required : true
          title : 'Arity'
          minimum : 1
          maximum : 9
          default : 1
        description :
          type : 'string'
          title : 'Description'
    toURI : (assignments) ->
      if assignments? and assignments.length > 0
        res = "#{assignments.join('|')}"
      else
        res = "-"
      return "/predicates/#{res}"
    toData : (txt) -> 
      return [] if (txt is '-') or (txt is '') or (not txt?)
      parts = txt.split('|')
      res = []
      for item in parts
        bits = item.split('-')
        firstBit = bits.shift()
        # Name is the awFOL name of the predicate
        predicateName = firstBit[0..firstBit.length-2]
        # predicateName is the informal name used in the description
        arity = parseInt(firstBit[firstBit.length-1])
        # If any parts remain, use them to describe the predicate.
        if bits.length>0
          description = bits.join(' ').replace(/([A-Z])/g, ' $1').toLowerCase().trim()
        else
          description = ''
        res.push({predicateName:predicateName, arity:arity, description:description})
      return res
    
  world : 
    title : 'World'
    flowFragment : '/world/:_world'
    type : 'string'
    required : 'true'
    toURI : (world) ->
      return "/world/#{world}"
    toData : (txt) -> txt


# Define the different types of exercise.
# Note: Order matters---when getting from URIs, the first match will be
# selected. (So where a URI could match two exTypes, put the exType it is
# supposed to match first.)
exTypes = [
  {
    description : 'construct a tree proof to determine whether or not an argument is valid'
    root : 'tree/require/stateIfValid'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'construct a complete tree proof for an argument and determine whether or not the argument is valid'
    root : 'tree/require/complete|stateIfValid'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'construct a complete tree proof for an argument'
    root : 'tree/require/complete'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'construct a closed tree proof for an argument (you must specify an argument which is actually logically valid)'
    root : 'tree/require/closed'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'construct a complete tree proof for some sentences'
    root : 'tree/require/complete'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'construct a tree proof to determine whether or not some sentences are logically consistent'
    root : 'tree/require/stateIfConsistent'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'construct a complete tree proof for some sentences and determine whether or not the sentences are logically consistent'
    root : 'tree/require/complete|stateIfConsistent'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'construct a closed tree proof for some sentences (you must specify sentences which are actually logically inconsistent)'
    root : 'tree/require/closed'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'prove an argument using natural deduction if it is valid (proof)'
    root : 'proof/orInvalid'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'prove an argument using natural deduction (proof)'
    root : 'proof'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'translate a sentence from a formal first-order language into English or another natural language'
    root : 'trans'
    components : [
      exComponents.domain
      exComponents.names
      exComponents.predicates
      exComponents.sentenceFOL
    ]
  }
  {
    description : 'translate a sentence from English or another natural language into a formal first-order language'
    root : 'trans'
    components : [
      exComponents.domain
      exComponents.names
      exComponents.predicates
      exComponents.sentence
    ]
  }
  {
    description : 'create a possible situation where all the sentences are true unless the sentences are inconsistent'
    root : 'create/orInconsistent'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'create a picture of a counterexample unless the argument is valid'
    root : 'create/orValid'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'create a possible situation where all the sentences are true'
    root : 'create'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'create a picture of a counterexample'
    root : 'create'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'give a formal counterexample unless the argument is valid'
    root : 'counter/orValid'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'give a formal counterexample' 
    root : 'counter'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'formally describe a possible situation in which some first-order sentences are true unless the sentences are inconsistent' 
    root : 'counter/orInconsistent'
    components : [
      exComponents.qq
    ]
  }
  {
    description : 'formally describe a possible situation in which some first-order sentences are true' 
    root : 'counter'
    components : [
      exComponents.qq
    ]
  }
  {
    description : 'create truth tables for one or more sentences'
    root : 'tt/noQ'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'create truth tables for an argument'
    root : 'tt/noQ'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'create truth tables for one or more sentences and answer standard questions about the sentences'
    root : 'tt'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'create truth tables for an argument and answer standard questions about whether the argument is valid and which rows, if any, are counterexamples'
    root : 'tt'
    components : [
      exComponents.premisesFOL
      exComponents.conclusionFOL
    ]
  }
  {
    description : 'identify the connective with widest scope in some sentences'
    root : 'scope'
    components : [
      exComponents.qqFOL
    ]
  }
  {
    description : 'answer a question in words'
    root : 'q'
    components : [
      exComponents.question
    ]
  }
  {
    description : 'answer some true/false multiple choice questions about a possible world'
    root : 'TorF'
    components : [
      exComponents.world
      exComponents.qq
    ]
  }
  {
    description : 'answer some true/false multiple choice questions about an argument and a possible world'
    root : 'TorF'
    components : [
      exComponents.premises
      exComponents.conclusion
      exComponents.world
      exComponents.qq
    ]
  }
  {
    description : 'answer some true/false multiple choice questions about a row of a truth table'
    root : 'TorF'
    components : [
      exComponents.ttRow
      exComponents.qq
    ]
  }
  {
    description : 'answer some true/false multiple choice questions about an argument and a row of a truth table'
    root : 'TorF'
    components : [
      exComponents.premises
      exComponents.conclusion
      exComponents.ttRow
      exComponents.qq
    ]
  }
  {
    description : 'answer some true/false multiple choice questions about an argument'
    root : 'TorF'
    components : [
      exComponents.premises
      exComponents.conclusion
      exComponents.qq
    ]
  }
  {
    description : 'answer some true/false multiple choice questions'
    root : 'TorF'
    components : [
      exComponents.qq
    ]
  }
]

# Add `.uriToObject` to each `exType`

for ex in exTypes
  ex.uriToObject = (uri) ->
    if uri.startsWith('/ex/')
      uri = uri.slice('/ex/'.length)
    return undefined unless uri.startsWith(ex.root)
    # console.log "matched #{ex.root}"
    # cut off the root
    uri = uri.slice(ex.root.length)
    
    parts = uri.split('/')
    data = {}
    parts.shift() # get rid of the preceding '' (because startswith /)
    for component, idx in ex.components
      bitsToMatch = component.flowFragment.split('/')
      bitsToMatch.shift() # (because startswith /)
      
      return undefined unless parts.length >= bitsToMatch.length
      
      # All components have two bitsToMatch, e.g. `/sentence/A and B`
      # except /q/ which  has one bitsToMatch, `:_question` 
      # Where a component has two (or more) bitsToMatch, the first 
      # bitsToMatch is just a string which must match the current uri part.
      if bitsToMatch.length > 1
        descPart = parts.shift()
        descPartMatch = bitsToMatch[0]
        return undefined unless descPart is descPartMatch
        # console.log "matched #{descPart}"
      contentPart = parts.shift()
      try
        # process contentPart and add to data
        data[idx] = component.toData(contentPart)
      catch e
        return undefined
        
    return data
  

exerciseTypes.getAllExDescriptions = () ->
  return ({description:o.description, idx:idx} for o, idx in exTypes)

exerciseTypes.getSchemaDescription = (exIdx) ->
  return exTypes[exIdx].description

exerciseTypes.getSchema = (exIdx) ->
  ex = exTypes[exIdx]
  schema = {
    title : '.'
    schemaIdx : exIdx
    # description : ex.description
    root : ex.root
    type : 'object'
    format : 'grid'
    properties : []
  }
  
  for component in ex.components
    schema.properties.push(component)
    
  schema.toURI = (data) ->
    unless _.isArray(data)
      data = _.toArray data
    uri = "/ex/#{ex.root}"
    for bit, idx in data
      component = ex.components[idx]
      if component.items?
        res = []
        for item in bit
          res.push(component.items.process(item))
      else
        res = bit
      uri = "#{uri}#{component.toURI(res)}"
    return uri
      
  return schema

exerciseTypes.uriToData = (uri) ->
  for ex, schemaIdx in exTypes
    data = ex.uriToObject(uri)
    break if data
  return undefined unless data?
  schema = exerciseTypes.getSchema(schemaIdx)
  return {schemaIdx, schema, data}




exerciseTypes.schemataHaveSameFields = (first, second) ->
  return false unless first?.properties?.length? and second?.properties?.length?
  return false unless first.properties.length is second.properties.length
  for firstProp, idx in first
    secondProp = second[idx]
    return false unless firstProp.title is secondProp.title
  return true



# Run this in the console on a page with an ExcerciseSet
# TODO: move to main test suit
exerciseTypes.test = () ->
  
  nofErrors = 0
  
  maybeConvertToAwFOL = (txt) ->
    try
      return fol.parse(txt).toString({replaceSymbols:true})
    catch
      return txt
    
  folify = (uri) ->
    parts = uri.split('/')
    newParts = []
    newParts.push( parts.shift() )
    newParts.push( parts.shift() )
    newParts.push( parts.shift() )
    while parts.length > 0
      next = parts.shift()
      nextParts = next.split('|')
      folParts = ( maybeConvertToAwFOL(p) for p in nextParts )
      newParts.push( folParts.join('|') )
    return newParts.join('/')
  
  test = (ex) ->
    res = exerciseTypes.uriToData(ex)
    unless res?
      console.log "uriToData failed for #{ex}" 
      nofErrors += 1
      return
    {schema, data} = res
    unless schema?
      console.log "no schema for #{ex}" 
      nofErrors += 1
      return
    unless data?
      console.log "no data for #{ex}" 
      nofErrors += 1
      return
    uri = schema.toURI(data)
    unless uri is ex
      unless folify(ex) is uri
        console.log "ex does not match: #{folify(ex)} -> #{uri}"
        nofErrors += 1
        for exPart, idx  in folify(ex).split('/')
          uriPart = uri.split('/')[idx]
          if uriPart isnt exPart
            console.log "\t part mismatch: #{exPart} -> #{uriPart}"
  
  exerciseSet = ExerciseSets.findOne()
  for l in exerciseSet.lectures
    for u in l.units
      for ex in u.rawExercises
        test(ex)
  
  console.log "nofErrors: #{nofErrors}"