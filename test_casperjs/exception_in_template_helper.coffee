x = require('casper').selectXPath

pwd = '.'
config = require("#{pwd}/config")
config.configure(casper)

pageObjects = require("#{pwd}/pageObjects")
testActions = require("#{pwd}/testActions")


# THIS TEST IS SUPPOSED TO FAIL
# (It’s purpose is to check that exceptions in template helpers cause tests to fail!)


casper.test.begin 'SHOULD FAIL: check test fails if there is an exception in a template helper', (test) ->

  casper.start config.URL, () ->
    # nothing to do.
  
  x = require('casper').selectXPath
  
  testActions.doLogin(casper, test, x)
        
  # Can go to an exericse, write some answer and submit it
  casper.then () ->
    @evaluate () ->
      FlowRouter.go '/testThrowException'
    @waitForSelector '.testThrowExceptionIsHere', () ->
      console.log 'page loaded'
        
  casper.then () ->
    @capture 'img/exception.png'
    
  
  casper.run () ->
    test.done()

