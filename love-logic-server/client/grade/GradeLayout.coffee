Template.submit_btn.onCreated () ->
  self = this
  self.autorun () ->
    FlowRouter.watchPathChange()


Template.GradeLayout.onCreated () ->
  self = this
  self.autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    
    # Keep track of the last exercise page the user loaded 
    # so that she can easily resume where she left off later.
    # (Currently we don't distinguish between grading and doing exercises)
    # (Disabled because currently not very useful.)
    # ix.storeLastExercise()
    
    self.subscribe 'courses'
    self.subscribe 'graded_answers', exerciseId
    self.subscribe 'help_requests_for_tutor', exerciseId
    
    # Which `SubmittedAnswers` to get?
    # If url param `user`, then get answers for that user (who must be a tutee of the current user).
    # Otherwise get answers for all the current users tutees.
    userId = FlowRouter.getQueryParam('user')
    self.subscribe 'submitted_answers', exerciseId, userId
    

getSubmittedAnswersCursor = () ->
  q = {}
  q.exerciseId = ix.getExerciseId()
  
  userId = FlowRouter.getQueryParam('user')
  if userId
    q.owner = userId
  
  if isHideCorrectAnswers()
    q['humanFeedback.isCorrect'] = {$not:true}
    q['machineFeedback.isCorrect'] = {$not:true}
  
  return SubmittedExercises.find(q, {sort:{'created':-1}})
  

isHideCorrectAnswers = () ->
  stored = Session.get("#{ix.getUserId()}/hideCorrectAnswers")
  return stored if stored?
  return false
  
Template.GradeLayout.helpers
  displayQuestion : () ->
    FlowRouter.watchPathChange()
    url = ix.url()
    type = url.split('/')[2]
    return "#{type}_ex_display_question"
  gradeURL : () -> 
    FlowRouter.watchPathChange()
    return ix.contractUrl('/grade')
  isHideCorrectAnswers : isHideCorrectAnswers
  displayAnswer : () ->
    url = ix.url()
    type = url.split('/')[2]
    return "#{type}_ex_display_answer"
  isAnswers : () ->
    FlowRouter.watchPathChange()
    return getSubmittedAnswersCursor().count() >0
  answers : getSubmittedAnswersCursor
  dateSubmitted : () ->
    return moment(@created).fromNow()
  isMachineFeedback : () ->
    return @machineFeedback?
  isHumanFeedback : () ->
    return @humanFeedback?

  # These occur in the data context of a SubmittedAnswer
  helpRequests : () ->
    return HelpRequest.find({submittedExerciseId:@_id, requesterId:@owner})
  helpRequestDate : () -> moment(@created).fromNow()
  doNotShowAnserHelpRequestInput : () ->
    return false unless @answer?
    key = "helpRequestAnswer/#{Meteor.userId()}/#{this._id}"
    forceShowInput = Session.get(key)
    return false if forceShowInput? and forceShowInput
    return true
  studentSeenHelpRequest : () -> @studentSeen?
  theId : () -> "#{@_id}"




# =====================
# Template: grading_form



Template.grading_form.helpers
  isHumanFeedbackComment : () ->
    return @humanFeedback?.comment?
  canDeleteHumanFeedbackComment : () ->
    return not @humanFeedback?.studentEverSeen?
  isCorrectnessDetermined : () ->
    return @humanFeedback?.isCorrect? or @machineFeedback?.isCorrect?
  rightOrWrong : () ->
    if @humanFeedback?.isCorrect?
      return ("correct" if @humanFeedback.isCorrect) or "incorrect"
    return ("correct" if @machineFeedback.isCorrect) or "incorrect"
  canDeleteCorrectness : () ->
    #return (not @humanFeedback?.comment?.studentEverSeen?) and 
    return @humanFeedback?.isCorrect?
  feedbackTextareaContent : () ->
    key = "comment/#{Meteor.userId()}/#{this._id}"
    return Session.get(key) or ''


saveComment = (submission, rawComment) ->
  comment = rawComment.trim()
  if comment is ''
    return
  #Ensure comment ends in a period
  unless comment.match /\.$/
    comment = "#{comment}."
  # Add the commentor’s name (unless it is already included)
  unless comment.match(/\ writes:\ /)
    name = ''
    if Meteor.user().profile?.name?
      name = "#{Meteor.user().profile.name} writes: "
    comment = "#{name}#{comment}"
  if not submission.humanFeedback?
    humanFeedback = { comment }
  else
    humanFeedback = _.clone(submission.humanFeedback)
    if humanFeedback.comment?
      humanFeedback.comment = "#{submission.humanFeedback.comment} And #{comment}"
    else 
      humanFeedback.comment = comment
  Meteor.call "addHumanFeedback", submission, humanFeedback, (error) ->
    if error 
      Materialize.toast "Error saving feedback: #{error.message}.", 4000
    else
      Materialize.toast "Your feedback has been saved.", 4000
      addGradedExercise(submission, undefined, humanFeedback.comment)
      
