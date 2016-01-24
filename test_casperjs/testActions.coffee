pwd = '.'
pageObjects = require("#{pwd}/pageObjects")

config = require("#{pwd}/config")




doLogin = (casper, test, x) ->
  
  loginPage = pageObjects.LoginPageObject(casper, test, x)
  casper.then () ->
    @waitForSelector 'body', () ->
      loginPage.logout()
  casper.then () ->
    loginPage.goSignIn()
  casper.then () ->
    @capture 'login.png'
    @waitForSelector 'form#at-pwd-form', () ->
      test.assertExists 'form#at-pwd-form', 'login form is found'
  # casper.then () ->
  #   LOGIN_EMAIL = config.LOGIN_EMAIL
  #   LOGIN_PW = config.LOGIN_PW
  #   @fill 'form#at-pwd-form', { 'at-field-email':LOGIN_EMAIL, 'at-field-password':LOGIN_PW}, true
  #   @capture 'login-done.png'
  # casper.then () ->
  #   @wait 50, () ->
  #     test.assertEval () ->
  #       FlowRouter.go('/')
  #       return true
  #   # @waitForSelector 'a[href="/courses"]', () ->
  #   # @waitForSelector x("//*[contains(., 'Sign Out' )]"), () ->
  # casper.then () ->
  #   @waitForSelector 'a[href="/courses"]', () ->
  #     test.assertEval (txt) ->
  #       return $("body:contains(#{txt})").length > 0
  #     , "logged in, home page displays my email address"
  #     , config.LOGIN_EMAIL
      


  casper.then () ->
    LOGIN_EMAIL = config.LOGIN_EMAIL
    LOGIN_PW = config.LOGIN_PW
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



exports.doLogin = doLogin

exports.resetTester = (casper, test) ->
  casper.then () ->
    @evaluate () ->
      FlowRouter.go('/resetTester')
    @wait 100, () ->
      @capture 'resetTester.png'
      @waitForSelector '.itIsDone', () ->
        test.assertExists '.itIsDone'

