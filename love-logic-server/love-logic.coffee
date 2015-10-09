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

FlowRouter.route '/feedbackToReview',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'feedbackToReview'

FlowRouter.route '/mySubmittedExercises',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'mySubmittedExercises'



# ------
# Exercise routes

# TODO: tutor - page showing tutee’s progress (% completed in last 7 days? etc)

# TODO: exercise - yes/no question (e.g. can logically valid argument have false premises)
# TODO: exercise - state whether an argument (of awFOL or En) is valid.
# TODO: exercise - (free text) state the definition of logically valid
# TODO: exercise - truth tables for argument (determine validity)
# TODO: exercise - build a scene which is a counterexample to this argument
# TODO: exercise - specify the main connective (multiple choice)
# TODO: exercise - write down the scopes of different operators.
# TODO: exercise - proof of, or counterexample to, argument

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

# Create a possible situation in which `_sentences` are all true
FlowRouter.route '/ex/create/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'

# Say which sentences are true in a possible situation
FlowRouter.route '/ex/TorF/:_sentences/:_world',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'

# Construct truth tables for the sentences
FlowRouter.route '/ex/tt/:_sentences/',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'

# ------
# Grading (=marking) routes

FlowRouter.route '/myTutees',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTutees'


FlowRouter.route '/exercisesToGrade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exercisesToGrade'

FlowRouter.route '/helpRequestsToAnswer',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'helpRequestsToAnswer'

FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

FlowRouter.route '/ex/proof/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
    
FlowRouter.route '/ex/create/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

FlowRouter.route '/ex/TorF/:_sentences/:_world/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

FlowRouter.route '/ex/tt/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# ------
# Collections

# Each time a student submits an exercise, store it here.  Update when it is marked.
@SubmittedExercises = new Mongo.Collection('submitted_exercises')

# Record which exercise sets a student has subscribed to.
@Subscriptions = new Mongo.Collection('subscriptions')

# When a grader grades an exercise, the results are stored here so that
# students who submit the same answer can be auto-graded.
# Documents contain `.exerciseId`, `.ownerIdHash` (so that changes can be monitored)
# hash of answer.content (or answer.answerPNFsimplifiedSorted) plus 
# `.isCorrect`, `.comment`, and `.graderId` ()
@GradedAnswers = new Mongo.Collection('graded_answers')

@HelpRequest = new Mongo.Collection('help_request')

