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


casper.options.viewportSize = {width: 1436, height: 805}


# This ensures tests fail if there’s an error in the code behind a template which Meteor catches
casper.on 'remote.message', (message) ->
  if message.startsWith('Exception in template helper')
    @echo 'error caught: ' #+ message
    throw new Error "meteor exception in template"

casper.on 'page.error', (msg, trace) ->
  @echo('Error: ' + msg, 'ERROR')
  for step in trace
    @echo('   ' + step.file + ' (line ' + step.line + ')', 'ERROR')



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

  casper.then () ->
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
      @click 'a[href="/courses"]'
      @waitForSelector 'a[href="/course/UK_W20_PH126"]', () ->
        test.assertExists 'a[href="/course/UK_W20_PH126"]', 'PH126 exercises are shown'
        test.assertExists 'a[href="/course/UK_W20_PH133"]', 'PH133 exercises are shown'

  # TODO: get an exercise set and visit all the links


  # --- reset tester
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go('/resetTester')
      return true
    @waitForSelector '.itIsDone'



  # --- tests for /ex/create 
  casper.then () ->
    test.assertEval () ->
      FlowRouter.go '/ex/create/orValid/from/LeftOf(a%2Cb)%7CLeftOf(b%2Cc)/to/LeftOf(a%2Cc)'
      return true
    
    test.assertEval () ->
      FlowRouter.go '/ex/create/orInconsistent/qq/LeftOf(a%2Cd)%7CLeftOf(b%2Cc)'
      txt = "Unless they are logically inconsistent, make"
      return $("body:contains(#{txt})").length > 0
    , "create/orInconsistent exercise has correct caption" 
    test.assertExists '.trueOrFalse', "a true or false selector exists"
    
    test.assertEval () ->
      FlowRouter.go '/ex/create/qq/LeftOf(a%2Cd)%7CLeftOf(b%2Cc)'
      txt = "Unless they are logically inconsistent, make"
      return $("body:contains(#{txt})").length is 0
    , "create/qq/... exercise has correct caption" 
    test.assertDoesntExist '.trueOrFalse', "a true or false selector is NOT shown"

    test.assertEval () ->
      FlowRouter.go '/ex/create/orInconsistent/qq/LeftOf(a%2Cd)%7CLeftOf(b%2Cc)'
      txt = "Unless they are logically inconsistent, make"
      return $("body:contains(#{txt})").length > 0
    , "create/orInconsistent exercise has correct caption even after visiting create/qq/..."  
    test.assertExists '.trueOrFalse', "a true or false selector exists"
    
    test.assertEval () ->
      FlowRouter.go '/ex/create/orValid/from/LeftOf(a%2Cb)%7CLeftOf(b%2Cc)/to/LeftOf(a%2Cc)'
      txt = "Unless it is logically valid, give"
      return $("body:contains(#{txt})").length > 0
    , "create/orValid exercise has correct caption" 
    test.assertExists '.trueOrFalse', "a true or false selector exists"
    
    test.assertEval () ->
      FlowRouter.go '/ex/create/from/LeftOf(a%2Cb)%7CLeftOf(b%2Cc)/to/LeftOf(a%2Cc)'
      txt = "Unless it is logically valid, give"
      return $("body:contains(#{txt})").length is 0
    , "create/from exercise has correct caption" 
    test.assertDoesntExist '.trueOrFalse', "a true or false selector is NOT shown"

    test.assertEval () ->
      FlowRouter.go '/ex/create/orValid/from/LeftOf(a%2Cb)%7CLeftOf(b%2Cc)/to/LeftOf(a%2Cc)'
      txt = "Unless it is logically valid, give"
      return $("body:contains(#{txt})").length > 0
    , "create/orValid exercise has still correct caption (even after visiting a create/from exercise)" 
    test.assertExists '.trueOrFalse', "a true or false selector exists"
  
    casper.then () ->
      @click 'label.true[for="true_for_0"]'
      @waitForSelector 'button#submit', () ->
        @click 'button#submit'      
    casper.then () ->
      @waitForSelector ".submittedAnswer", () ->
        test.assertEval () ->
          txt = "is correct"
          return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
        , "the correct answer is submitted and marked correctly" 
    
    casper.then () ->
      @click 'label.false[for="false_for_0"]'
      @click 'button#submit'      
    casper.then () ->
      @waitForSelector ".submittedAnswer", () ->
        test.assertEval () ->
          txt = "is incorrect"
          return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
        , "the incorrect answer is submitted and marked correctly" 
    
  
  casper.then () ->
    @capture 'create.png'
    
  
  casper.run () ->
    test.done()

