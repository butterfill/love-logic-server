x = require('casper').selectXPath

pwd = '.'
config = require("#{pwd}/config")
config.configure(casper)

pageObjects = require("#{pwd}/pageObjects")
testActions = require("#{pwd}/testActions")




casper.test.begin 'open a logic-ex page', (test) ->
  
  casper.start config.URL, () ->
    test.assertTitle 'love-logic', 'title is unchanged'
    # @capture 'login.png'
    test.assertExists '.brand-logo', 'logo is found'
  
  x = require('casper').selectXPath
  
  testActions.doLogin(casper, test, x)
  
  testActions.resetTester(casper, test, x)



  # --- tests for /ex/tt

  # /ex/tt/qq/A and not A
  
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go '/ex/tt/qq/A and not A'
      txt = "truth table for this sentence"
      return $("body:contains(#{txt})").length > 0
    , "the question title is correctly displayed"
  
    test.assertEval () ->
      return $('.trueOrFalseInputs').length is 3
    , "the correct number of questions about the truth table appear"

    test.assertEval () ->
      txt = "is a logical truth"
      return $("body:contains(#{txt})").length > 0
    , "the question about logical truth is displayed"
  
  # /ex/tt/from/A and not A/to/B and not B
  
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go '/ex/tt/from/A and not A/to/B and not B'
      txt = "truth tables for this argument"
      return $("body:contains(#{txt})").length > 0
    , "the question title is displayed"
    
    test.assertEval () ->
      premises = ix.getPremisesFromParams()
      ok = true
      for p in premises
        ok = false unless p.getSentenceLetters?
      conclusion = ix.getConclusionFromParams()
      ok = false unless conclusion.getSentenceLetters?
      return ok
    , "everything is ok with getting the parameters from the question and parsing them as FOL"
    
    test.assertEval () ->
      txt = "The argument is logically valid"
      return $("body:contains(#{txt})").length > 0
    , "the questions about the truth table are displayed"
  
  casper.then () ->
    @waitForSelector '.addRow', () ->
      @capture 'ttrows.png'
      @evaluate () ->
        console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
      @click '.addRow'
      @evaluate () ->
        console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
      @click '.addRow'
      @evaluate () ->
        console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
      @click '.addRow'
      @evaluate () ->
        console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
    @wait 25
    
  casper.then () ->
    test.assertEval () ->
      txt = "is a counterexample to the argument."
      return $("body:contains(#{txt})").length > 0
    , "a question about counterexamples is displayed"
     
    test.assertEval () ->
      return true if $(".truthtable tbody tr").length is 4
      console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
      return false
    , "the correct number of rows appear  [ignore phantomjs sporadic fail]"
      
    test.assertEval () ->
      return true if $('.trueOrFalseInputs').length is 5
      console.log "$('.trueOrFalseInputs').length = #{$('.trueOrFalseInputs').length}"
      return false
    , "the correct number of questions about the truth table appear  [ignore phantomjs sporadic fail]"
      
  casper.then () ->
    @click '.removeRow'
    @wait 25
  casper.then () ->
    test.assertEval () ->
      return true if $(".truthtable tbody tr").length is 3
      console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
      return false
    , "the correct number of rows appear after removing one"
    test.assertEval () ->
      return $('.trueOrFalseInputs').length is 4
    , "the correct number of questions about the truth table appear after removing a row of the truth table  [ignore phantomjs sporadic fail]"
    
    
  casper.then () ->
    @click '.addRow'
  casper.then () ->
    test.assertEval () ->
      return true if $(".truthtable tbody tr").length is 4
      console.log "$('.truthtable tbody tr').length = #{$('.truthtable tbody tr').length}"
      return false
    , "the correct number of rows appear after adding one back [ignore phantomjs sporadic fail]"
  
  casper.then () ->
    @evaluate () ->
      rows = [
        ['T','T','F','F']
        ['T','F','F','F']
        ['F','T','F','F']
        ['F','F','F','F']
      ]
      for rIdx in [0..3]
        row = rows[rIdx]
        for cIdx in [0..3]
          theVal = row[cIdx]
          $(".truthtable tbody tr:eq(#{rIdx}) td:eq(#{cIdx}) input").val( theVal )
  casper.then () ->
    @waitForSelector 'button#submit', () ->
      @wait 500, () ->
        @click 'button#submit'
    @waitForSelector ".submittedAnswer", () ->
      test.assertEval () ->
        txt = "truth table is correct but"
        return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
      , "the partially correct answer is submitted and marked" 
    
  casper.then () ->
    # For some reason this is necessary; otherwise clicking the label 
    # resets the truthtable!
    @waitForSelector '#view-answer', () ->
      @wait 25, () ->
        @click '#view-answer'
      
  casper.then () ->
    @wait 50, () ->
      @click 'label[for="true_for_0"]'
    @wait 50, () ->
      @click 'label[for="false_for_1"]'
    @wait 50, () ->
      @click 'label[for="false_for_2"]'
    @wait 50, () ->
      @click 'label[for="false_for_3"]'
    @wait 50, () ->
      @click 'label[for="false_for_4"]'
    @wait 150, () ->
      @click 'button#submit'
  casper.then () ->
    @waitForSelector x("//*[contains(.,'Your answer is correct')]"), () ->
      @wait 50, () ->
        @capture 'step2.png'
        test.assertEval () ->
          console.log "step 2 submittedAnswer #{$('.submittedAnswer').text()}"
          txt = "Your answer is correct"
          return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
        , "the correct answer is submitted and marked correctly" 
  
  casper.then () ->
    @wait 25, () ->
      # nasty xpath selector for the fourth .addRow
      @click x('(//*[contains(concat(" ", normalize-space(@class), " "), " addRow ")])[4]')
    @waitForSelector 'label[for="false_for_5"]', () ->
      @wait 25, () ->
        @click 'label[for="false_for_5"]'
    @waitForSelector x('(//*[contains(concat(" ", normalize-space(@class), " "), " removeRow ")])[5]'), () ->
      @wait 25, () ->
        @click x('(//*[contains(concat(" ", normalize-space(@class), " "), " removeRow ")])[5]')
  casper.then () ->
    @wait 25, () ->
      @click 'button#submit'
    @waitForSelector ".submittedAnswer", () ->
      # Need to wait for the server to update the correctness of the answer!
      @wait 500, () ->
        test.assertEval () ->
          console.log "after extended submittedAnswer #{$('.submittedAnswer').text()}"
          console.log "ix.getAnswer().TorF = #{ix.getAnswer().TorF}"
          txt = "Your answer is correct"
          return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
        , "the correct answer is submitted and marked correctly even after extending the truth table" 
    
    
  
  
  casper.then () ->
    @capture 'tt.png'
    
  
  casper.run () ->
    test.done()

