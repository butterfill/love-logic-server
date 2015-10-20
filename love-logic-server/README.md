Server and web ui for setting logic exercises (individually or in sets) and tracking students’ progress.

Exercises are URLs, e.g. to ask your students to write a truth table:

```
  /ex/tt/qq/not (A or B)
```

or to ask your students to write truth tables for an argument:

```
  /ex/tt/from/A or not B|not A or B/to/A and not A
```

To ask your students to create a possible situation in which some sentences are all true:

```
  /ex/create/qq/Happy(a)|exists x not Happy(x)|exists x exists y (Happy(x) and Sad(y) and SameShape(x,y))
```

Or to ask your students to create a counterexample to an argument:
```
  /ex/create/from/all x all y (LeftOf(x,y) arrow SameSize(x,y))/to/all x all y SameSize(x,y)
```

To ask you students to write a proof:
```
  /ex/proof/from/exists x all y (not x = y arrow TallerThan(x,y))/to/∀y ∃x ( ¬ x = y → TallerThan(x,y) )
```

There are also exercises involving translations to and from a first-order language, and evaluating
sentences or arguments in a possible situation you specify. (See logic-ex.butterfill.com for further examples.)

It's possible to set up a set of exercises linked to lecture topics (e.g. logic-1.butterfill.com).

If students to specify a tutor, that tutor can monitor their progress, add comments, grade exercises that aren’t automatically graded and answer requests for help.

(c) Stephen A. Butterfill 2015
All rights reserved.
Contact me if you want to use this code.