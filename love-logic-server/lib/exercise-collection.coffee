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
    name : 'UK_W20_PH133'
    description : 'Exercises for Introduction to Philosophy (PH133) at the University of Warwick'
  }
  {
    name : '_test'
    description : 'Test exercises'
  }
  # {
  #   name : 'UK_W20_PH136'
  #   description : 'Exercises for Logic I (PH136) at the University of Warwick'
  # }
]

exSets = [
  {
    courseName : '_test'
    variant : 'normal'
    description : 'These exercises are aimed at students who did not take a mathematical subject at A-Level or equivalent.'
    lectures : [
      {
        type : 'lecture'
        name : 'lecture_03'
        slides : 'http://logic-1.butterfill.com/lecture_03.html'
        handout : 'http://logic-1.butterfill.com/handouts/lecture_03.handout.pdf'
        units : [
          {
            type : 'unit'
            name : 'Formal Proof: ∧Elim and ∧Intro'
            slides : 'http://logic-1.butterfill.com/units/unit_21.html'
            rawReading : ['5.1', '6.1']
            rawExercises : [
              '/ex/proof/from/A and B/to/A'
              '/ex/proof/from/A|B/to/A and B'
              '/ex/proof/from/A|B|C/to/A and (B and C)'
              '/ex/proof/from/A and (B and C)/to/B'
              '/ex/proof/orInvalid/from/A and B|B and C/to/A and C'
              '/ex/proof/orInvalid/from/A or B|B or C/to/A or C'
              '/ex/proof/orInvalid/from/A and (B or C)/to/(A and B) or C'
              '/ex/proof/orInvalid/from/A or (B and C)/to/(A or B) and C'
              '/ex/proof/orInvalid/from/A and (B and C)/to/(A and B) and C'
              '/ex/TorF/qq/a logically valid argument cannot have a false conclusion|a logically valid argument cannot have false premises'
              '/ex/TorF/qq/a logically valid argument cannot have true premises and a false conclusion'
              """/ex/TorF/from/Happy(a)|not White(b)/to/exists x (Happy(x) and White(x))/world/[{"x":9,"y":0,"w":2,"h":2,"n":"a","c":"white","f":["}:","^","D"]},{"x":0,"y":0,"w":2,"h":2,"n":"b","c":"pink","f":[":\'","-","D"]},{"x":4,"y":0,"w":2,"h":2,"n":"","c":"purple","f":[":\'","-","("]}]/qq/The premises are true in the possible situation|The conclusion is false in the possible situation|The possible situation is a counterexample to the argument|The argument is valid"""
              "/ex/TorF/from/not A|A arrow B/to/not B/TTrow/A:F|B:T/qq/the first premise is true|the second premise is true|the conclusion is true|the possible situation is a counterexample to the argument"
              "/ex/TorF/from/not A|A arrow B/to/not B/TTrow/A:F|B:F/qq/not A|A arrow B|not B|the possible situation is a counterexample to the argument"
              "/ex/q/define ‘logically valid argument’"
              "/ex/q/state the rules for ∧"
            ]
          }
          {
            type : 'unit'
            name : '∨Intro'
            slides : 'http://logic-1.butterfill.com/units/unit_225.html'
            rawReading : ['6.1']
            rawExercises : [
              '/ex/proof/from/A/to/A or B'
              '/ex/proof/from/B/to/A or B'
              '/ex/proof/from/A and B/to/(A and B) or C'
              '/ex/proof/from/A and B/to/A or B'
              '/ex/trans/domain/3things/names/a=thing-1|b=thing-2/predicates/Fish1-x-is-a-fish|Between3-xIsBetweenYAndZ|Person1/sentence/A fish is between two people'
              '/ex/trans/domain/people/names/a=Ayesha|b=Beatrice/predicates/Runner1-x-is-a-runner|FasterThan2-xIsFasterThanY|Philosopher1-xIsAPhilosopher/sentence/Ayesha is a philosopher who is faster than Beatrice'
              '/ex/trans/domain/people/names/a=Ayesha|b=Beatrice/predicates/Runner1-x-is-a-runner|FasterThan2-xIsFasterThanY|Philosopher1-xIsAPhilosopher/sentence/Ayesha is a philosopher who is faster than a runner'
              '/ex/trans/domain/Ayesha|Beatrice|Caitlin/names/a=Ayesha/predicates/Fish1-x-is-a-fish|Between3-xIsBetweenYAndZ|Person1/sentence/Fish(a) and exists x exists y Between(a,x,y)'
              '/ex/trans/domain/Ayesha|Beatrice|Caitlin/names/a=Ayesha|b=Beatrice/predicates/Fish1-x-is-a-fish|Between3-xIsBetweenYAndZ|Person1/sentence/Person(a) and exists x exists y Between(a,x,y)'
              '/ex/tt/qq/A or B|B and not A|(A∨B)∧¬(B∧¬A)'
              '/ex/tt/qq/A or not B|not A arrow B'
              '/ex/tt/from/A or not B/to/not A arrow B'
              '/ex/tt/from/A or B|B or C/to/A or C'
              '/ex/tt/from/A and B|B and C/to/A and C'
              '/ex/create/qq/White(b)'
              '/ex/create/qq/White(a)|Red(b)|Happy(c)'
              '/ex/create/qq/LargerThan(a,b)|SameShape(a,b)'
              '/ex/create/qq/LargerThan(a,b)|SameSize(b,c)|not SameShape(b,c)'
              '/ex/create/qq/exists x (Happy(x) and Tall(x))'
              '/ex/create/qq/exists x exists y Adjacent(x,y) and exists x exists y not Adjacent(x,y)'
              """/ex/TorF/world/[{"x":9,"y":0,"w":2,"h":2,"n":"a,b","c":"white","f":["}:","^","D"]},{"x":0,"y":0,"w":2,"h":2,"n":"","c":"pink","f":[":\'","-","D"]},{"x":4,"y":0,"w":2,"h":2,"n":"","c":"purple","f":[":\'","-","("]}]/qq/White(a)|exists x Happy(x)|exists x exists y RightOf(x,y)"""
              """/ex/TorF/world/[{"x":9,"y":0,"w":2,"h":2,"n":"b","c":"pink","f":[":","-",")"]},{"x":3,"y":2,"w":2,"h":2,"n":"a","c":"orange","f":[";'","-","("]}]/qq/Orange(a)|exists x Sad(x)|exists x exists y Adjacent(x,y)"""
              '/ex/proof/from/A and (B and C)/to/B or D'
            ]
            
          }
          {
            type : 'unit'
            name : 'Rules of Proof for Identity'
            slides : 'http://logic-1.butterfill.com/units/unit_110.html'
            rawReading : ['2.2']
            rawExercises : [
              '/ex/proof/from/Red(a)|a=b/to/Red(b)'
              '/ex/proof/from/not Red(a)|a=b/to/not Red(b)'
              '/ex/proof/from/true/to/a=a'
              '/ex/proof/from/a=b|b=c/to/a=c'
              '/ex/proof/from/Loves(a,b)|a=c/to/Loves(c,b)'
              '/ex/proof/from/Loves(a,b)|Loves(b,a)|a=c/to/Loves(c,b) and Loves(b,c)'
            ] #unit.exercises
          } # unit
          {
            type : 'unit'
            name : 'test tt one sentence'
            slides : ''
            rawReading : []
            rawExercises : [
              '/ex/tt/qq/A and B'
              '/ex/tt/qq/A and not A'
              '/ex/tt/qq/A or not A'
            ] #unit.exercises
          } # unit
          {
            type : 'unit'
            name : 'test q'
            slides : ''
            rawReading : []
            rawExercises : [
              '/ex/q/Define logically valid argument'
              '/ex/q/Define counterexample'
            ] #unit.exercises
          } # unit
          {
            type : 'unit'
            name : 'test tt two sentences'
            slides : ''
            rawReading : []
            rawExercises : [
              '/ex/tt/qq/A and B|B and A'
              '/ex/tt/qq/A|A and B'
              '/ex/tt/qq/A and B|A'
              '/ex/tt/qq/A arrow C|A or C'
            ] #unit.exercises
          } # unit
        ] #lecture.exercises
      } # lecture
    ]
  }
  {
    courseName : '_test'
    variant : 'fast'
    description : 'These exercises are aimed at students with a qualification equivalent to further maths at A-Level.'
    lectures : [
      {
        type : 'lecture'
        name : 'lecture_03'
        slides : 'http://logic-1.butterfill.com/lecture_03.html'
        handout : 'http://logic-1.butterfill.com/handouts/lecture_03.handout.pdf'
        units : [
          {
            type : 'unit'
            name : 'Formal Proof: ∧Elim and ∧Intro'
            slides : 'http://logic-1.butterfill.com/units/unit_21.html'
            rawReading : ['5.1', '6.1']
            rawExercises : [
              '/ex/proof/from/A and B/to/A'
              '/ex/proof/from/A|B|C/to/A and (B and C)'
              '/ex/proof/from/A and B|B and C/to/A and C'
              '/ex/proof/from/A and (B and C)/to/(A and B) and C'
            ]
          }
          {
            type : 'unit'
            name : '∨Intro'
            slides : 'http://logic-1.butterfill.com/units/unit_225.html'
            rawReading : ['6.1']
            rawExercises : [
              '/ex/proof/from/A/to/A or B'
              '/ex/proof/from/A and B/to/A or B'
              '/ex/proof/from/A and (B and C)/to/B or D'
            ]
            
          }
          {
            type : 'unit'
            name : 'Rules of Proof for Identity'
            slides : 'http://logic-1.butterfill.com/units/unit_110.html'
            rawReading : ['2.2']
            rawExercises : [
              '/ex/proof/from/Red(a)|a=b/to/Red(b)'
              '/ex/proof/from/true/to/a=a'
              '/ex/proof/from/a=b|b=c/to/a=c'
              '/ex/proof/from/Loves(a,b)|Loves(b,a)|a=c/to/Loves(c,b) and Loves(b,c)'
            ] #unit.exercises
          } # unit
        ] #lecture.exercises
      } # lecture
    ]
  }
]
    
if not Meteor.isClient
  if Courses.find().count() is 0
    for c in courses
      Courses.insert(c)
  for exerciseSet in exSets
    if ExerciseSets.find({courseName:exerciseSet.courseName, variant:exerciseSet.variant}).count() is 0
      ExerciseSets.insert exerciseSet
  
  