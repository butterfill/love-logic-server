
doSubscriptions = (self, onReady) ->
  self ?= this
  onReady ?= () ->
  self.autorun () ->
    # We need to `watchPathChange` so that the CodeMirror thing gets updated.
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'submitted_exercise', exerciseId, {onReady}

Template.submit_btn.onCreated doSubscriptions
Template.submitted_answer.onCreated () ->
  doSubscriptions this, ()->
    # Record that the user has seen the feedback (or at least opened the page containing it)
    exerciseId = ix.getExerciseId()
    owner = Meteor.userId()
    exWithUnseenFeedback = SubmittedExercises.find({exerciseId, owner, 'humanFeedback.studentSeen':false}).fetch()
    for ex in exWithUnseenFeedback
      Meteor.call "studentSeenFeedback", ex

# Keep track of the last exercise page the user loaded 
# so that she can easily resume where she left off later.
Template.submit_btn.onCreated () ->
  self = this
  self.autorun () ->
    FlowRouter.watchPathChange()
    ix.storeLastExercise()
    

isSubmitted = () ->
  exerciseId = ix.getExerciseId()
  owner = Meteor.userId()
  return SubmittedExercises.find({exerciseId, owner}).count() > 0


Template.submitted_answer.helpers    
  isSubmitted : isSubmitted 
  submittedAnswers : () ->
    exerciseId = ix.getExerciseId()
    owner = Meteor.userId()
    return SubmittedExercises.find({exerciseId, owner}, {sort:{'created':-1}})
  dateSubmitted : () ->
    return moment(@created).fromNow()
  machineSays : () -> (@machineFeedback.comment? and @machineFeedback.comment isnt '')
  isCorrectnessDetermined : () ->
    return @humanFeedback?.isCorrect? or @machineFeedback?.isCorrect?
  # Only call this after establishing `isCorrectnessDetermined`
  rightOrWrong : () ->
    if @humanFeedback?.isCorrect?
      return ("correct" if @humanFeedback.isCorrect) or "incorrect"
    return ("correct" if @machineFeedback.isCorrect) or "incorrect"
  displayMachineFeedback : () ->
    return false if not @machineFeedback?
    # We don't want to display machineFeedback if the machine coulnd't detemine correctness
    # and the human has determined correctness.
    # return false if @humanFeedback?.isCorrect? and not @machineFeedback?.isCorrect?
    return true

Template.submit_btn.helpers    
  isSubmitted : isSubmitted 

Template.submitted_answer.events
  # This is called from a sub-template in which the data context is a `SubmittedExercise`
  'click #view-answer' : (event, template) ->
    # The special session variable holds the value displayed in an editor
    # We set it twice to ensure a reactive update.
    ix.setAnswer(@answer.content)

