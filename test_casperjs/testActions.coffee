pwd = '.'
pageObjects = require("#{pwd}/pageObjects")

config = require("#{pwd}/config")


x = require('casper').selectXPath


doLogin = (casper, test) ->
  loginPage = pageObjects.LoginPageObject(casper, test)
  casper.then () ->
    @waitForSelector 'body', () ->
      loginPage.logout()
  casper.then () ->
    loginPage.goSignIn()
  casper.then () ->
    @capture 'login.png'
    @waitForSelector 'form#at-pwd-form', () ->
      test.assertExists 'form#at-pwd-form', 'login form is found'
      @fill 'form#at-pwd-form', { 'at-field-email':config.LOGIN_EMAIL, 'at-field-password':config.LOGIN_PW}, true
  casper.then () ->
    @wait 50, () ->
      test.assertEval () ->
        FlowRouter.go('/')
        return true
    @waitForSelector x("//*[contains(., 'Sign Out' )]"), () ->
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

