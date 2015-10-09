# user accounts config.
# See https://github.com/meteor-useraccounts/core/blob/master/Guide.md
# See https://github.com/meteor-useraccounts/iron-routing


# AccountsTemplates.addField({
#   _id: 'email'
#   type: 'email'
#   placeholder:
#     signUp: "Email (your university email)"
#     signIn: "Email (your university email)"
#   required: true
# });

AccountsTemplates.addField({
  _id: 'name'
  type: 'text'
  placeholder: 
    signUp: "Full name"
  required: true
});

AccountsTemplates.addField({
  _id: 'seminar_tutor'
  type: 'email'
  placeholder: 
    signUp: "Your seminar tutor’s email"
  required: false
});

AccountsTemplates.addField({
  _id: "terms_of_use"
  type: "checkbox"
  required: true
  # TODO : make that it is required to be true
  displayName: "All my datas are belong to you."
});

AccountsTemplates.configure
  defaultLayout: 'ApplicationLayout'
  defaultLayoutRegions : {}
  defaultContentRegion: 'main'
  enablePasswordChange: true
  #   showForgotPasswordLink: true

AccountsTemplates.configureRoute('signIn')
AccountsTemplates.configureRoute('signUp')
AccountsTemplates.configureRoute('changePwd')

# See https://github.com/meteor-useraccounts/flow-routing
FlowRouter.triggers.enter [AccountsTemplates.ensureSignedIn], 
  except: [ 
    'signIn'
    'signUp'
    'forgotPwd'
    'resetPwd'
    'verifyEmail'
    'resendVerificationEmail'
  ]
