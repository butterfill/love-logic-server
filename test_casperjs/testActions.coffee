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
    LOGIN_EMAIL = config.LOGIN_EMAIL
    LOGIN_PW = config.LOGIN_PW
    @waitForSelector 'form#at-pwd-form', () ->
      test.assertExists 'form#at-pwd-form', 'login form is found'
      @fill 'form#at-pwd-form', { 'at-field-email':LOGIN_EMAIL, 'at-field-password':LOGIN_PW}, true
  casper.then () ->
    @wait 50, () ->
      test.assertEval () ->
        FlowRouter.go('/')
        return true
    @waitForSelector 'a[href="/courses"]', () ->
    @waitForSelector x("//*[contains(., 'Sign Out' )]"), () ->
  casper.then () ->
    @waitForSelector 'a[href="/courses"]', () ->
      test.assertEval (txt) ->
        return $("body:contains(#{txt})").length > 0
      , "logged in, home page displays my email address"
      , config.LOGIN_EMAIL
      
exports.doLogin = doLogin

exports.resetTester = (casper, test) ->
  casper.then () ->
    @evaluate () ->
      FlowRouter.go('/resetTester')
    @wait 100, () ->
      @capture 'resetTester.png'
      @waitForSelector '.itIsDone', () ->
        test.assertExists '.itIsDone'

