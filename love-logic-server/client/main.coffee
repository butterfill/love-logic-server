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

Template.changeTutorModal.onRendered () ->
  # Configure the typeahead
  # Currently a bit wonky : uses a SearchSource (which is reactive)
  # together with the typeahead.js async method --- doesn’t fit well.
  # Note that there’s also a keyup event that runs TutorSearch below 
  # --- without this, the chance of getting all relevant results is decreased.
  $('#seminarTutorTypeahead').typeahead({
    hint : true
    minLength : 2
    highlight : true
  },{
    name : 'students'
    async : true
    display : (user) -> user.emails[0].address
    source : (query, syncResults, asyncResults) ->
      TutorSearch.search(query)
      getData = () -> TutorSearch.getData({
          # transform : (matchText, regExp) ->
          #   return matchText.replace(regExp, "<b>$&</b>")
          sort : {isoScore:-1}
        })
      data = getData()
      syncResults( data )
      oldIds = (x._id for x in data)
      sendMoreResults = () -> 
        newData = getData()
        moreData = (x for x in newData unless x?._id in oldIds)
        asyncResults( moreData )
      setAutorun = () ->
        Tracker.autorun (c) ->
          return unless TutorSearch.getStatus().loaded
          c.stop()
          sendMoreResults()
      # short delay before setting autorun so that TutorSearch has
      # time to tell us it is loading
      _.delay( setAutorun, 50)
        
    templates : 
      empty : [
          '<div class="empty-message">',
            'unable to find any tutor names or emails that match the current query',
          '</div>'
        ].join('\n')
      suggestion : (user) ->
        return "<div>#{user.emails[0].address} - #{user.profile.name}<div>"
      
  })
  
  

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
  isInstructorOrTutor : ix.isInstructorOrTutor
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
  
Template.main.events
  'click #resume-last-exercise' : (event, template) ->
    url = Session.get("#{ix.getUserId()}/lastExercise")
    FlowRouter.go(url)
    
  'click .changeSeminarTutor' : (event, template) ->
    tutor = Meteor.user()?.profile?.seminar_tutor
    if tutor?
      TutorSearch.search(tutor)
    else
      TutorSearch.search('')
    MaterializeModal.form
      title : "Tutor"
      bodyTemplate : "changeTutorModal"
      submitLabel : "update"
      closeLabel : "cancel"
      seminarTutorEmail : Meteor.user()?.profile?.seminar_tutor or ''
      callback : (error, response) ->
        if response.submit
          newAddress = response.form.seminarTutorEmail
          Meteor.call "updateSeminarTutor", newAddress, (error) ->
            if error
              Materialize.toast error.message, 4000
            else
              Materialize.toast "Your seminar tutor has been updated", 4000
              
  'click .changeInstructor' : (event, template) ->
    MaterializeModal.form
      title : "Instructor"
      bodyTemplate : "changeInstructorModal"
      submitLabel : "update"
      closeLabel : "cancel"
      instructorEmail : Meteor.user()?.profile?.instructor
      callback : (error, response) ->
        if response.submit
          newAddress = response.form.instructorEmail
          Meteor.call "updateInstructor", newAddress, (error) ->
            if error
              Materialize.toast error.message, 4000
            else
              Materialize.toast "Your instructor has been updated", 4000
    
  'click .changeEmail' : (event, template) ->
    MaterializeModal.form
      title : "Change Email"
      bodyTemplate : "changeEmailModal"
      submitLabel : "update"
      closeLabel : "cancel"
      emailAddress : ix.getUserEmail()
      callback : (error, response) ->
        if response.submit
          newAddress = response.form.emailAddress
          Meteor.call "updateEmailAddress", newAddress, (error) ->
            if error
              Materialize.toast error.message, 4000
            else
              Materialize.toast "Your email address has been updated", 4000

Template.changeTutorModal.events
  'keyup .tutorTypeahead' : _.throttle( (event, template) ->
      # help the typeahead : ensure that TutorSearch is uptodate if possible
      # (Not sure why this is necessary; but without it, some entries are
      # missing.)
      $target = $(event.target)
      text = $target.val()
      TutorSearch.search(text)
    , 200 )
  
