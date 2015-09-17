
Template.ApplicationLayout.helpers
  currentUserEmail : () ->
    u = Meteor.user()
    return '' if u is null
    # Note: `u` may be undefined because the template is loaded twice,
    # once before the data is received.
    return u?.emails?[0]?.address
