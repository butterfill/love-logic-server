pwd = '.'
pageObjects = require("#{pwd}/pageObjects")

config = require("#{pwd}/config")




exports.doLogin = (casper, test, x) ->
  
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
  casper.then () ->
    LOGIN_EMAIL = config.LOGIN_EMAIL
    LOGIN_PW = config.LOGIN_PW
    @fill 'form#at-pwd-form', { 'at-field-email':LOGIN_EMAIL, 'at-field-password':LOGIN_PW}, true
    @capture 'login-done.png'
  casper.then () ->
    @wait 50, () ->
      test.assertEval () ->
        FlowRouter.go('/')
        return true
  casper.then () ->
    # @waitForSelector 'a[href="/courses"]', () ->
    @waitForSelector x("//*[contains(., 'Sign Out' )]"), () ->
      test.assertEval (txt) ->
        return $("body:contains(#{txt})").length > 0
      , "logged in, home page displays my email address"
      , config.LOGIN_EMAIL


exports.resetTester = (casper, test) ->
  casper.then () ->
    @evaluate () ->
      FlowRouter.go('/resetTester')
    @wait 100, () ->
      @capture 'resetTester.png'
      @waitForSelector '.itIsDone', () ->
        test.assertExists '.itIsDone'


exports.visitPage = (url, casper, test) ->
  casper.then () ->
    @wait 15, () ->
      # it’s good to wait.
      @evaluate( ((url) ->FlowRouter.go url), url )
  casper.then () ->
    @wait 15, () ->
      @waitWhileSelector '.pageIsLoading', () ->
        console.log "loaded #{url}"
        test.assertDoesntExist '.pageIsLoading'
