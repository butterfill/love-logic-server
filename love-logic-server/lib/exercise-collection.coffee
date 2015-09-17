@ExerciseSets = new Mongo.Collection('exercise_sets')

UK_W20_PH126 =
  normal_exercises :
    'lecture_03' :
      unit_21 : [
        '/ex/proof/from/A and B/to/A'
        '/ex/proof/from/A|B/to/A and B'
        '/ex/proof/from/A|B|C/to/A and (B and C)'
        '/ex/proof/from/A and (B and C)/to/B'
        '/ex/proof/from/A and B|B and C/to/A and C'
        '/ex/proof/from/A and (B and C)/to/(A and B) and C'
      ]
      'unit_110' : [
        '/ex/proof/from/Red(a)|a=b/to/Red(b)'
        '/ex/proof/from/not Red(a)|a=b/to/not Red(b)'
        '/ex/proof/from/true|a=a'
        '/ex/proof/from/a=a|b=c/to/a=c'
        '/ex/proof/from/Loves(a,b)|a=c/to/Loves(c,b)'
        '/ex/proof/from/Loves(a,b)|Loves(b,a)|a=c/to/Loves(c,b) and Loves(b,c)'
      ]
      'unit_225' : [
        '/ex/proof/from/A/to/A or B'
        '/ex/proof/from/B/to/A or B'
        '/ex/proof/from/A and B/to/(A and B) or C'
        '/ex/proof/from/A and B/to/A or B'
        '/ex/proof/from/A and (B and C)/to/B or D'
      ]
    
if not Meteor.isClient
  
  if ExerciseSets.find({name:'UK_W20_PH126'}).count() is 0
    ExerciseSets.insert {
      name : 'UK_W20_PH126'
      exercises : UK_W20_PH126
    }
  
  