Meteor.methods
  # TODO: Change email.  Do not allow user to change email to
  # an email already used, nor to an email used as a supervisor email.
  
  updateSeminarTutor : (emailAddress) ->
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    if Meteor.isClient
      # Can’t simulate
      return undefined
    test = Meteor.users.find({'emails.address':emailAddress}).count()
    if test is 0
      throw new Meteor.Error "No one is registered with that email address."
    Meteor.users.update(userId, {$set: {"profile.seminar_tutor":emailAddress}})

  updateEmailAddress : (emailAddress) ->
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    if Meteor.isClient
      # Can’t simulate
      return undefined
    test = Meteor.users.find({'emails.address':emailAddress}).count()
    if test isnt 0
      throw new Meteor.Error "That email address is already is use."
    emails = [{ address : emailAddress, verified : false }]
    Meteor.users.update(userId, {$set: {'emails':emails}})
  
  makeMeATutor : () ->
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    Meteor.users.update(userId, {$set: {'profile.is_seminar_tutor':true}})
    
    
  
  submitExercise : (exercise) ->
    userId = Meteor.user()?._id
    if not userId or 'userId' of exercise
      throw new Meteor.Error "not-authorized"
    # Can't do this because may be auto grading using past feedback
    # if 'humanFeedback' of exercise
    #   throw new Meteor.Error "Human feedback provided with submission (cheating?)."
    newDoc = _.defaults(exercise, {
      owner : userId
      ownerName : Meteor.user().profile?.name
      email : Meteor.user().emails[0].address
      created : new Date()
    })
    if Meteor.isClient
      return undefined
    # Update exercise if not already graded by a human
    # This is a tiny bit tricky because Meteor doesn’t wrap `findAndModify` for us.
    # The following follows the core of https://github.com/fongandrew/meteor-find-and-modify/blob/master/find_and_modify.js
    # (except that their code doesn’t work because they add a `$setOnInsert`.)
    rawSubmittedExercises = SubmittedExercises.rawCollection()
    findAndModify = Meteor.wrapAsync(rawSubmittedExercises.findAndModify, rawSubmittedExercises)
    query = { $and:[
      {owner : userId}
      {exerciseId : exercise.exerciseId}
      {humanFeedback : {$exists:false}}
    ] }
    findAndModify(query, {}, newDoc, {upsert: true})

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

  addHumanFeedback : (submission, humanFeedback) ->
    if not Meteor.userId() 
      throw new Meteor.Error "not-authorized"
    # Check that the owner of the submission has not changed
    oldOwner = SubmittedExercises.findOne({_id:submission._id})?.owner
    if oldOwner isnt submission.owner
      throw new Meteor.Error "The owner (author) of a submitted exercise may not be changed."
    # Check that the current user is the tutor of the owner of `submission`.
    # (Only do this on the server because `Meteor.users` gives the only the current user on the client!)
    if Meteor.isServer
      tutorEmail = Meteor.users.findOne(submission.owner)?.profile?.seminar_tutor
      if not tutorEmail
        throw new Meteor.Error "not-authorized (no supervisor for this student)"
      userEmails = (x.address for x in Meteor.user().emails)
      if not( tutorEmail in userEmails )
        throw new Meteor.Error "not-authorized (not the supervisor of this student)"
    humanFeedback.studentSeen = false
    SubmittedExercises.update(submission, $set:{humanFeedback: humanFeedback})
  
  studentSeenFeedback : (exercise) ->
    userId = Meteor.user()._id
    if not userId or exercise.owner isnt userId
      throw new Meteor.Error "not-authorized"
    SubmittedExercises.update(exercise, $set:{'humanFeedback.studentSeen':true, 'humanFeedback.studentEverSeen':true})

  studentSeenHelpRequestAnswer : (helpReq) ->
    userId = Meteor.user()._id
    if not userId or helpReq.requesterId isnt userId
      throw new Meteor.Error "not-authorized"
    HelpRequest.update(helpReq, $set:{studentSeen: new Date()})
    

  createHelpRequest : (doc) ->
    requesterId = Meteor.user()?._id
    if not requesterId
      throw new Meteor.Error "not-authorized"
    doc.requesterId = requesterId
    if Meteor.user()?.profile?.seminar_tutor?
      doc.requesterTutorEmail = Meteor.user().profile.seminar_tutor
    doc.created = new Date()
    HelpRequest.insert(doc)

  answerHelpRequest : (helpReq, answer) ->
    answererId = Meteor.user()?._id
    if not answererId
      throw new Meteor.Error "not-authorized"
    answererName = Meteor.user().profile?.name
    # Anyone may answer a help request
    HelpRequest.update(helpReq, $set:{dateAnswered:new Date(), answererId, answer, answererName} )

  addGradedExercise : (exerciseId, ownerIdHash, answerHash, isCorrect, comment, answerPNFsimplifiedSorted) ->
    graderId = Meteor.user()?._id
    if not graderId
      throw new Meteor.Error "not-authorized"
    newDoc = {graderId, exerciseId, ownerIdHash, answerHash}
    if answerPNFsimplifiedSorted
      newDoc.answerPNFsimplifiedSorted = answerPNFsimplifiedSorted
    if isCorrect?
      newDoc.isCorrect = isCorrect
    if comment? 
      newDoc.comment = comment
    # (Checking that we actually need to add this answer has already been done on the client.)
    if Meteor.isClient
      return undefined
    rawGradedAnswers = GradedAnswers.rawCollection()
    findAndModify = Meteor.wrapAsync(rawGradedAnswers.findAndModify, rawGradedAnswers)
    # TODO create unique composite index
    query = { $and:[
      {exerciseId}
      {ownerIdHash}
      {answerHash}
    ] }
    findAndModify(query, {}, newDoc, {upsert: true})


# -----
# Methods for getting data
Meteor.methods

  # Return a list of exerciseIds for which students have submitted work.
  getExercisesToGrade : () ->
    if not Meteor.userId() 
      throw new Meteor.Error "not-authorized"
    if Meteor.isClient
      # We are going to use `.aggregate` which only works on the server
      return []
    tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    if not tutor_email
      console.log "Current user has no email address!"
      return [] 
    tuteeIds = wy.getTuteeIds(tutor_email)
    pipeline = []
    needsFeedback = 
      $or:[
        # Correctness has not yet been determined
        $and: [
          {"humanFeedback.isCorrect":{$exists:false}}
          {"machineFeedback.isCorrect":{$exists:false}}
        ]
        # Machine has marked the exercise false---would expect a human comment in this case.
        $and: [
          {"machineFeedback.isCorrect":{$ne:true}}
          {"humanFeedback":{$exists:false} }
        ]
      ]
    pipeline.push $match: { $and:[{owner:{$in:tuteeIds}}, needsFeedback] }
    pipeline.push $project: {exerciseId:1}
    pipeline.push $group: { _id: "$exerciseId" }
    pipeline.push $project: {exerciseId: "$_id", _id:0}
    result = SubmittedExercises.aggregate(pipeline)
    return result

