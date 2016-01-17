

# ========
# Template: trans_ex_display_question
# (This is a fragment that is used both for students and graders)

Template.q_ex_display_question.helpers
  theQuestion : () -> 
    return ix.getQuestion(@)

Template.q_ex.onCreated () ->
  self = this
  @autorun () ->
    FlowRouter.watchPathChange()
    exerciseId = ix.getExerciseId()
    self.subscribe 'graded_answers', exerciseId

Template.q_ex.events 
  'click button#submit' : (event, template) ->
    answer = ix.getAnswer()
    
    doc = 
      answer : 
        type : 'q'
        content : answer
    
    # Try to get human feedback from the grade and comments on a previous student’s answer.
    humanFeedback = ix.gradeUsingGradedAnswers()
    if humanFeedback?
      doc.humanFeedback = humanFeedback
      
    ix.submitExercise doc, () ->
        Materialize.toast "Your answer has been submitted.", 4000
    return
