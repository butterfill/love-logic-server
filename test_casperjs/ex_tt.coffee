CLIENT_SERVER_DELAY = 5000;

LOGIN_EMAIL = 'tester@'
LOGIN_PW = 'tester'
# URL = 'http://logic-ex.butterfill.com/sign-in'
# URL = 'http://logic-ex-test.butterfill.com/sign-in'
URL = 'http://localhost:3000/sign-in'


try
  slimer
catch e
  require('es6-shim')
  localStorage.clear()


casper.options.viewportSize = {width: 1436, height: 805}


# This ensures tests fail if there’s an error in the code behind a template which Meteor catches
casper.on 'remote.message', (message) ->
  # if message.startsWith('Exception in template helper')
  @echo 'console: ' + message.substring(0,300)
    # throw new Error "meteor exception in template"

casper.on 'page.error', (msg, trace) ->
  @echo('Error: ' + msg, 'ERROR')
  # for step in trace
  #   @echo('   ' + step.file + ' (line ' + step.line + ')', 'ERROR')



casper.test.begin 'open a logic-ex page', (test) ->
  
  casper.start URL, () ->
    test.assertTitle 'love-logic', 'title is unchanged'
    # @capture 'login.png'
    test.assertExists '.brand-logo', 'logo is found'
    @waitForSelector 'body', () ->
      # log out (phantomjs stores session)
      test.assertEval () ->
        Meteor.logout()
        FlowRouter.go('/sign-in')
        return true
    @wait 25

  casper.then () ->
    @capture 'login.png'
    @waitForSelector 'form#at-pwd-form', () ->
      test.assertExists 'form#at-pwd-form', 'login form is found'
      this.fill 'form#at-pwd-form', { 'at-field-email':LOGIN_EMAIL, 'at-field-password':LOGIN_PW}, true

  # --- reset tester
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go('/resetTester')
      return true
    @waitForSelector '.itIsDone'



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
    , "the correct number of rows appear"
      
    test.assertEval () ->
      return true if $('.trueOrFalseInputs').length is 5
      console.log "$('.trueOrFalseInputs').length = #{$('.trueOrFalseInputs').length}"
      return false
    , "the correct number of questions about the truth table appear"
      
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
    , "the correct number of questions about the truth table appear after removing a row of the truth table"
    
    
  casper.then () ->
    @click '.addRow'
    
  casper.then () ->
    @capture 'tt.png'
    
  
  casper.run () ->
    test.done()

