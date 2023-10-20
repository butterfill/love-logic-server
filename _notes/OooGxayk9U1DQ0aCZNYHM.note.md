---
title: mongodb tricks and tips
created: 2023-10-19
tags:
  -
projects:
  - lp83px3XHTSxSfSwbOYkn
---


see also:

* \ref{note:MRw-zw0NGqmpeErI1blGt} : this has a bit on how to install the old version 3.2 (which you need for meteor!)

* \ref{note:yIrfOTjmFE-TiwGnfITbA}



### tip

If you have a problem with  "could not find member to sync from", try setting manually in the mongo shell:

```
rs.syncFrom("10.0.0.34:27017")
```
