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

# TODO: only trusted users can create GradedAnswers

# TODO: students can see the summary of their progress (same as tutor view, but just for themselves).

# TODO: add possibility of ‘it is impossible’ to the `/create` exercises.
# TODO: exercise - create a counterexample OR say the argument is valid
# TODO: exercise - truth tables for argument (determine validity) (see route below)
# TODO: exercise - build a scene in which all sentences are false
# TODO: exercise - specify the main connective (multiple choice)
# TODO: exercise - write down the scopes of different operators.
# TODO: exercise - proof of, or counterexample to, argument

# Write a proof exercise
FlowRouter.route '/ex/proof/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'proof_ex'
FlowRouter.route '/ex/proof/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
    
# Translation exercise.  Example URL: /ex/trans/domain/5things/names/a=thing1%7Cb=thing2/predicates/Fish1%7CPerson2%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish
# It will work out which direction you are translating in by what language `:_sentence` is in.
FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'trans_ex'
FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Create a possible situation in which `_sentences` are all true
FlowRouter.route '/ex/create/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'
FlowRouter.route '/ex/create/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Create a counterexample to the argument
FlowRouter.route '/ex/create/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'
FlowRouter.route '/ex/create/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Construct truth tables for the sentences
FlowRouter.route '/ex/tt/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'
FlowRouter.route '/ex/tt/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Construct truth tables for argument and say whether it is valid, specifying a counterexample if appropriate. TODO: update template so it copes with this  TODO: Add examples
FlowRouter.route '/ex/tt/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'
FlowRouter.route '/ex/tt/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'



# Answer a question in free text
FlowRouter.route '/ex/q/:_question/',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'q_ex'
FlowRouter.route '/ex/q/:_question/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# ---
# The exercises following all use the `evaluate_ex` template

# Answer questions about an argument and a possible situation (predicate)
# E.g. /ex/TorF/from/I am a dog|I am a cat/to/I am a dog and a cat/world/[{"x":9,"y":0,"w":2,"h":2,"n":"a,b","c":"white","f":["}:","^","D"]},{"x":0,"y":0,"w":2,"h":2,"n":"","c":"pink","f":[":\'","-","D"]},{"x":4,"y":0,"w":2,"h":2,"n":"","c":"purple","f":[":\'","-","("]}]/qq/The argument is sound|The argument is valid
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/world/:_world/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/world/:_world/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about an argument and a possible situation (TTrow)
# e.g. /ex/TorF/from/not A|A arrow B/to/not B/TTrow/A:F|B:T/qq/the first premise is true|the second premise is true|the conclusion is true|the possible situation is a counterexample to the argument
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/TTrow/:_TTrow/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/TTrow/:_TTrow/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about an argument
# e.g. /ex/TorF/from/I am a dog|I am a cat/to/I am a dog and a cat//qq/The argument is sound|The argument is valid
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about a possible situation (predicate)
FlowRouter.route '/ex/TorF/world/:_world/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/world/:_world/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about a possible situation (TTrow)
FlowRouter.route '/ex/TorF/TTrow/:_TTrow/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/TTrow/:_TTrow/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions
FlowRouter.route '/ex/TorF/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'


# ------
# Grading (=marking) routes

FlowRouter.route '/myTutees',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTutees'

FlowRouter.route '/myTuteesProgress',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTuteesProgress'

FlowRouter.route '/exercisesToGrade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exercisesToGrade'

FlowRouter.route '/helpRequestsToAnswer',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'helpRequestsToAnswer'


# ------
# Other routes

# Add or create an exercise set
FlowRouter.route '/upsertExerciseSet',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'upsertExerciseSet'


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
    # Do not allow user to change email to an email already used.
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
    subscription = Subscriptions.findOne({owner:userId, courseName, variant})
    if subscription?
      throw new Meteor.Error "You are already following ‘#{variant}’ on #{courseName}."
    Subscriptions.insert({
      owner : userId
      created : new Date()
      courseName
      variant
    })

  unsubscribeToExerciseSet : (courseName, variant) ->
    userId = Meteor.user()._id
    if not userId
      throw new Meteor.Error "not-authorized"
    subscription = Subscriptions.findOne({owner:userId, courseName, variant})
    if not subscription?
      throw new Meteor.Error "You aren’t following ‘#{variant}’ on #{courseName}."
    Subscriptions.remove(subscription._id)

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


  upsertExerciseSet : (exerciseSet) ->
    userId = Meteor.user()._id
    if not userId or (exerciseSet.owner? and exerciseSet.owner isnt userId)
      throw new Meteor.Error "not-authorized"
    if not exerciseSet.courseName? or not exerciseSet.variant? 
      throw new Meteor.Error "Exercise sets must have `courseName` and `variant` properties."
    oldExerciseSet = ExerciseSets.findOne({courseName:exerciseSet.courseName, variant:exerciseSet.variant})
    if not oldExerciseSet?
      exerciseSet.owner = userId
      exerciseSet.created = new Date()
      r = ExerciseSets.insert(exerciseSet)
      return r
    # There is an exercise set which we must update.
    if oldExerciseSet.owner isnt userId
      throw new Meteor.Error "You cannot update this exercise set because you do not own it."
    r = ExerciseSets.update(oldExerciseSet._id, $set:{description:exerciseSet.description, lectures:exerciseSet.lectures})
    return r
      
    

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

