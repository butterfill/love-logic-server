options = {
  keepHistory: 1000 * 60 * 5,
  localSearch: true
}
TutorSearch = new SearchSource('tutors', ['emails.address', 'profile.name', options])

# -------------
# Template helpers

Template.main.onCreated () ->
  self = this
  
  self.nofHelpRequestsForTutor = new ReactiveVar()

  self.autorun () ->
    self.subscribe('subscriptions')
    self.subscribe('next_exercise_with_unseen_feedback')
    self.subscribe('next_help_request_with_unseen_answer')
    if ix.userIsTutor()
      Meteor.call "nofHelpRequestsForTutor", (error, result) ->
        self.nofHelpRequestsForTutor.set(result)

Template.main.onRendered () ->
  ix.checkBrowserCompatible()
  @autorun () ->
    FlowRouter.go('/sign-in') unless Meteor.userId()?
  

getNextExercisesWithUnseenFeedback = () ->
  return SubmittedExercises.findOne({ $and:[{owner:Meteor.userId()}, {'humanFeedback.studentSeen':false}] })

Template.main.helpers
  isLastExercise : () -> Session.get("#{ix.getUserId()}/lastExercise")?
  isTutor : ix.userIsTutor
  isInstructor : ix.userIsInstructor
  hasSubscriptions : () ->
    owner = Meteor.userId()
    return Subscriptions.find({owner}).count() >0
  hasNoSubscriptions : () ->
    owner = Meteor.userId()
    return Subscriptions.find({owner}).count() is 0
  subscriptions : () ->
    owner = Meteor.userId()
    return Subscriptions.find({owner})

  hasSeminarTutor : () ->
    return Meteor.user()?.profile?.seminar_tutor?
  hasInstructor : () ->
    return Meteor.user()?.profile?.instructor?
  seminarTutor : () ->
    return Meteor.user()?.profile?.seminar_tutor
  instructor : () ->
    return Meteor.user()?.profile?.instructor
  instructorEmail : () ->
    return Meteor.user()?.profile?.instructor
  
  hasNewGrades : () ->
    return getNextExercisesWithUnseenFeedback()?
  
  hasNewHelpRequestAnswers : () ->
    return HelpRequest.find({ requesterId:Meteor.userId(), answer:{$exists:true}, studentSeen:{$exists:false}}, {reactive:false}).count() > 0
  nextHelpRequestAnswerLink : () ->
    helpReq = HelpRequest.findOne({ requesterId:Meteor.userId(), studentSeen:{$exists:false} }, {reactive:false})
    link = helpReq.exerciseId
    return link
  
  emailAddress : () ->
    return ix.getUserEmail()
  
  nofHelpRequestsForTutor : () ->
    return Template.instance().nofHelpRequestsForTutor?.get?()
  
  getTutors : () ->
    res = TutorSearch.getData({
      transform : (matchText, regExp) ->
        return matchText.replace(regExp, "<b>$&</b>")
      sort : {isoScore:-1}
    })
    return res
  getTutorsIsLoading : () -> TutorSearch.getStatus().loading
  
Template.main.events
  'click #resume-last-exercise' : (event, template) ->
    url = Session.get("#{ix.getUserId()}/lastExercise")
    FlowRouter.go(url)
    
  'click .changeSeminarTutor' : (event, template) ->
    $('#seminar-tutor-modal').openModal()
    tutor = Meteor.user()?.profile?.seminar_tutor
    if tutor?
      $('input.seminarTutor').val(tutor).focusin()
      TutorSearch.search(tutor)
    else
      TutorSearch.search('')
  'keyup input.seminarTutor' : (event, template) ->
    text = $(event.target).val().trim()
    TutorSearch.search(text)
  'click a.setThisTutor' : (event, template) ->
    # This is a click in the autocomplete list
    email = @emails[0].address
    $('input.seminarTutor').val(email).focusin()
    TutorSearch.search(email)
  'click #confirm-set-seminar-tutor-email' : (event, template) ->
    newAddress = $('input.seminarTutor').val()
    Meteor.call "updateSeminarTutor", newAddress, (error) ->
      if error
        Materialize.toast error.message, 4000
      else
        Materialize.toast "Your seminar tutor has been updated", 4000

  'click #confirm-set-instructor-email' : (event, template) ->
    newAddress = $('input.instructor').val()
    Meteor.call "updateInstructor", newAddress, (error) ->
      if error
        Materialize.toast error.message, 4000
      else
        Materialize.toast "Your instructor has been updated", 4000
  
  'click #confirm-update-email' : (event, template) ->
    newAddress = $('textarea.newEmailAddress').val()
    Meteor.call "updateEmailAddress", newAddress, (error) ->
      if error
        Materialize.toast error.message, 4000
      else
        Materialize.toast "Your email address has been updated", 4000
  
  
  'click .changeInstructor' : (event, template) ->
    $('#instructor-modal').openModal()
  'click .changeEmail' : (event, template) ->
    $('#change-email-modal').openModal()

