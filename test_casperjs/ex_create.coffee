x = require('casper').selectXPath

pwd = '.'
config = require("#{pwd}/config")
config.configure(casper)

pageObjects = require("#{pwd}/pageObjects")
testActions = require("#{pwd}/testActions")



casper.test.begin 'open a logic-ex page', (test) ->

  casper.start config.URL, () ->
    test.assertTitle 'love-logic', 'title is unchanged'
    test.assertExists '.brand-logo', 'logo is found'
  
  x = require('casper').selectXPath
  
  testActions.doLogin(casper, test, x)
        
  testActions.resetTester(casper, test, x)

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
      @wait 50, () ->
        @click 'button#submit'      
    casper.then () ->
      # DOESNT WORK (never found)
      # @waitForSelector x("//*[text()='answer is incorrect']"), () ->
      # DOESNT WORK (never found)
      # nasty xpath selector for the second .submittedAnswer
      @waitForSelector x('//*[contains(concat(" ", normalize-space(@class), " "), " submittedAnswer ")][2]'), () ->
        @wait 50, () ->
          test.assertEval () ->
            txt = "is incorrect"
            return $(".submittedAnswer:eq(0):contains(#{txt})").length > 0
          , "the incorrect answer is submitted and marked correctly" 
    
  
  casper.then () ->
    @capture 'create.png'
    
  
  casper.run () ->
    test.done()

