---
title: number of submitted_exercises on zoxiy per year
created: 5/27/2025
tags:
  -
projects:
  - lp83px3XHTSxSfSwbOYkn
---
This is as at `5/27/2025`. 

I decided to free some space by deleting submitted exercises that are older.


```json
{ "_id" : 2015, "count" : 697 }
{ "_id" : 2016, "count" : 125462 }
{ "_id" : 2017, "count" : 128477 }
{ "_id" : 2018, "count" : 133581 }
{ "_id" : 2019, "count" : 162043 }
{ "_id" : 2020, "count" : 78787 }
{ "_id" : 2021, "count" : 141772 }
{ "_id" : 2022, "count" : 124545 }
{ "_id" : 2023, "count" : 107145 }
{ "_id" : 2024, "count" : 113629 }
{ "_id" : 2025, "count" : 74849 }
```




```js
rs.slaveOk()

db.submitted_exercises.aggregate([
  {
    $project: {
      year: { $year: "$created" }
    }
  },
  {
    $group: {
      _id: "$year",
      count: { $sum: 1 }
    }
  },
  {
    $sort: { _id: 1 }  // Sort by year ascending
  }
])
```