# Functions used across various publications and methods.
# Note: this runs on client and server.

@wy = {}

# ----
# Relating to grading

# Return a list of the ids of those who specify `tutor_email` as their `seminar_tutor`
wy.getTuteeIds = (tutor_email) ->
  if not tutor_email
    console.log "Current user has no email address!"
    return [] 
  tutees = Meteor.users.find({'profile.seminar_tutor':tutor_email}, {fields:{_id:1}}).fetch()
  return (x._id for x in tutees)


      

