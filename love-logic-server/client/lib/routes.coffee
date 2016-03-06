# ------
# Routes 


FlowRouter.notFound =
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'routeNotFound'



FlowRouter.route '/', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'main'

FlowRouter.route '/termsOfUse', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'termsOfUse'
  name : 'termsOfUse'

FlowRouter.route '/oldBrowserSorry', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'oldBrowserSorry'
  name : 'oldBrowserSorry'


FlowRouter.route '/testThrowException', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'testThrowException'

# ------
# Admin routes for students

FlowRouter.route '/courses', 
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'courses'

FlowRouter.route '/course/:_courseName',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exerciseSetsForCourse'

FlowRouter.route '/course/:_courseName/exerciseSet/:_variant',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exerciseSet'
FlowRouter.route '/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exerciseSet'
FlowRouter.route '/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exerciseSet'
FlowRouter.route '/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/listExercises',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'listExercises'
FlowRouter.route '/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit/listExercises',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'listExercises'

FlowRouter.route '/feedbackToReview',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'feedbackToReview'

FlowRouter.route '/mySubmittedExercises',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'mySubmittedExercises'



# ------
# Exercise routes

# TODO: add tutor: provide a list of tutors to select from (or can enter custom email), the list is restricted to the domain of the user’s email address

# TODO: /ex/counter checks arity of predicate tuples

# TODO: exercises to grade sorted by course and lecture

# TODO: exercise editor (can create exercise sets)

# TODO: stats - how many Warwick people

# TODO: use http://pieroxy.net/blog/pages/lz-string/index.html to compress exercisesIds to avoid problem with long URLS (mongodb index fails!)

# TODO: tutees: tutor can see their progress on exercise sets the tutor is following

# TODO: link to guides for specific types of exercise from each type of exercise
# TODO: generic help by exercise type (e.g. how to write proofs).

# TODO: profile.seminar_tutor should specify id, not email address!

# TODO: test the fix to the GradedAnswers Leftof(b,a) is LeftOf(b,a) bug

# TODO: tutor can ‘disown’ tutee, and mass disown tutees; instructor can disown tutors --- this will enable transition from one year to the next

# TODO: exercisesToGrade doesn’t pick up on ‘Beatrice is’.  Why not?

# TODO: after submit, a 'SHOW ME AN ANSER' button appears (/proof and /create)

# TODO: all emails are lower case 

# TODO: tidy up feedback on incorrect proofs

# TODO: proofs can be formatted (symbols; neat spacing)

# TODO: can review GradedAnswers

# TODO: only trusted users can create GradedAnswers

# TODO: instructor can monitor all students’ progress.

# TODO: exercise - write down the scopes of different operators.

# TODO: Allow users to see and complete exercises, but not submit them, without being logged in? (Tricky because when the log in the saved answer will no longer appear; but maybe necessary for advertising?)



# Write a proof exercise
FlowRouter.route '/ex/proof/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'proof_ex'
FlowRouter.route '/ex/proof/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
# Say that the argument is invalid or write a proof
FlowRouter.route '/ex/proof/orInvalid/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'proof_ex'
FlowRouter.route '/ex/proof/orInvalid/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
    
