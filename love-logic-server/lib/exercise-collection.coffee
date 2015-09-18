@Courses = new Mongo.Collection('courses')
@ExerciseSets = new Mongo.Collection('exercise_sets')

# Structure : 
#   country_institution_course
#     variant
#       lecture
#         unit
#           list of exercises (urls)
courses = [
  {
    name : 'UK_W20_PH126'
    description : 'Exercises for Logic I (PH126) at the University of Warwick'
  }
  {
    name : 'UK_W20_PH136'
    description : 'Exercises for Logic I (PH136) at the University of Warwick'
  }
  {
    name : 'UK_W20_PH133'
    description : 'Exercises for Introduction to Philosophy (PH133) at the University of Warwick'
  }
]

exSets = [
  {
    courseName : 'UK_W20_PH126'
    variant : 'normal'
    description : 'These exercises are suitable for students who did not take a mathematical subject at A-Level or equivalent.'
    exercises :
      lecture_03 :
        unit_21 : [
          '/ex/proof/from/A and B/to/A'
          '/ex/proof/from/A|B/to/A and B'
          '/ex/proof/from/A|B|C/to/A and (B and C)'
          '/ex/proof/from/A and (B and C)/to/B'
          '/ex/proof/from/A and B|B and C/to/A and C'
          '/ex/proof/from/A and (B and C)/to/(A and B) and C'
        ]
        unit_110 : [
          '/ex/proof/from/Red(a)|a=b/to/Red(b)'
          '/ex/proof/from/not Red(a)|a=b/to/not Red(b)'
          '/ex/proof/from/true/to/a=a'
          '/ex/proof/from/a=b|b=c/to/a=c'
          '/ex/proof/from/Loves(a,b)|a=c/to/Loves(c,b)'
          '/ex/proof/from/Loves(a,b)|Loves(b,a)|a=c/to/Loves(c,b) and Loves(b,c)'
        ]
        unit_225 : [
          '/ex/proof/from/A/to/A or B'
          '/ex/proof/from/B/to/A or B'
          '/ex/proof/from/A and B/to/(A and B) or C'
          '/ex/proof/from/A and B/to/A or B'
          '/ex/proof/from/A and (B and C)/to/B or D'
        ]
  }
  {
    courseName : 'UK_W20_PH126'
    variant : 'fast'
    description : 'These exercises are suitable for students with a qualification equivalent to further maths at A-Level.'
    exercises :
      lecture_03 :
        unit_21 : [
          '/ex/proof/from/A and B/to/A'
          '/ex/proof/from/A and B|B and C/to/A and C'
          '/ex/proof/from/A and (B and C)/to/(A and B) and C'
        ]
        unit_110 : [
          '/ex/proof/from/Red(a)|a=b/to/Red(b)'
          '/ex/proof/from/Loves(a,b)|a=c/to/Loves(c,b)'
          '/ex/proof/from/Loves(a,b)|Loves(b,a)|a=c/to/Loves(c,b) and Loves(b,c)'
        ]
        unit_225 : [
          '/ex/proof/from/A/to/A or B'
          '/ex/proof/from/A and B/to/A or B'
          '/ex/proof/from/A and (B and C)/to/B or D'
        ]
  }
]
    
if not Meteor.isClient
  if Courses.find().count() is 0
    for c in courses
      Courses.insert(c)
  if ExerciseSets.find().count() is 0
    for e in exSets
      ExerciseSets.insert e
  
  