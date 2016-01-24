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
    
  testActions.doLogin(casper, test)
        
  testActions.resetTester(casper, test)

  # Check that I can see some courses
  casper.then () ->
    @evaluate () ->
      FlowRouter.go('/')
    @waitForSelector 'a[href="/courses"]', () ->
      test.assertEval (txt) ->
        return $("body:contains(#{txt})").length > 0
      , "logged in, link to select course exists, page displays my email address"
      , config.LOGIN_EMAIL


  # TODO: get an exercise set and visit all the links

  
  casper.run () ->
    test.done()
