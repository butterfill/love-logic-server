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

  # Can go to an exericse, write some answer and submit it
  casper.then () ->
    @evaluate () ->
      FlowRouter.go '/ex/q/define ‘logically valid argument’'
    @waitForSelector '#submit', () ->
      console.log 'page loaded'
  casper.then () ->
    @waitForSelector '.CodeMirror', () ->
      test.assertEval () ->
        txt = "define ‘logically valid argument’"
        return $("body:contains(#{txt})").length > 0
      , "the question is displayed" 
      test.assertExists '.CodeMirror', "the editor exists"
  casper.then () ->
    @waitForSelector ".CodeMirror.cm-s-blackboard.CodeMirror-focused textarea", () ->
      @sendKeys(".CodeMirror.cm-s-blackboard.CodeMirror-focused textarea", "This is a wrong answer.")
    @wait 75, () ->
      @click("button#submit")
    @waitForSelector x("//*[contains(text(), 'submitted an answer')]"), () ->
      test.assertExists x("//*[contains(text(), 'submitted an answer')]")
  
  # Attempting to submit a blank exercise does not create an error
  casper.then () ->
    @evaluate () ->
      FlowRouter.go '/ex/q/Write nothing'
    @waitForSelector '#submit', () ->
      console.log 'page loaded'
  casper.then () ->
    @waitForSelector '.CodeMirror', () ->
      test.assertExists '.CodeMirror', "the editor exists"
  casper.then () ->
    @wait 75, () ->
      @click("button#submit")
    @waitForSelector x("//*[contains(text(), 'submitted an answer')]"), () ->
      test.assertExists x("//*[contains(text(), 'submitted an answer')]")
    
  
  casper.then () ->
    @capture 'q.png'
    
  
  casper.run () ->
    test.done()

