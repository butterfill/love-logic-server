
LoginPageObject = (c, t) ->
  return {
    logout : () ->
      c.evaluate () ->
        Meteor.logout()
    goSignIn : () ->
      c.evaluate () ->
        FlowRouter.go('/sign-in')
      c.then () ->
        @waitForSelector 'form#at-pwd-form'
  }
exports.LoginPageObject = LoginPageObject