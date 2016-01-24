CLIENT_SERVER_DELAY = 5000;

LOGIN_EMAIL = 'tester@'
LOGIN_PW = 'tester'
# URL = 'http://logic-ex.butterfill.com/sign-in'
URL = 'http://logic-ex-test.butterfill.com/sign-in'
# URL = 'http://localhost:3000/sign-in'

try
  slimer
catch e
  require('es6-shim')

x = require('casper').selectXPath


# if getCasperEngine() is  'phantom'
#   require('es6-shim')

casper.options.viewportSize = {width: 1436, height: 805}

# This ensures tests fail if there’s an error in the code behind a template which Meteor catches
casper.on 'remote.message', (message) ->
  if message.startsWith('Exception in template helper')
    @echo 'error caught: ' + message
    throw new Error "meteor exception in template"

casper.on 'page.error', (msg, trace) ->
  @echo('Error: ' + msg, 'ERROR')
  for step in trace
    @echo('   ' + step.file + ' (line ' + step.line + ')', 'ERROR')


casper.test.begin 'open a logic-ex page', (test) ->
  
  casper.start URL, () ->
    test.assertTitle 'love-logic', 'title is unchanged'
    @waitForSelector 'body', () ->
      # log out (phantomjs stores session)
      test.assertEval () ->
        Meteor.logout()
        FlowRouter.go('/sign-in')
        return true
    @evaluate () ->
      FlowRouter.go('/sign-in')
        
  casper.then () ->
    @capture 'login.png'
    @waitForSelector 'form#at-pwd-form', () ->
      test.assertExists 'form#at-pwd-form', 'login form is found'
      this.fill 'form#at-pwd-form', { 'at-field-email':LOGIN_EMAIL, 'at-field-password':LOGIN_PW}, true
  
  # Check that I can see some courses
  casper.then () ->
    @waitForSelector 'a[href="/courses"]', () ->
      test.assertEval (txt) ->
        return $("body:contains(#{txt})").length > 0
      , "logged in, link to select course exists, page displays my email address"
      , LOGIN_EMAIL

  
  # --- reset tester
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go('/resetTester')
      return true
    @waitForSelector '.itIsDone'


  # --- tests for /ex/TorF 
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go '/ex/TorF/from/Either%20the%20pig%20went%20up%20the%20left%20fork%20or%20it%20went%20up%20the%20right%20fork%7CThe%20pig%20didn’t%20go%20up%20the%20left%20fork/to/The%20pig%20went%20up%20the%20right%20fork/qq/The%20argument%20is%20logically%20valid?variant=normal-normal&courseName=UK_W20_PH126&lectureName=Lecture%2001&unitName=The%20Pigs%20of%20Logic'
      txt = "Consider this argument"
      return $("body:contains(#{txt})").length > 0
    test.assertEval () ->
      txt = "The argument is logically valid."
      return $("body:contains(#{txt})").length > 0
    , "the question is asked" 
    test.assertExists '.trueOrFalse', "a true or false selector exists"
    
  # give correct answer and check it’s marked correctly
  casper.then () ->
    @click 'label.true'
    @waitForSelector 'button#submit', () ->
      @click 'button#submit'      
  casper.then () ->
    @waitForSelector ".submittedAnswer", () ->
      test.assertEval () ->
        txt = "is correct"
        return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
      , "the correct answer is submitted and marked correctly" 
      
  # give incorrect answer and check it’s marked correctly
  # TODO: this should really wait until there’s a second .submittedAnswer (so might fail just because it’s a badly written test!)
  casper.then () ->
    @click 'label.false'
    @waitForSelector 'button#submit', () ->
      @click 'button#submit'
  casper.then () ->
    # nasty xpath selector for the second .submittedAnswer
    @waitForSelector x('//*[contains(concat(" ", normalize-space(@class), " "), " submittedAnswer ")][2]'), () ->
      @wait 50, () ->
        test.assertEval () ->
          txt = "is incorrect"
          return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
        , "the incorrect answer is submitted and marked correctly" 

  
  # ---  tests for navigation
  
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go '/ex/TorF/qq/a%20logically%20valid%20argument%20cannot%20have%20a%20false%20conclusion%7Ca%20logically%20valid%20argument%20cannot%20have%20false%20premises?variant=normal&courseName=_test&lectureName=lecture_03&unitName=Formal%20Proof:%20%E2%88%A7Elim%20and%20%E2%88%A7Intro'
      txt = "Which of the following are true and which false?"
      return $("body:contains(#{txt})").length > 0
    , "the question title is displayed"
    test.assertEval () ->
      txt = "A logically valid argument cannot have a false conclusion"
      return $("body:contains(#{txt})").length > 0
    , "the first task is displayed"
    test.assertEval () ->
      txt = "A logically valid argument cannot have false premises"
      return $("body:contains(#{txt})").length > 0
    , "the second task is displayed"
  
  casper.then () ->
    @wait 50, () ->
      @click 'label.true'
    @waitForSelector 'button#submit', () ->
      @click 'button#submit'      
  casper.then () ->
    @waitForSelector ".submittedAnswer", () ->
      test.assertEval () ->
        txt = "is incorrect"
        return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
      , "the incomplete answer is submitted and marked correctly" 
  casper.then () ->
    @click 'label.true[for="true_for_1"]'
    @click 'button#submit'      
  casper.then () ->
    # @waitForSelector ".submittedAnswer", () ->
    # nasty xpath selector for the second .submittedAnswer
    @waitForSelector x('//*[contains(concat(" ", normalize-space(@class), " "), " submittedAnswer ")][2]'), () ->
      test.assertEval () ->
        txt = "is incorrect"
        return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
      , "the incorrect answer is submitted and marked correctly" 
      
  casper.then () ->
    @wait 50, () ->
      @click 'label.false[for="false_for_0"]'
    @wait 50, () ->
      @click 'label.false[for="false_for_1"]'
    @wait 50, () ->
      @click 'button#submit'      
  casper.then () ->
    # @waitForSelector ".submittedAnswer", () ->
    # nasty xpath selector for the second .submittedAnswer
    @waitForSelector x('//*[contains(concat(" ", normalize-space(@class), " "), " submittedAnswer ")][3]'), () ->
      test.assertEval () ->
        txt = "is correct"
        return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
      , "the correct answer is submitted and marked correctly" 
    
  
  casper.then () ->
    @capture 'TorF.png'
    
  
  

  
  casper.run () ->
    test.done()

