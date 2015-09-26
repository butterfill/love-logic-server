

Template.GradeLayout.onCreated () ->
  self = this
  self.autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'submitted_answers', exerciseId
    self.subscribe 'courses'



  
Template.GradeLayout.helpers
  displayQuestion : () ->
    FlowRouter.watchPathChange()
    url = ix.url()
    type = url.split('/')[2]
    console.log type
    return "#{type}_ex_display_question"
  displayAnswer : () ->
    url = ix.url()
    type = url.split('/')[2]
    return "#{type}_ex_display_answer"
  isAnswers : () ->
    FlowRouter.watchPathChange()
    return SubmittedExercises.find().count() >0
  answers : () ->
    exerciseId = ix.getExerciseId()
    return SubmittedExercises.find({exerciseId}, {sort:{'created':-1}})
  dateSubmitted : () ->
    return moment(@.created).fromNow()
  isMachineFeedback : () ->
    return @machineFeedback?
  isHumanFeedback : () ->
    return @humanFeedback?





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
    key = "comment/Meteor.userId()/#{this._id}"
    return Session.get(key) or ''


saveComment = (submission, rawComment) ->
  name = ''
  if Meteor.user().profile?.name?
    name = "#{Meteor.user().profile.name} writes: "
  comment = "#{name}#{rawComment}"
  if comment.trim() is ''
    return
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
      
Template.grading_form.helpers
  "theId" : () ->
    return "#{@._id}"
  
Template.grading_form.events
  # Update the comment associated with a submitted exercise (tutor is
  # providing written feedback.)
  "blur .human-comment" : (event, templateInstance) ->
    submission = this
    saveComment(submission, event.target.value)

  "click .modal-footer .add-human-comment" : (event, template) ->
    submission = this
    textareaId = $(event.target).attr('data-textarea')
    console.log textareaId
    rawComment = $("#"+"#{textareaId}").val()
    saveComment(submission, rawComment)
    $(templateInstance.find('.addComment.modal-trigger')).leanModal()    

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
    
  "click .changeCorrectness" : (event, template) ->
    submission = this
    humanFeedback = _.clone submission.humanFeedback
    delete humanFeedback.isCorrect
    Meteor.call "addHumanFeedback", submission, humanFeedback, (error) ->

  "click .addComment.modal-trigger" : (event, template) ->
    # We need `parent` because it's the icon (child) that gets clicked
    target = $(event.target).parent().attr('data-target')
    $('#'+target).openModal()
    
    
  "click .editComment" : (event, target) ->
    console.log "start"
    submission = this
    key = "comment/Meteor.userId()/#{this._id}"
    console.log key
    Session.set(key, submission.humanFeedback.comment)
    humanFeedback = _.clone submission.humanFeedback
    delete humanFeedback.comment
    Meteor.call "addHumanFeedback", submission, humanFeedback, (error) ->
      if error
        Materialize.toast "Error deleting feedback comment: #{error.message}.", 4000
    console.log "done"