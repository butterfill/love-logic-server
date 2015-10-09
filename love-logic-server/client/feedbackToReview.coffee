
Template.feedbackToReview.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe "exercises_with_unseen_feedback"

Template.feedbackToReview.helpers
  'exercises' : () ->
    return SubmittedExercises.find({ owner:Meteor.userId(), 'humanFeedback.studentSeen':false })
  'exerciseName' : () ->
    return decodeURIComponent(@exerciseId)