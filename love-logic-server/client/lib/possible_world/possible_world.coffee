

# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")


Template.possible_world_static.onRendered () ->
  o = @data.options or {}
  options = _.defaults o, 
    cell_height: 80
    width: 12
    animate : true
    vertical_margin: 10
    static_grid : true
  
  templateInstance = this
  $grid = $(@find('.grid-stack'))
  $grid.gridstack(options)
  studentsAnswer = @data.answer.content
  deserializeAndRestore(studentsAnswer, $grid)

Template.possible_world_from_param.onRendered () ->
  o = @data.options or {}
  options = _.defaults o, 
    cell_height: 80
    width: 12
    animate : true
    vertical_margin: 10
    static_grid : true
  
  templateInstance = this
  @autorun () ->
    # We need to `watchPathChange` so that the possible situation gets updated.
    FlowRouter.watchPathChange()
    $grid = $(templateInstance.find('.grid-stack'))
    $grid.gridstack(options)
    world = ix.getWorldFromParam()
    deserializeAndRestore(world, $grid)


Template.possible_world.onRendered () ->
  o = @data.options or {}
  options = _.defaults o, 
    cell_height: 80
    width: 12
    animate : true
    vertical_margin: 10
  
  templateInstance = this
  $grid = $(@find('.grid-stack'))
  templateInstance.$grid = $grid
  $grid.gridstack(options)
  $grid.on 'change', () ->
    saveAndUpdate()

  # Allow the possible situation to be updated by setting the session variable
  @autorun () ->
    # We need to `watchPathChange` so that the possible situation gets updated.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer() 
    if not savedAnswer?
      # Allow the grid from a previous question to be carried over
      # But add an element if there are none.
      if getNofElements($grid) is 0
        addElementToGrid(defaultNode(), $grid)
    else
      currentAnswer = ix.possibleWorld.serializeAndAbbreviate($grid)
      if not (_.isEqual(currentAnswer, savedAnswer) )
        deserializeAndRestore(savedAnswer, $grid)
        # Clear feedback because the answer has been changed from outside
        giveFeedback ""
        ix.possibleWorld.checkSentencesTrue($grid, giveFeedback) 

getNofElements = ($grid) ->
  return $('.grid-stack-item', $grid).length


getNextSymbol = (currentSymbol, type) ->
  currentSymbolIdx = (x.symbol for x in type).indexOf(currentSymbol)
  nextSymbolIdx = currentSymbolIdx+1
  if nextSymbolIdx >= type.length
    nextSymbolIdx = 0
  nextSymbol = type[nextSymbolIdx].symbol
  return nextSymbol
getRandomSymbol = (type)  ->
  return type[Math.floor(Math.random()*type.length)].symbol;





deserializeAndRestore = (data, $grid) ->
  theGrid = $grid.data('gridstack')
  theGrid.remove_all()
  _.each data,  (node) ->
    addElementToGrid(ix.possibleWorld.unabbreviate(node), $grid)
    
      
addElementToGrid = (node, $grid) ->
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
        <div class="container">
          <div class='input-field'>
            <input placeholder="[no name]", type="text" value="#{node.name or ''}" >
          </div>
        </div>
        <div class="left" style="margin-top:-3px;">
          <i class="material-icons right grey-text deleteElement"> delete </i>
        </div>
      </div>
    </div>
  """)
  theGrid = $grid.data('gridstack')
  newElement = theGrid.add_widget $html,
    node.x, node.y, node.width, node.height, false
  return newElement

defaultNode = () ->
  return {
    "x":0, "y":0, "width":2, "height":2
    "name": ""
    "colour": ix.possibleWorld.ELEMENT_COLOURS.next()
    "face": [ getRandomSymbol(ix.possibleWorld.eyes), getRandomSymbol(ix.possibleWorld.nose), getRandomSymbol(ix.possibleWorld.mouths) ]
  }


saveAndUpdate = ($grid) ->
  ix.setAnswer( ix.possibleWorld.serializeAndAbbreviate($grid) )
  ix.possibleWorld.checkSentencesTrue($grid, giveFeedback)
        

Template.possible_world.events 
  'click .mouth' : (event, template) -> 
    currentSymbol = $(event.target).text()
    nextSymbol = getNextSymbol(currentSymbol, ix.possibleWorld.mouths)
    $(event.target).text(nextSymbol)
    saveAndUpdate(template.$grid)
  'click .eyes' : (event, template) -> 
    currentSymbol = $(event.target).text()
    nextSymbol = getNextSymbol(currentSymbol, ix.possibleWorld.eyes)
    $(event.target).text(nextSymbol)
    saveAndUpdate(template.$grid)
  'click .nose' : (event, template) -> 
    currentSymbol = $(event.target).text()
    nextSymbol = getNextSymbol(currentSymbol, ix.possibleWorld.nose)
    $(event.target).text(nextSymbol)
    saveAndUpdate(template.$grid)
  'blur input' : (event, template) ->
    saveAndUpdate(template.$grid)

  'click button#addElement' : (event, template) ->
    addElementToGrid(defaultNode(), template.$grid)

  'click .deleteElement' : (event, template) ->
    if getNofElements(template.$grid) is 1
      Materialize.toast "All possible situations must have at least one thing.", 4000
      return undefined
    el = $(event.target).parents('.grid-stack-item')
    theGrid = template.$grid.data('gridstack')
    theGrid.remove_widget(el)
    

    