# Translation exercise.  Example URL: /ex/trans/domain/5things/names/a=thing1%7Cb=thing2/predicates/Fish1%7CPerson2%7CRed1/sentence/At%20least%20two%20people%20are%20not%20fish
# It will work out which direction you are translating in by what language `:_sentence` is in.
FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'trans_ex'
FlowRouter.route '/ex/trans/domain/:_domain/names/:_names/predicates/:_predicates/sentence/:_sentence/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Create a possible situation in which `_sentences` are all true
FlowRouter.route '/ex/create/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'
# As /ex/create but describe the possible situation explicitly (extensions for predicates, etc)
FlowRouter.route '/ex/counter/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'counter_ex'
# Either say that the sentences are inconsistent or else create a possible situation in which `_sentences` are all true
FlowRouter.route '/ex/create/orInconsistent/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'
FlowRouter.route '/ex/counter/orInconsistent/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'counter_ex'
FlowRouter.route '/ex/create/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
FlowRouter.route '/ex/counter/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
FlowRouter.route '/ex/create/orInconsistent/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
FlowRouter.route '/ex/counter/orInconsistent/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Create a counterexample to the argument
FlowRouter.route '/ex/create/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'
FlowRouter.route '/ex/counter/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'counter_ex'
# Either say that the argument is logically valid or else create a counterexample to the argument
FlowRouter.route '/ex/create/orValid/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'create_ex'
FlowRouter.route '/ex/counter/orValid/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'counter_ex'
FlowRouter.route '/ex/create/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
FlowRouter.route '/ex/counter/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
FlowRouter.route '/ex/create/orValid/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
FlowRouter.route '/ex/counter/orValid/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Construct truth tables for the sentences
FlowRouter.route '/ex/tt/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'
FlowRouter.route '/ex/tt/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
# As above, but don’t ask the questions
FlowRouter.route '/ex/tt/noQ/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'
FlowRouter.route '/ex/tt/noQ/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Construct truth tables for argument and say whether it is valid, specifying a counterexample if appropriate. TODO: update template so it copes with this  TODO: Add examples
FlowRouter.route '/ex/tt/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'
FlowRouter.route '/ex/tt/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'
# As above, but don’t ask the questions
FlowRouter.route '/ex/tt/noQ/from/:_premises/to/:_conclusion',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'tt_ex'
FlowRouter.route '/ex/tt/noQ/from/:_premises/to/:_conclusion/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

FlowRouter.route '/ex/scope/qq/:_sentences/',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'scope_ex'
FlowRouter.route '/ex/scope/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'


# Answer a question in free text
FlowRouter.route '/ex/q/:_question/',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'q_ex'
FlowRouter.route '/ex/q/:_question/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# ---
# The exercises following all use the `evaluate_ex` template

# Answer questions about an argument and a possible situation (predicate)
# E.g. /ex/TorF/from/I am a dog|I am a cat/to/I am a dog and a cat/world/[{"x":9,"y":0,"w":2,"h":2,"n":"a,b","c":"white","f":["}:","^","D"]},{"x":0,"y":0,"w":2,"h":2,"n":"","c":"pink","f":[":\'","-","D"]},{"x":4,"y":0,"w":2,"h":2,"n":"","c":"purple","f":[":\'","-","("]}]/qq/The argument is sound|The argument is valid
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/world/:_world/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/world/:_world/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about an argument and a possible situation (TTrow)
# e.g. /ex/TorF/from/not A|A arrow B/to/not B/TTrow/A:F|B:T/qq/the first premise is true|the second premise is true|the conclusion is true|the possible situation is a counterexample to the argument
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/TTrow/:_TTrow/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/TTrow/:_TTrow/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about an argument
# e.g. /ex/TorF/from/I am a dog|I am a cat/to/I am a dog and a cat//qq/The argument is sound|The argument is valid
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/from/:_premises/to/:_conclusion/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about a possible situation (predicate)
FlowRouter.route '/ex/TorF/world/:_world/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/world/:_world/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions about a possible situation (TTrow)
FlowRouter.route '/ex/TorF/TTrow/:_TTrow/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/TTrow/:_TTrow/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'

# Answer questions
FlowRouter.route '/ex/TorF/qq/:_sentences',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'TorF_ex'
FlowRouter.route '/ex/TorF/qq/:_sentences/grade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'GradeLayout'


# ------
# Grading (=marking) routes

FlowRouter.route '/myTutees',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTutees'

FlowRouter.route '/myTutors',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTutors'

FlowRouter.route '/exercisesToGrade',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'exercisesToGrade'

FlowRouter.route '/helpRequestsToAnswer',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'helpRequestsToAnswer'

FlowRouter.route '/myTuteesProgress',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTuteesProgress'
FlowRouter.route '/myTuteesProgress/course/:_courseName/exerciseSet/:_variant',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTuteesProgress'
FlowRouter.route '/myTuteesProgress/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTuteesProgress'
FlowRouter.route '/myTuteesProgress/course/:_courseName/exerciseSet/:_variant/lecture/:_lecture/unit/:_unit',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'myTuteesProgress'



# ------
# Other routes

# Add or create an exercise set
FlowRouter.route '/upsertExerciseSet',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'upsertExerciseSet'

# Stats (nof exercises submitted, etc)
FlowRouter.route '/stats',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'stats'

FlowRouter.route '/resetTester',
  action : (params, queryParams) ->
    BlazeLayout.render 'ApplicationLayout', main:'resetTester'

