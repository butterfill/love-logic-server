# ------
# Routes

FlowRouter.notFound =
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'routeNotFound'


FlowRouter.route '/', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'main'


# ------
# Admin routes for students

FlowRouter.route '/test/:msg',
  action : (params, queryParams) ->
    console.log "got #{params.msg}"
    BlazeLayout.render 'ApplicationLayout', main:'mySubmittedExercises'


FlowRouter.route '/courses', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'courses'

FlowRouter.route '/course/:_courseName',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exerciseSetsForCourse'

FlowRouter.route '/course/:_courseName/exercise-set/:_variant',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exerciseSet'


FlowRouter.route '/mySubmittedExercises',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'mySubmittedExercises'



# ------
# Exercise routes

# TODO: exercise - specify the main connective (multiple choice)
# TODO: exercise - write down the scopes of different operators.

# Write a proof exercise
FlowRouter.route '/ex/proof/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'proof_ex'

# Translation exercise
# Example URL:
# /ex/trans/domain/5things/names/a=thing1%7Cb=thing2/predicates/Fish1%7CPerson2%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish
# It will work which direction you are translating in by what language `:_sentence` is in.
FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'trans_ex'

FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'trans_ex_grade'


# ------
# Marking routes


# ------
# Collections

# Each time a student submits an exercise, store it here.  Update when it is marked.
@SubmittedExercises = new Mongo.Collection('submitted_exercises')

# Save a student’s work, but don’t let anybody see it.
@WorkInProgress = new Mongo.Collection('work_in_progress')

# Record which exercise sets a student has subscribed to.
@Subscriptions = new Mongo.Collection('subscriptions')

Meteor.methods
  submitExercise : (exercise) ->
    if not Meteor.userId() or 'userId' of exercise
      throw new Meteor.Error "not-authorized"
    SubmittedExercises.insert( _.defaults(exercise, {
      owner : Meteor.user()._id
      ownerName : Meteor.user().profile?.name
      email : Meteor.user().emails[0].address
      created : new Date()
    }))

  saveWorkInProgress : (exerciseId, text) ->
    userId = Meteor.user()._id
    if not userId
      throw new Meteor.Error "not-authorized"
    wip = WorkInProgress.findOne({$and:[{owner:userId},{exerciseId:exerciseId}]})
    if wip
      WorkInProgress.update(wip, $set:{text : text})
    else 
      WorkInProgress.insert( {
        owner : userId
        exerciseId : exerciseId
        created : new Date()
        text : text
      })
  
  subscribeToExerciseSet : (courseName, variant) ->
    userId = Meteor.user()._id
    if not userId
      throw new Meteor.Error "not-authorized"
    subscription = Subscriptions.findOne($and:[{owner:userId},{courseName},{variant}])
    if subscription
      throw new Meteor.Error "You are already following ‘#{variant}’ on #{courseName}."
    if not subscription
      Subscriptions.insert({
        owner : userId
        created : new Date()
        courseName
        variant
      })
      
    
