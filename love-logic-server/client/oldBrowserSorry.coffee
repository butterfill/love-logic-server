
Template.oldBrowserSorry.events
  'click #ignoreWarning' : () ->
    key = "#{ix.getUserId()}/oldBrowserIgnoreWarning"
    Session.setPersistent(key, true)
    FlowRouter.go('/')
    
    

    
