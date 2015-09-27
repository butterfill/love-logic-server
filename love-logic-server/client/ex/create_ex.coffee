# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")

Template.create_ex.rendered = () ->
  options = 
    cell_height: 80
    width: 12
    animate : true
    vertical_margin: 10
  $('.grid-stack').gridstack(options)
  $('.grid-stack').on('change', () ->
    saveAndUpdate()
  )

  # Allow the possible situation to be updated by setting the session variable
  Tracker.autorun () ->
    # We need to `watchPathChange` so that the possible situation gets updated.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer() 
    if savedAnswer?
      currentAnswer = serialize()
      if not (_.isEqual(currentAnswer, savedAnswer) )
        console.log "restoring answer"
        deserialize(savedAnswer)
        # Clear feedback because the answer has been changed from outside
        giveFeedback ""     
        checkSentencesTrue()

mouths = [
  {symbol:')', predicate:'Happy'}
  {symbol:'|', predicate:'Neutral'}
  {symbol:'(', predicate:'Sad'}
  {symbol:'D', predicate:'Laughing'}
  {symbol:'()', predicate:'Surprised'}
  {symbol:'{}', predicate:'Angry'}
]
eyes = [
  {symbol:':', predicate:null}
  {symbol:'}:', predicate:'Frowing'}
  {symbol:';', predicate:'Winking'}
  {symbol:":'", predicate:'Crying'}
  {symbol:"|%", predicate:'Confused'}
]
nose = [
  {symbol:'-', predicate:null}
  {symbol:'>', predicate:'HasLargeNose'}
  {symbol:"^", predicate:null}
]
getNextSymbol = (currentSymbol, type) ->
  currentSymbolIdx = (x.symbol for x in type).indexOf(currentSymbol)
  nextSymbolIdx = currentSymbolIdx+1
  if nextSymbolIdx >= type.length
    nextSymbolIdx = 0
  nextSymbol = type[nextSymbolIdx].symbol
  return nextSymbol
getPredicate = (symbol, type) ->
  symbolIdx = (x.symbol for x in type).indexOf(symbol)
  if symbolIdx is -1
    return undefined
  return type[symbolIdx]?.predicate

# Given an HTML element representing a `thing`, return its name (if any)
getNameFromDiv = (el) ->
  return $('input', el).val()

getColourFromDiv = (el) ->
  classes = $('.grid-stack-item-content', el).attr('class')
  if not classes
    return 'white'
  for label in ['white','yellow','red','pink','purple','green','blue','indigo','cyan','teal','lime','orange']
    if classes.indexOf(label) isnt -1
      return label

# Given an HTML element representing a `thing`, return monadic predictates that describe this thing.  
getPredicatesFromSerializedObject = (object) ->
  eyesSymbol = object.face[0]
  noseSymbol = object.face[1]
  mouthSymbol = object.face[2]
  predicates = [
    getPredicate(mouthSymbol, mouths)
    getPredicate(eyesSymbol, eyes)
    getPredicate(noseSymbol, nose)
  ]
  colourName = object.colour
  colourPredicate = colourName[0].toUpperCase() + colourName.split('').splice(1).join('')
  predicates.push colourPredicate
  predicates.push (("Tall" if object.height is 3) or "Short")
  predicates.push (("Wide" if object.width is 3) or "Narrow")
  return (x for x in predicates when x?)

binaryPredicates = 
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
    return binaryPredicates.HorizontallyAdjacent(a,b) or binaryPredicates.VerticallyAdjacent(a,b)
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

# Create a possible situation against which awFOL sentences can be evaluated.
# For example:
#   `{domain:[1,2,3], predicates:{F:[[1],[3]]}, names:{a:1, b:2}})`
getSituationFromSerializedWord = (data) ->
  domain = []
  predicates = {}
  names = {}
  assignedNames = []
  for item, idx in data
    domain.push idx

    # names
    if item.name? and item.name isnt ''
      itemNames = item.name.split(',')
      for aName in itemNames
        if aName in assignedNames
          throw new Error "You cannot give the name ‘#{aName}’ to two objects."
        assignedNames.push aName
        names[aName] = idx
        
    #unary predicates
    newPredicates = getPredicatesFromSerializedObject(item)
    for p in newPredicates
      if p not of predicates
        predicates[p] = []
      predicates[p].push [idx]
  
  # binary predicates
  for predicateName, test of binaryPredicates
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
  
