# (c) Stephen A. Butterfill 2015
# All rights reserved.
# Contact me if you want to use this code.

# ------
# Collections

# Each time a student submits an exercise, store it here.  Update when it is marked.
@SubmittedExercises = new Mongo.Collection('submitted_exercises')
# @SubmittedExercises = new Ground.Collection('submitted_exercises')

# Record which exercise sets a student has subscribed to.
@Subscriptions = new Mongo.Collection('subscriptions')
# @Subscriptions = new Ground.Collection('subscriptions')

# When a grader grades an exercise, the results are stored here so that
# students who submit the same answer can be auto-graded.
# Documents contain `.exerciseId`, `.ownerIdHash` (so that changes can be monitored)
# hash of answer.content (or answer.answerPNFsimplifiedSorted) plus 
# `.isCorrect`, `.comment`, and `.graderId` ()
@GradedAnswers = new Mongo.Collection('graded_answers')

@HelpRequest = new Mongo.Collection('help_request')




Meteor.methods
  seminarTutorExists : (emailAddress) ->
    Meteor.users.find({'emails.address':emailAddress, 'profile.is_seminar_tutor':true}).count() isnt 0

  updateSeminarTutor : (emailAddress) ->
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    if Meteor.isClient
      # Can’t simulate
      return undefined
    test = Meteor.users.find({'emails.address':emailAddress,  'profile.is_seminar_tutor':true}).count()
    if test is 0
      throw new Meteor.Error "No tutor is registered with that email address."
    Meteor.users.update(userId, {$set: {"profile.seminar_tutor":emailAddress}})

  updateInstructor : (emailAddress) ->
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    if Meteor.isClient
      # Can’t simulate
      return undefined
    test = Meteor.users.find({'emails.address':emailAddress,  'profile.is_instructor':true}).count()
    if test is 0
      throw new Meteor.Error "No instructor is registered with that email address."
    Meteor.users.update(userId, {$set: {"profile.instructor":emailAddress}})

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
    
  makeMeAnInstructor : () ->
    userId = Meteor.user()?._id
    if not userId 
      throw new Meteor.Error "not-authorized"
    Meteor.users.update(userId, {$set: {'profile.is_instructor':true}})
    
    
  
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
      # TODO: write some code here (can find and then insert) so that
      # client can do an optimistic update and give faster feedback.
      return undefined
    # Update exercise if not already graded by a human
    # This is a tiny bit tricky because Meteor doesn’t wrap `findAndModify` for us.
    # The following follows the core of https://github.com/fongandrew/meteor-find-and-modify/blob/master/find_and_modify.js
    # (except that their code doesn’t work because they add a `$setOnInsert`.)
    rawSubmittedExercises = SubmittedExercises.rawCollection()
    findAndModify = Meteor.wrapAsync(rawSubmittedExercises.findAndModify, rawSubmittedExercises)
    query = { owner : userId, exerciseId : exercise.exerciseId, humanFeedback : {$exists:false} }
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


  "nofHelpRequestsForTutor" : () ->
    #restrict to TA’s own students
    if Meteor.isClient
      return 99
    tutor_email = Meteor.users.findOne({_id:@userId})?.emails?[0]?.address
    tuteeIds = wy.getTuteeIds(tutor_email)
    return HelpRequest.find({ requesterId:{$in:tuteeIds}, answer:{$exists:false}}).count()


# -----
# Stats
Meteor.methods
  getNofUsers : () ->
    if Meteor.isClient
      return undefined
    return Meteor.users.find().count()
  getNofSubmittedExercises : () ->
    if Meteor.isClient
      return undefined
    return SubmittedExercises.find().count()
  
Meteor.methods
  resetTester : () ->
    if Meteor.isClient
      return undefined
    i = Meteor.users.findOne({'profile.name':'tester'})?._id
    if i?
      SubmittedExercises.remove({owner:i})
      return true
    else
      throw new Meteor.Error "Could not find tester’s id!"
    
    