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
  
  # TODO: move to util module
  # NB: this function doesn’t find the text element but all elements 
  # containing the text (so will return parents).
  xFindText = (text) -> x("//*[contains( normalize-space(.), '#{text}' )]")
  
  testActions.doLogin(casper, test, x)
        
  testActions.resetTester(casper, test, x)

  url = '/ex/create/qq/Above(a,b)'
  testActions.visitPage( encodeURIComponent(url), casper, test)

  casper.waitForSelector 'button#addElement', (->
    test.assertExists 'button#addElement'
    @click 'button#addElement'
    return
  ), ->
    test.assertExists 'button#addElement'
    return
  
  casper.then () ->
    casper.waitForSelector x('//*[contains(text(), \'The name a is not defined\')]'), (->
      test.assertExists x('//*[contains(text(), \'The name a is not defined\')]')
      return
    ), ->
      test.assertExists x('//*[contains(text(), \'The name a is not defined\')]')
      return
    casper.waitForSelector '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', (->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      @click '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    ), ->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', (->
      @sendKeys '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', 'a'
      # tried to get a blur to update the name, didn't work
      # @page.sendEvent("blur")
      # @click '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      # @sendKeys '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', ',a',  { keepFocus: true }
      return
    ), ->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector '#feedback', (->
      test.assertExists '#feedback'
      @click '#feedback'
      return
    ), ->
      test.assertExists '#feedback'
      return
  casper.then () ->
    # casper.waitForSelector x('//*[contains(text(), \'The name b is not defined\')]'), (->
    #   test.assertExists x('//*[contains(text(), \'The name b is not defined\')]')
    #   return
    # ), ->
    #   test.assertExists x('//*[contains(text(), \'The name b is not defined\')]')
    #   return
    casper.waitForSelector 'button#submit', (->
      test.assertExists 'button#submit'
      @click 'button#submit'
      return
    ), ->
      test.assertExists 'button#submit'
      return
    casper.waitForSelector '.row.submittedAnswer .col.s12 > .right', (->
      test.assertExists '.row.submittedAnswer .col.s12 > .right'
      @click '.row.submittedAnswer .col.s12 > .right'
      return
    ), ->
      test.assertExists '.row.submittedAnswer .col.s12 > .right'
      return
    # @waitForSelector x("//*[contains(text(), 'submitted an answer')]"), () ->
    
    
    casper.waitForSelector xFindText('answer is incorrect'), (->
      test.assertExists xFindText('answer is incorrect')
      return
    ), ->
      test.assertExists xFindText('answer is incorrect')
      return
    casper.waitForSelector '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input', (->
      test.assertExists '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input'
      @click '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input'
      return
    ), ->
      test.assertExists '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input', (->
      @sendKeys '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input', 'b'
      return
    ), ->
      test.assertExists '.grid-stack-item-content.white.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector 'button#submit', (->
      test.assertExists 'button#submit'
      @click 'button#submit'
      return
    ), ->
      test.assertExists 'button#submit'
      return
    casper.waitForSelector '.row.submittedAnswer span:nth-child(4)', (->
      test.assertExists '.row.submittedAnswer span:nth-child(4)'
      @click '.row.submittedAnswer span:nth-child(4)'
      return
    ), ->
      test.assertExists '.row.submittedAnswer span:nth-child(4)'
      return
    casper.waitForSelector xFindText('Your answer is correct'), (->
      test.assertExists xFindText('Your answer is correct')
      return
    ), ->
      test.assertExists xFindText('Your answer is correct')
      return
    casper.waitForSelector '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', (->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      @click '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    ), ->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', (->
      @sendKeys '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', ',b'
      return
    ), ->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector '#feedback', (->
      test.assertExists '#feedback'
      @click '#feedback'
      @click 'button#submit'
      return
    ), ->
      test.assertExists '#feedback'
      return
    casper.waitForSelector xFindText('You cannot give the name'), (->
      test.assertExists xFindText('You cannot give the name')
      return
    ), ->
      test.assertExists xFindText('You cannot give the name')
      return
    casper.waitForSelector 'button#submit', (->
      test.assertExists 'button#submit'
      @click 'button#submit'
      return
    ), ->
      test.assertExists 'button#submit'
      return
    casper.waitForSelector '.row.submittedAnswer span:nth-child(4)', (->
      test.assertExists '.row.submittedAnswer span:nth-child(4)'
      @click '.row.submittedAnswer span:nth-child(4)'
      return
    ), ->
      test.assertExists '.row.submittedAnswer span:nth-child(4)'
      return
    casper.waitForSelector xFindText('Your answer is incorrect'), (->
      test.assertExists xFindText('Your answer is incorrect')
      return
    ), ->
      test.assertExists xFindText('Your answer is incorrect')
      return
    casper.waitForSelector '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input', (->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      @click '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      @evaluate () ->
        $('.grid-stack-item-content.yellow input').val('a')
      return
    ), ->
      test.assertExists '.grid-stack-item-content.yellow.lighten-2.ui-draggable-handle input'
      return
    casper.waitForSelector 'button#submit', (->
      test.assertExists 'button#submit'
      @click 'button#submit'
      return
    ), ->
      test.assertExists 'button#submit'
      return
    casper.waitForSelector '.row.submittedAnswer span:nth-child(4)', (->
      test.assertExists '.row.submittedAnswer span:nth-child(4)'
      @click '.row.submittedAnswer span:nth-child(4)'
      return
    ), ->
      test.assertExists '.row.submittedAnswer span:nth-child(4)'
      return
    casper.waitForSelector xFindText('Your answer is correct'), (->
      test.assertExists xFindText('Your answer is correct')
      return
    ), ->
      test.assertExists xFindText('Your answer is correct')
      return

    
  casper.then () ->
    @capture 'img/create2.png'
    
  
  casper.run () ->
    test.done()