serialize = () ->
  _.map $('.grid-stack .grid-stack-item:visible'), (el) ->
    el = $(el)
    node = el.data('_gridstack_node')
    return {
      x: node.x,
      y: node.y,
      width: node.width,
      height: node.height
      name : getNameFromDiv(el)
      colour : getColourFromDiv(el)
      face : ($(".#{cls}", el).text() for cls in ['eyes','nose','mouth'])
    }
deserialize = (data) ->
  grid = $('.grid-stack').data('gridstack')
  grid.remove_all()
  _.each data,  (node) ->
    $html = $("""
      <div data-gs-max-width="3" data-gs-min-width="2" data-gs-max-height="3" data-gs-min-height="2">
        <div class='grid-stack-item-content #{node.colour} lighten-2' >
          <div class='center'>
            <div class='face'>
              <span class='eyes'>#{node.face[0]}
              </span>
              <span class='nose'>#{node.face[1]}
              </span>
              <span class='mouth'>#{node.face[2]}
              </span>
            </div>
          </div>
          <div class='input-field'>
            <input placeholder="[no name]", type="text" value="#{node.name or ''}" >
          </div>
        </div>
      </div>
    """)
    newWidget = grid.add_widget $html,
      node.x, node.y, node.width, node.height, false
      

checkSentencesTrue = () ->
  allTrue = true
  try
    possibleSituation = getSituationFromSerializedWord( serialize() )
  catch error
    giveFeedback "Warning: #{error.message}"
    return false
  for sentence, idx in getSentencesFromParam()
    try
      isTrue = sentence.evaluate(possibleSituation)
    catch error
      giveFeedback "Warning: #{error.message}"
      $(".sentenceIsTrue:eq(#{idx})").text('[not evaluable in this world]')
      return false
    allTrue = allTrue and isTrue 
    $(".sentenceIsTrue:eq(#{idx})").text(('T' if isTrue) or 'F')
  return allTrue
    
saveAndUpdate = () ->
  ix.setAnswer( serialize() )
  checkSentencesTrue()
  # console.log "serialize"
  # console.log serialize()
  # console.log "getSituationFromSerializedWord"
  # console.log getSituationFromSerializedWord( serialize() )
        

Template.create_ex.events 
  'click .mouth' : (event, template) -> 
    currentSymbol = $(event.target).text()
    nextSymbol = getNextSymbol(currentSymbol, mouths)
    $(event.target).text(nextSymbol)
    saveAndUpdate()
  'click .eyes' : (event, template) -> 
    currentSymbol = $(event.target).text()
    nextSymbol = getNextSymbol(currentSymbol, eyes)
    $(event.target).text(nextSymbol)
    saveAndUpdate()
  'click .nose' : (event, template) -> 
    currentSymbol = $(event.target).text()
    nextSymbol = getNextSymbol(currentSymbol, nose)
    $(event.target).text(nextSymbol)
    saveAndUpdate()
  'blur input' : (event, template) ->
    saveAndUpdate()

  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    isCorrect = checkSentencesTrue()
    machineFeedback = {
      isCorrect : isCorrect
      comment : "Your submitted possible situation is #{('not' if not isCorrect) or ''} correct."
    }
    ix.submitExercise({
        answer : 
          type : 'create'
          content : serialize()
        machineFeedback : machineFeedback
      }, () ->
        Materialize.toast "Your possible situation has been submitted.", 4000
    )


# ===================
# display question template

getSentencesFromParam = () ->
  sentences = decodeURIComponent(FlowRouter.getParam('_sentences')).split('|')
  return (fol.parse(x) for x in sentences)

Template.create_ex_display_question.helpers 
  sentences : () ->
    folSentences = getSentencesFromParam()
    return ({theSentence:x.toString({replaceSymbols:true})} for x in folSentences)

