
Template.truth_table.onRendered () ->
  # Allow the answer to be updated by setting the session variable
  templateInstance = this
  
  @autorun () ->
    # We need to `watchPathChange` so that the answer also gets updated when we change page.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer()?.tt
    if savedAnswer? and _.isArray(savedAnswer) and savedAnswer.length>0
      if not _.isEqual(ix.truthTable.getValuesFromTable(), savedAnswer)
        makeTableFromValues(savedAnswer)
    else
      # TODO check the table isn't already blank?
      if shallIAutoFillReferenceColumns()
        ix.setAnswerKey(ix.truthTable.getReferenceRowValues(), 'tt')
      resetTruthTable()

shallIAutoFillReferenceColumns = () ->
  folSentences = ix.getSentencesOrPremisesAndConclusion() or []
  return true if folSentences.length > 2
  nofSymbols = 0
  countSymbols = (e) -> nofSymbols +=1 if e.symbol?
  for e in folSentences
    e.walk( countSymbols )
  return nofSymbols > 5

nofRowsNeeded = () ->
  letters = ix.truthTable.getSentenceLetters()
  return Math.pow(2,letters.length)
      
Template.truth_table.helpers
  sentences : () ->
    folSentences = ix.getSentencesOrPremisesAndConclusion() or []
    ix.setDialectFromExerciseSet()
    return ({theSentence:x.toString({replaceSymbols:true}), idx:idx} for x, idx in folSentences)
  
  letters : () ->
    ({theLetter:l} for l in (ix.truthTable.getSentenceLetters() or []))
  rows : () ->
    values = ix.getAnswer()?.tt
    if values? and _.isArray(values) and values.length > 0 
      return getRowsFromValues(values)
    else
      result = (null for x in (ix.truthTable.getSentenceLetters() or []))
      result = result.concat( (null for x in (ix.getSentencesOrPremisesAndConclusion() or [])) )
      return result


addTypeahead = () ->
  return
  # $('.truthtable input').typeahead('destroy')
  # $('.truthtable input').typeahead({
  #   hint : false
  #   minLength : 0
  #   highlight : false
  # },{
  #   name : 'tf'
  #   async : false
  #   display : (value) -> value.tf
  #   source : (query, syncResults, asyncResults) ->
  #     if query in ['f','F','0']
  #       syncResults([{tf:"F", name:"false"}])
  #     else
  #       if query in ['t','T','1']
  #         syncResults([{tf:"T", name:"true"}])
  #       else
  #         syncResults([{tf:"T", name:"true"},{tf:"F", name:"false"}])
  #
  #   templates :
  #     empty : [
  #         '<div class="empty-message">',
  #           'unable to find any truth values matching what you entered',
  #         '</div>'
  #       ].join('\n')
  #     suggestion : (value) ->
  #       return "<div>#{value.tf} - #{value.name}<div>"
  # })

# Param `values` is an array of rows as created by `getValuesFromTable`.
makeTableFromValues = (values) ->
  resetTruthTable()
  for row in values
    $tr = $('.truthtable tbody tr').last()
    $inputs = $('input', $tr)
    $inputs.each (idx, input) ->
      $(input).val('T') if row[idx] is true
      $(input).val('F') if row[idx] is false
      $(input).val('') if row[idx] is null
    addTrToTable()
  #Now remove the last row we added
  $('.truthtable tbody tr').last().remove()


# Add a TR to the table.truthtable.  If `$tr` is given, add it after `$tr`.
addTrToTable = ($tr) ->
  $tr ?= $('.truthtable tbody tr').last()
  $newTr = $tr.clone()
  # Clear the input values in the new row.
  $('input', $newTr).val('')
  $tr.after($newTr)
  addTypeahead()
  return $newTr

resetTruthTable = () ->
  while $('.truthtable tbody tr').length > 0
    $('.truthtable tbody tr').last().remove()
  $tr = $('<tr></tr>')
  #add row
  for ignore in [1..nofColumnsNeededInTruthTable()]
    $td = $('<td class="center"><div class="input-field"><input maxlength="1" type="text" style="width:1em;"></div></td>')
    # .input-field
    #   input(maxlength="1", type="text", style="width:1em;")
    $tr.append($td)
  $tr.append('<td><i class="material-icons addRow">add_circle_outline</i></td>')
  $tr.append('<td><i class="material-icons removeRow">remove_circle_outline</i></td>')
  # td
  #   i.material-icons.addRow add_circle_outline
  # td
  #   i.material-icons.removeRow remove_circle_outline
  $('.truthtable tbody').append($tr)
  addTypeahead()

nofColumnsNeededInTruthTable = () ->
  ix.truthTable.getSentenceLetters().length + ix.getSentencesOrPremisesAndConclusion().length
  

Template.truth_table.events 
  'click .addRow' : (event, template) ->
    $tr = $(event.target).parents('tr')
    addTrToTable($tr)
    newValues = ix.truthTable.getValuesFromTable()
    ix.setAnswerKey(newValues, 'tt')
  'click .removeRow' : (event, template) ->
    $tr = $(event.target).parents('tr')
    $tr.remove()
    newValues = ix.truthTable.getValuesFromTable()
    ix.setAnswerKey(newValues, 'tt')
    if ix.getAnswer().TorF?
      ix.setAnswerKey( ix.radioToArray(), 'TorF')
    
  'blur .truthtable input' : (event, template) ->
    $input = $(event.target)
    if $input.val() in ['t','T','1']
      $input.val('T')
    else
      if $input.val() in ['f','F','0']
        $input.val('F')
    newValues = ix.truthTable.getValuesFromTable()
    ix.setAnswerKey(newValues, 'tt')
  # These events never fired, or at least this handler was never called
  # 'typeahead:change .typeahead' : (event, template) ->
  #   $input = $(event.target)
  #   console.log 'typeahead:change event'
  #   console.log $input
  #   console.log  $input.typeahead('val')
  #   if $input.typeahead('val') in ['t','T','1']
  #     $input.typeahead('val','T')
  #   else
  #     if $input.typeahead('val') in ['f','F','0']
  #       $input.typeahead('val','F')
  #     else
  #       $input.typeahead('val','')
  #   newValues = ix.truthTable.getValuesFromTable()
  #   ix.setAnswerKey(newValues, 'tt')

getRowsFromValues = (values) ->
  result = []
  for row in values
    result.push( {values:({value:valueToText(v)} for v in row)} )
  return result
valueToText = (v) -> (("T" if v) or ("F" if v is false)) or ("" if v is null)


Template.truth_table_static.helpers
  letters : () ->
    self = this
    ({theLetter:l} for l in (ix.truthTable.getSentenceLetters(self) or []))
  sentences : () ->
    self = this
    ss = ix.getSentencesOrPremisesAndConclusion(self) or []
    ix.setDialectFromExerciseSet()
    return ({theSentence:x.toString({replaceSymbols:true}), idx} for x, idx in ss)
  rows : () ->
    return getRowsFromValues(@answer.content.tt)
