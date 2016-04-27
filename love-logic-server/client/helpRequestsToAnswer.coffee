
Template.helpRequestsToAnswer.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe "all_unanswered_help_requests_for_tutor"

Template.helpRequestsToAnswer.helpers
  'exercises' : () ->
    return HelpRequest.find(answer:{$exists:false})
  'gradeURL' : () -> ix.getGradeURL(@exerciseId)
  'exerciseName' : () ->
    return decodeURIComponent(@exerciseId)