
Template.tt_ex.rendered = () ->
  templateInstance = this
  # Allow the answer to be updated by setting the session variable
  Tracker.autorun () ->
    # We need to `watchPathChange` so that the answer also gets updated when we change page.
    FlowRouter.watchPathChange()
    savedAnswer = ix.getAnswer() 
    if savedAnswer?
      if not _.isEqual(getValuesFromTable(), savedAnswer)
        makeTableFromValues(savedAnswer)



Template.tt_ex.helpers
  sentences : () ->
    folSentences = ix.getSentencesFromParam()
    return ({theSentence:x.toString({replaceSymbols:true}), idx:idx} for x, idx in folSentences)
  letters : () ->
    ({theLetter:l} for l in getSentenceLetters())
    

checkAnswer = (values) ->
  values ?= getValuesFromTable()
  result = checkAnswerCorrectNofRows(values)
  return result unless result.isCorrect
  res2 = checkAnswerCorrectRowOrder(values)
  if not res2
    result.message += 'You did not order the rows correctly.'
    result.isCorrect = false
  
  lttrs = getSentenceLetters()
  sentences = ix.getSentencesFromParam()
  correctAnswers = []
  for row, rowIdx in values
    # console.log row
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

checkAnswerCorrectNofRows = (values) ->
  lttrs = getSentenceLetters()
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
checkAnswerCorrectRowOrder = (values) ->
  values = (_.clone(r) for r in values)
  lttrs = getSentenceLetters()
  expectedNofRows = Math.pow(2,lttrs.length)
  for num in [expectedNofRows-1..0]
    binaryStr = pad0(num.toString(2), lttrs.length)
    expected = (x is "1" for x in binaryStr)
    idx = (expectedNofRows-1)-num
    actual = values[idx].splice(0,lttrs.length)
    return false unless _.isEqual(expected, actual)
  return true
pad0 = (n, len) ->
  return n if n.length >= len
  # Thankyou http://stackoverflow.com/questions/10073699/pad-a-number-with-leading-zeros-in-javascript
  return new Array(len - n.length + 1).join('0') + n
    

getValuesFromTable = () ->
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
  console.log "getValuesFromTable result"
  console.log result
  return result
window.getValuesFromTable = getValuesFromTable

# Param `values` is an array of rows as created by `getValuesFromTable`.
makeTableFromValues = (values) ->
  console.log "updating"
  #TODO: make table have only one row
  while $('.truthtable tbody tr').length > 1
    $('.truthtable tbody tr').last().remove()
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
    

getSentenceLetters = () ->
  lttrs = []
  for s in ix.getSentencesFromParam()
    moreLttrs = s.getSentenceLetters()
    lttrs = lttrs.concat moreLttrs
  return _.uniq(lttrs)

# Add a TR to the table.truthtable.  If `$tr` is given, add it after `$tr`.
addTrToTable = ($tr) ->
  $tr ?= $('.truthtable tbody tr').last()
  $newTr = $tr.clone()
  # Clear the input values in the new row.
  $('input', $newTr).val('')
  $tr.after($newTr)
  return $newTr
  

Template.tt_ex.events 
  # 'click input' : save
  
  'click .addRow' : (event, template) ->
    $tr = $(event.target).parents('tr')
    addTrToTable($tr)
  'click .removeRow' : (event, template) ->
    $tr = $(event.target).parents('tr')
    $tr.remove()
    
  
  'blur .truthtable input' : (event, template) ->
    $input = $(event.target)
    if $input.val() in ['t','T','1']
      $input.val('T')
    else
      if $input.val() in ['f','F','0']
        $input.val('F')
      else
        $input.val('')
    newValues = getValuesFromTable()
    console.log checkAnswer(newValues)
    ix.setAnswer(newValues)
  
  # This button is provided by a the `submitted_answer` template.
  'click button#submit' : (event, template) ->
    Materialize.toast "Not implemented yet.", 4000
    # machineFeedback =
    #   isCorrect : result.isCorrect
    # if result.msg and result.msg isnt ''
    #   machineFeedback.comment = result.msg
    # ix.submitExercise({
    #     answer :
    #       type : 'TorF'
    #       content : answer
    #     machineFeedback : machineFeedback
    #   }, () ->
    #     Materialize.toast "Your answer has been submitted.", 4000
    # )



# ===================
# TorF_ex_display_answer


Template.tt_ex_display_question.helpers
  sentences : () ->
    ss = ix.getSentencesFromParam()
    ss = (x.toString({replaceSymbols:true}) for x in ss)
    ssObj = ({theSentence:x, idx} for x, idx in ss)
    return ssObj
