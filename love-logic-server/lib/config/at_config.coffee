# user accounts config.
# See https://github.com/meteor-useraccounts/core/blob/master/Guide.md
# See https://github.com/meteor-useraccounts/iron-routing

AccountsTemplates.configure
  defaultLayout: 'ApplicationLayout'
  enablePasswordChange: true
  
  # defaultLayoutRegions:
  #     nav: 'nav'
  #     footer: 'footer'
  #   defaultContentRegion: 'main'
  #   showForgotPasswordLink: true

AccountsTemplates.configureRoute('signIn')
AccountsTemplates.configureRoute('signUp')
AccountsTemplates.configureRoute('changePwd')

Router.plugin('ensureSignedIn', {
  except: _.pluck(AccountsTemplates.routes, 'name').concat(['home', 'contacts'])
});