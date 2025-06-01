---
title: how to run zoxiy on local machine
created: 2023-01-31
tags:
  -
projects:
  - lp83px3XHTSxSfSwbOYkn
---

## install meteor

instructions:
  * \ref{url:https://www.meteor.com/developers/install}
  * \ref{url:https://docs.meteor.com/install.html}

max node version is 14 so:

```
nvm i v14.21.2
nvm use v14.21.2
npm i -g meteor
meteor --version
```

## run

```
cd love-logic-server 
meteor
```

This will generate an error `error: CERT_HAS_EXPIRED` (because ‘Node.js before 10 (and Meteor before 1.9) doesn’t include let’s encrypt’s newest root certificate’—\ref{url:https://forums.meteor.com/t/solved-error-certificate-has-expired/49912/13}).  Ignore this:

```
NODE_TLS_REJECT_UNAUTHORIZED=0 meteor
```

Now it should run.

At this stage, local database will not be interesting but you should be able to start it.

You can register an account (tester/tester with email tester@) and do an exercise.


## connect to local mongo database 

You can connect to local db:

```
meteor mongo
```

Then, in the mongo shell:

```
show dbs
use meteor
show collections
db.users.find({})
db.courses.find({})
```


## install a local mongodb

download version 3.2 binaries from \ref{url:https://www.mongodb.com/try/download/community}

UPDATE: use 3.6 binaries now (updated on the server)

instructions: \ref{url:https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-os-x-tarball/}

already installed on eleven mac:
```
mongod --dbpath /usr/local/var/mongodb
```

If you need to install:

setup:

```
cd ~/mongo-dbs
mkdir mongodb3.2
cd mongodb3.2
mv ~/Downloads/mongodb-osx-x86_64-3.2.22 .  
mkdir -p var/log/mongodb 
mkdir -p var/mongodb
```

run:

```
./mongodb-osx-x86_64-3.2.22/bin/mongod --dbpath var/mongodb --logpath var/log/mongodb/mongo.log  # add --fork
```

This generates a security error. You have to open `system settings/security and privacy` and click allow.

Then access the mongo console:

```
./mongodb-osx-x86_64-3.2.22/bin/mongo 
```

## import data to mongodb

```
cd ~/Documents/web-app-backup/logic-ex-backup
tar xvf logic[latest version]
cd logic-test-2023-01-30-0910

~/mongo-dbs/mongodb3.2/mongodb-osx-x86_64-3.2.22/bin/mongorestore .
```

back in the mongodb console:
```
show dbs
use love-logic
db.users.find({}).count()
```

## connect local meteor to own local mongodb instance

in the `love-logic-server/love-logic-server` folder:

```
source setMongoURL.sh 
meteor
```