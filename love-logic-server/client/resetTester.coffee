
Template.resetTester.onCreated () ->
  templateInstance = this
  templateInstance.doit = new ReactiveVar()
  templateInstance.autorun () ->
    Meteor.call "resetTester", (error, result) ->
      templateInstance.doit.set(true)

Template.resetTester.helpers
  'doit' : () ->
    return Template.instance().doit.get()

    
