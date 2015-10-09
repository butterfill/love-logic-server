
Template.helpRequestsToAnswer.onCreated () ->
  templateInstance = this
  templateInstance.autorun () ->
    templateInstance.subscribe "all_unanswered_help_requests_for_tutor"

Template.helpRequestsToAnswer.helpers
  'exercises' : () ->
    return HelpRequest.find(answer:{$exists:false})
  'gradeURL' : () ->
    return (@exerciseId.replace(/\/$/, ''))+"/grade"
  'exerciseName' : () ->
    return decodeURIComponent(@exerciseId)