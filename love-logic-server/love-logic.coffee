# ------
# Routes

Router.configure
  layoutTemplate: 'ApplicationLayout'

# AccountsTemplates.configure
#   defaultLayout: 'ApplicationLayout'
#   defaultLayoutRegions:
#       nav: 'nav'
#       footer: 'footer'
#     defaultContentRegion: 'main'
#     showForgotPasswordLink: true
#
# AccountsTemplates.configureRoute('signIn');
# AccountsTemplates.configureRoute('signUp');

Router.route '/', () ->
  this.render 'hello'

Router.route '/exerciseSets', () ->
  if Meteor.isClient
    Meteor.subscribe('exercise_sets')
  this.render 'exerciseSets'

Router.route '/exerciseSets/:_id', () ->
  if Meteor.isClient
    Meteor.subscribe('exercise_set',@params._id)
  this.render 'exerciseSetVariants'

Router.route '/exerciseSets/:_id/:_variant', () ->
  if Meteor.isClient
    Meteor.subscribe('exercise_set',@params._id)
    Meteor.subscribe('submitted_exercises')
  this.render 'listExercises'


Router.route '/mySubmittedExercises', () ->
  if Meteor.isClient
    Meteor.subscribe('submitted_exercises')
  this.render 'mySubmittedExercises'

Router.route '/ex/proof/from/:_premises/to/:_conclusion', () ->
  this.render 'proof_ex'#, 
    # data : () ->
    #   premises = decodeURIComponent(@params._premises).split('|')
    #   conclusion = decodeURIComponent @params._conclusion
    #   return {premises, conclusion}

# Example URL:
# /ex/trans/domain/5things/names/a=thing1%7Cb=thing2/predicates/Fish1%7CPerson2%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish
# It will work out what you are translating from by what language `:_sentence` is in.
Router.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence', () ->
  this.render 'trans_ex'#, 



# ------
# Collections

@SubmittedExercises = new Mongo.Collection('submitted_exercises')

Meteor.methods
  submitExercise : (exercise) ->
    if not Meteor.userId() or 'userId' of exercise
      throw new Meteor.Error "not-authorized"
    SubmittedExercises.insert( _.defaults(exercise, {
      owner : Meteor.user()._id
      email : Meteor.user().emails[0].address
      created : new Date()
    }))
