Template.upsertExerciseSet.events
  'click #submit' : (event, template) ->
    docJSONStr = $('#exerciseSet').val()
    doc = JSON.parse(docJSONStr)
    Meteor.call "upsertExerciseSet", doc, (error, result) ->
      if error
        Materialize.toast "Sorry, could not create or update. #{error.message}", 4000
      else
        Materialize.toast "Your exercise set has been updated or created.", 4000