Template.grading_form.helpers
  "theId" : () ->
    return "#{@_id}"

# When a grader marks an exercise, we might want to store the grade and 
# comment in case another student gives a matching answer.
addGradedExercise = (submittedExercse, isCorrect, comment) ->
  isCorrect ?= submittedExercse.humanFeedback?.isCorrect
  # Only save when we have a judgement of correctness
  if not isCorrect?
    return undefined
  # We may not have a comment; it should not matter whether we do or not.
  comment ?= submittedExercse.humanFeedback?.comment
  exerciseId = submittedExercse.exerciseId
  ownerIdHash = ix.hash(submittedExercse.owner)
  answerHash = ix.hashAnswer(submittedExercse)
  answerPNFsimplifiedSorted = submittedExercse.answerPNFsimplifiedSorted
  dialectName = submittedExercse.answer.content.dialectName
  dialectVersion = submittedExercse.answer.content.dialectVersion
  # Must save graded answer if we already have a graded answer for this owner, answer and exercise
  mustSave = GradedAnswers.find({$and:[{exerciseId}, {ownerIdHash}, {answerHash}]}).count() > 0
  if not mustSave
    # Don't want to save if we already have give this answer the same grade
    # TODO: check if we have new, useful feedback and can that?  Or create a facility for graders
    # to exit the canned feedback?
    nofExistingGradedAnswers = GradedAnswers.find({$and:[{exerciseId}, {answerHash}, {isCorrect}]}).count()
    if nofExistingGradedAnswers > 0
      console.log "Not saving graded exercise because already have an exemplar."
      return undefined
  console.log "saving graded exercise ..."
  Meteor.call "addGradedExercise", exerciseId, ownerIdHash, answerHash, isCorrect, comment, answerPNFsimplifiedSorted, dialectName, dialectVersion
  

Template.grading_form.events
  # Update the comment associated with a submitted exercise (tutor is
  # providing written feedback.)
  "blur .human-comment" : (event, templateInstance) ->
    submission = this
    saveComment(submission, event.target.value)


  "click .markCorrectness" : (event, template) ->
    isCorrect = $(event.target).hasClass('correct')
    submission = this
    if not submission.humanFeedback?
      humanFeedback = { isCorrect }
    else
      humanFeedback = _.clone(submission.humanFeedback)
      humanFeedback.isCorrect = isCorrect
    Meteor.call "addHumanFeedback", submission, humanFeedback, (error) ->
      if error 
        Materialize.toast "Error saving feedback: #{error.message}.", 4000
      else
        Materialize.toast "Your feedback has been saved.", 4000
        submittedExercse = template.data
        addGradedExercise(submittedExercse, isCorrect, undefined)
        
  "click .changeCorrectness" : (event, template) ->
    submission = this
    humanFeedback = _.clone submission.humanFeedback
    delete humanFeedback.isCorrect
    Meteor.call "addHumanFeedback", submission, humanFeedback, (error) ->

  "click .addComment" : (event, template) ->
    submission = @
    MaterializeModal.form({
      title : "Add comment"
      bodyTemplate : "addCommentModal"
      submitLabel : "done"
      closeLabel : "cancel"
      humanFeedback : @humanFeedback
      callback : (error, response) ->
        if response.submit
          saveComment(submission, response.form.newComment)
    })
    
  "click .editComment" : (event, target) ->
    submission = this
    key = "comment/#{Meteor.userId()}/#{this._id}"
    Session.set(key, submission.humanFeedback.comment)
    humanFeedback = _.clone submission.humanFeedback
    delete humanFeedback.comment
    Meteor.call "addHumanFeedback", submission, humanFeedback, (error) ->
      if error
        Materialize.toast "Error deleting feedback comment: #{error.message}.", 4000
    
Template.GradeLayout.events
  'blur .help-request-answer' : (event, template) ->
    helpReq = @
    answer = $(event.target).val()
    return unless answer? and answer.trim() isnt ''
    # This session variable controls whether the input is shown
    key = "helpRequestAnswer/#{Meteor.userId()}/#{this._id}"
    Session.set(key, false)

    Meteor.call "answerHelpRequest", helpReq, answer

  "click .editAnswer" : (event, target) ->
    # This session variable controls whether the input is shown
    key = "helpRequestAnswer/#{Meteor.userId()}/#{this._id}"
    Session.set(key, true)

  'click #hideCorrectAnswers' : (event, target) ->
    Session.setPersistent("#{ix.getUserId()}/hideCorrectAnswers", $('#hideCorrectAnswers').prop('checked'))
