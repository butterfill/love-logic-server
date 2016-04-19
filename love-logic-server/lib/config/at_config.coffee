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

# Don’t do this because I couldn’t work out how to validate
# seminar tutor exists
# 
# AccountsTemplates.addField({
#   _id: 'seminar_tutor'
#   type: 'email'
#   placeholder: "Your tutor’s email"
#   displayName: "Your tutor’s email"
#   required: false
#   func: (value) ->
#     # If this returns false, there is no error.
#     return true unless value.indexOf?('@') isnt -1
#     # # Couldn't get validation to show error message when
#     # # server-side validation failed.  Tried two methods, both had same result:
#     # self = this
#     #
#     # # method 1
#     # if Meteor.isClient
#     #   Meteor.call 'seminarTutorExists', value, (error, tutorExists) ->
#     #     if tutorExists
#     #       self.setSuccess()
#     #     else
#     #       self.setError("No tutor is registered with this email address.")
#     #     self.setValidating(false)
#     #   return
#     # # server
#     # test = Meteor.call 'seminarTutorExists', value
#     # return false if test
#     # return "No tutor is registered with this email address."
#     #
#     # # method 2
#     # if Meteor.isServer
#     #   test = Meteor.users.find({'emails.address':value, 'profile.is_seminar_tutor':true}).count()
#     #   if test is 0
#     #     self.setError "No tutor is registered with this email address."
#     #     return "No tutor is registered with this email address."
#     #   return false
#     # return undefined
#   errStr: "Give your tutor’s email address."
# });

AccountsTemplates.addField({
  _id: "terms_of_use"
  type: "checkbox"
  required: true
  # TODO : make that it is required to be true
  displayName: "I accept the Terms of Use"
  func: (value) -> 
    # If this returns false, there is no error.
    return true unless value is true
  errStr: "You must tick the checkbox to accept the terms of use."
});

AccountsTemplates.configure
  defaultLayout: 'ApplicationLayout'
  defaultLayoutRegions : {}
  defaultContentRegion: 'main'
  enablePasswordChange: true
  #   showForgotPasswordLink: true
  reCaptcha:
    siteKey: '6Lc7Ew8TAAAAAE4stjjDQZj75lJr04uiVF4IY9EP'
    theme: 'light'
    data_type: 'image'
  showReCaptcha: false
  termsUrl: '/termsOfUse'
  showPlaceholders: true
  
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
    'termsOfUse'
  ]
