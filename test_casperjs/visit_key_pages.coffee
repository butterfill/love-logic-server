x = require('casper').selectXPath

pwd = '.'
config = require("#{pwd}/config")
config.configure(casper)

pageObjects = require("#{pwd}/pageObjects")
testActions = require("#{pwd}/testActions")


# THIS TEST IS SUPPOSED TO FAIL
# (It’s purpose is to check that exceptions in template helpers cause tests to fail!)


casper.test.begin 'visit key pages (check there is no exception in template helpers)', (test) ->

  casper.start config.URL, () ->
    # nothing to do.
  
  x = require('casper').selectXPath
  
  testActions.doLogin(casper, test, x)

  pages = [
    '/course/UK_W20_PH126/exerciseSet/normal-normal'
    '/course/UK_W20_PH126/exerciseSet/normal-normal/lecture/Lecture%2001'
    '/course/UK_W20_PH126/exerciseSet/normal-normal/lecture/Lecture%2001/listExercises'
    '/course/UK_W20_PH126/exerciseSet/normal-normal/lecture/Lecture%2002'
    '/course/UK_W20_PH126/exerciseSet/normal-normal/lecture/Lecture%2002/listExercises'
    '/exercisesToGrade'
    '/helpRequestsToAnswer'
    '/myTutees'
    '/myTuteesProgress'
    '/mySubmittedExercises'
    
    '/ex/q/define ‘logically valid argument’'
    
    '/ex/TorF/from/Either the pig went up the left fork or it went up the right fork|The pig didn’t go up the left fork/to/The pig went up the right fork/qq/The argument is logically valid'
    "/ex/TorF/from/A or B|not A/to/B/qq/The argument is logically valid"
    "/ex/TorF/qq/‘Ayesha cries’ is an atomic sentence|‘Ayesha cries or Beatrice weeps’ is a non-atomic sentence|‘People come and people go’ is a non-atomic sentence"
    """/ex/TorF/from/Happy(a) or Happy(b)|Happy(a)/to/not Happy(b)/world/[{"x":9,"y":0,"w":2,"h":2,"n":"a","c":"white","f":["}:","^","D"]},{"x":0,"y":0,"w":2,"h":2,"n":"b","c":"pink","f":[":'","-","D"]},{"x":4,"y":0,"w":2,"h":2,"n":"","c":"purple","f":[":'","-","("]}]/qq/Happy(a) or Happy(b)|Happy(a)|not Happy(b)|The possible situation is a counterexample to the argument"""
    """/ex/TorF/from/Sad(a)|Neutral(b)/to/Laughing(c)/world/[{"x":5,"y":0,"w":2,"h":2,"n":"b","c":"pink","f":[":","-","|"]},{"x":8,"y":0,"w":2,"h":2,"n":"c","c":"purple","f":[";","^","D"]},{"x":2,"y":0,"w":2,"h":2,"n":"a","c":"blue","f":[":",">","("]}]/qq/Sad(a)|Neutral(b)|Laughing(c)|The argument is logically valid|The argument is sound in this possible situation"""
    """/ex/TorF/world/[{"x":9,"y":0,"w":2,"h":2,"n":"a","c":"white","f":["}:","^","D"]},{"x":0,"y":0,"w":2,"h":2,"n":"b","c":"pink","f":[":'","-","D"]},{"x":4,"y":0,"w":2,"h":2,"n":"","c":"purple","f":[":'","-","("]}]/qq/Happy(a)|not Happy(b)|Happy(a) or Happy(b)"""
    """/ex/TorF/world/[{"x":3,"y":0,"w":2,"h":2,"n":"","c":"yellow","f":[":","-",")"]},{"x":5,"y":0,"w":2,"h":2,"n":"","c":"red","f":[":",">",")"]}]/qq/exists x (Happy(x) and Red(x))|all x (Happy(x) arrow Red(x))"""
    
    "/ex/create/qq/White(a)"
    "/ex/create/qq/not White(a)|Happy(a)"
    "/ex/create/qq/all x (Yellow(x) arrow Happy(x))|all x (Red(x) arrow Sad(x))"
    "/ex/create/from/TallerThan(a,b)/to/WiderThan(a,b)"
    "/ex/create/from/Adjacent(a,b)|Adjacent(b,c)/to/Adjacent(a,c)"
    "/ex/create/orValid/from/White(a)|a=b/to/White(b)"
    
    "/ex/trans/domain/Ayesha|Beatrice/names/a=Ayesha/predicates/White1/sentence/Ayesha is white"
    "/ex/trans/domain/Ayesha|Beatrice/names/a=Ayesha|b=Beatrice/predicates/Yellow1|Red1/sentence/Yellow(a) or Red(b)"
    
    "/ex/tt/noQ/qq/A and B"
    "/ex/tt/qq/(A and B) or C"
    "/ex/tt/qq/not (A or B)|not A or not B"
    "/ex/tt/from/not A or not B|A/to/not B"
    
    "/ex/proof/from/A/to/A or B"
    "/ex/proof/from/A|C/to/A and (B or C)"
    "/ex/proof/orInvalid/from/A or B|not A/to/B"
    
    "/ex/scope/qq/(Intelligent(a) and Dissatisfied(a)) or Happy(a)|Intelligent(a) and (Dissatisfied(a) or Happy(a))|(A ∨ B) ∧ C|A ∨ (B ∧ C)|A arrow (B arrow C)|(A arrow B) arrow C"
    "/ex/scope/qq/¬(A ∧ B)|¬A ∧ ¬B|¬A and ¬B|¬(A arrow B)"
    
  ]

  for url in pages
    testActions.visitPage( encodeURIComponent(url), casper, test)
  # testActions.visitPage('/course/UK_W20_PH126/exerciseSet/normal-normal', casper, test)
  
  casper.then () ->
    @capture 'img/visit_key_pages.png'
    
  
  casper.run () ->
    test.done()

