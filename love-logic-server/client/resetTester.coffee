
Template.resetTester.onCreated () ->
  templateInstance = this
  templateInstance.doit = new ReactiveVar()
  templateInstance.autorun () ->
    Meteor.call "resetTester", (error, result) ->
      if error?
        templateInstance.doit.set(error)
      else
        templateInstance.doit.set(true)

Template.resetTester.helpers
  'doit' : () ->
    return Template.instance().doit.get() is true
  'getErrorOrTrue' : () ->
    return Template.instance().doit.get()

    
