# ------
# Routes

Router.configure
  layoutTemplate: 'ApplicationLayout'

Router.route '/', () ->
  this.render 'hello'


# ------
# Admin routes for students

Router.route '/courses', () ->
  if Meteor.isClient
    Meteor.subscribe('courses')
  this.render 'courses'

Router.route '/course/:_courseName', () ->
  if Meteor.isClient
    Meteor.subscribe('course', @params._courseName)
    Meteor.subscribe('exercise_sets',@params._courseName)
  this.render 'exerciseSetsForCourse'

Router.route '/course/:_courseName/exercise-set/:_variant', () ->
  if Meteor.isClient
    Meteor.subscribe('course', @params._courseName)
    Meteor.subscribe('exercise_set', @params._courseName, @params._variant)
    Meteor.subscribe('submitted_exercises')
  this.render 'exerciseSet'


Router.route '/mySubmittedExercises', () ->
  if Meteor.isClient
    Meteor.subscribe('submitted_exercises')
  this.render 'mySubmittedExercises'



# ------
# Exercise routes

Router.route '/ex/proof/from/:_premises/to/:_conclusion', () ->
  if Meteor.isClient
    @wait(Meteor.subscribe('submitted_exercises'))
    @wait(Meteor.subscribe('work_in_progress'))
  if @ready()
    @render 'proof_ex'
  else
    @render 'loading'

# Example URL:
# /ex/trans/domain/5things/names/a=thing1%7Cb=thing2/predicates/Fish1%7CPerson2%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish
# It will work which direction you are translating in by what language `:_sentence` is in.
Router.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence', () ->
  if Meteor.isClient
    Meteor.subscribe('submitted_exercises')
    Meteor.subscribe('work_in_progress')
  this.render 'trans_ex'



# ------
# Collections

@SubmittedExercises = new Mongo.Collection('submitted_exercises')
@WorkInProgress = new Mongo.Collection('work_in_progress')

Meteor.methods
  submitExercise : (exercise) ->
    if not Meteor.userId() or 'userId' of exercise
      throw new Meteor.Error "not-authorized"
    SubmittedExercises.insert( _.defaults(exercise, {
      owner : Meteor.user()._id
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
