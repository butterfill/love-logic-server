editor = undefined
schema = undefined 

setJSONEditor = (editorElement, schemaIdx, data) ->
  newSchema = exerciseTypes.getSchema(schemaIdx)
  canSaveData = exerciseTypes.schemataHaveSameFields(schema, newSchema)
  # `schema` is global in this file
  unless schema is newSchema
    schema = newSchema
    try
      oldData = editor?.getValue()            # `editor` is global in this file
    catch
      oldData = undefined
    editor?.destroy?()
    editor = new JSONEditor editorElement, 
      schema : schema
      disable_edit_json : true
      disable_properties : true
      disable_collapse : true
      iconlib : 'fontawesome4'
      theme : 'materializecss'
  if data?
    editor.setValue(data) 
    exTypeInputVal = $('.exType.typeahead').val()
    if exTypeInputVal? or exTypeInputVal is '' 
      description = exerciseTypes.getSchemaDescription(schemaIdx)
      $('.exType.typeahead').val(description)
  else if canSaveData and oldData?
    # We weren’t sent data, but we should carry it across 
    # from the old schema to the new.
    editor.setValue(oldData) 
      
Template.exerciseBuilder.onRendered () ->
  
  # For now we can only edit exercises using the awFOL syntax.
  # (This is because of complications with ExerciseSchema)
  fol.setDialect('lpl')
  
  # Configure the typeahead
  # Currently a bit wonky : uses a SearchSource (which is reactive)
  # together with the typeahead.js async method --- doesn’t fit well.
  # Note that there’s also a keyup event that runs TutorSearch below 
  # --- without this, the chance of getting all relevant results is decreased.
  descriptions = exerciseTypes.getAllExDescriptions()
  editorElement = $('#exBuilder')[0]
  $('.exType.typeahead').typeahead({
    hint : true
    minLength : 2
    highlight : true
    limit : 10
  },{
    name : 'exerciseTypes'
    async : false
    limit : 10
    display : (exType) -> exType.description
    source : (query, syncResults) ->
      queryWords = query.split(/\s+/)
      maxScore = 0
      for d in descriptions
        d.score = 0
        for qw in queryWords
          d.score += 1 if d.description.indexOf(qw) isnt -1
        if d.score > maxScore
          maxScore = d.score
      res = []
      if maxScore isnt 0
        res = (d for d in descriptions when d.score is maxScore)
      fewerWordsFirstSorter = (a,b) ->
        aWords = a.description.split(' ').length
        bWords = b.description.split(' ').length
        return aWords - bWords
      res.sort( fewerWordsFirstSorter )
      syncResults( res )
    templates : 
      empty : [
          '<div class="empty-message">',
            'unable to find any exercise types matching the current query',
          '</div>'
        ].join('\n')
      suggestion : (exType) ->
        return "<div>#{exType.description}<div>"
  }).bind('typeahead:select', (event, exType) ->
    if exType?.idx?
      setJSONEditor(editorElement, exType.idx)
  )
  
  # Check whether we’ve been sent an exercise to edit
  exerciseText = @data?.exerciseText
  if exerciseText?
    # console.log exerciseText
    {schemaIdx, data} = exerciseTypes.uriToData(exerciseText)
    setJSONEditor(editorElement, schemaIdx, data)
  else
    # Restore the previous session (which is useful in case
    # want to create a sequence of similar exercises).
    if editor? and schema?
      data = editor.getValue()
      if data? and _.toArray(data).length isnt 0
        setJSONEditor(editorElement, schema.schemaIdx, data)
      else
        schema = undefined
        editor?.destroy?()


Template.exerciseBuilderFooter.events
  'click .saveEx' : (event, template) ->
    # `schema` is global for this file
    try
      exerciseURI = schema.toURI(_.toArray(editor.getValue()))
    catch
      Materialize.toast 'Cannot save exercise because there are errors in your input.', 4000
      return
    # @ is that data context, `result` was passed to this component
    # to put data into to be passed back to the caller.
    @result.exerciseURI = exerciseURI
    MaterializeModal.close()
  
  'click .resetEx' : (event, template) ->
    schema = undefined
    editor?.destroy?()
    editor = undefined
    $('.exType.typeahead').val('')
  
  'click .deleteEx' : (event, template) ->
    @result.deleteExercise = true
    MaterializeModal.close()
    