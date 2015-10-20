Template.upsertExerciseSet.events
  'click #submit' : (event, template) ->
    docJSONStr = $('#exerciseSet').val()
    doc = JSON.parse(docJSONStr)
    Meteor.call "upsertExerciseSet", doc, (error, result) ->
      if error
        Materialize.toast "Sorry, could not create or update. #{error.message}", 4000
      else
        Materialize.toast "Your exercise set has been updated or created.", 4000
  'click #importFromLocalhost' : (event, template) ->
    for filename in [
      'exercise_index_normal_normal.txt'
      'exercise_index_normal_fast.txt'
      'exercise_index_fast_normal.txt'
      'exercise_index_fast_fast.txt'
      'exercise_index_short_normal.txt'
      'exercise_index_short_fast.txt'
    ]
      HTTP.get "http://localhost:9778/#{filename}", (error, resp) ->
        doc = JSON.parse(resp.content)
        Meteor.call "upsertExerciseSet", doc, (error, result) ->
          if error
            Materialize.toast "Sorry, could not create or update. #{error.message}", 4000
          else
            Materialize.toast "#{filename} has been updated or created.", 4000
      