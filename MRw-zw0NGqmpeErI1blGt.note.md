---
title: "zoxiy (love-logic) deploy notes"
created: 2023-01-29
tags:
  -
projects:
  - lp83px3XHTSxSfSwbOYkn
---

*These were written a long time after initial deploy and I forgot a lot.*

# mongo

mongod --version:
```
db version v3.2.22
git version: 105acca0d443f9a47c1a5bd608fd7133840a58dd
OpenSSL version: OpenSSL 1.0.2g  1 Mar 2016
allocator: tcmalloc
modules: none
build environment:
    distmod: ubuntu1604
    distarch: x86_64
    target_arch: x86_64
```

NB: meteor 1.2 will probably not work with mongodb 3.6 on. (I think
I once tried with mongodb 3.6 and it would not work. Will eventually
have to upgrade to more recent meteor etc.)

Manual install seems fine (adding repositories did not work):

```
wget http://launchpadlibrarian.net/253903472/libssl1.0.0_1.0.2g-1ubuntu4_amd64.deb
dpkg -i libssl1...

wget https://repo.mongodb.org/apt/ubuntu/dists/xenial/mongodb-org/3.2/multiverse/binary-amd64/mongodb-org-mongos_3.2.10_amd64.deb
dpkg -i mongodb-org-mongos_3.2.10_amd64.deb

wget https://repo.mongodb.org/apt/ubuntu/dists/xenial/mongodb-org/3.2/multiverse/binary-amd64/mongodb-org-server_3.2.10_amd64.deb
dpkg -i mongodb-org-server_3.2.10_amd64.deb

wget https://repo.mongodb.org/apt/ubuntu/dists/xenial/mongodb-org/3.2/multiverse/binary-amd64/mongodb-org-shell_3.2.10_amd64.deb
dpkg -i mongodb-org-shell_3.2.10_amd64.deb

wget https://repo.mongodb.org/apt/ubuntu/dists/xenial/mongodb-org/3.2/multiverse/binary-amd64/mongodb-org-tools_3.2.10_amd64.deb
dpkg -i mongodb-org-tools_3.2.10_amd64.deb

wget https://repo.mongodb.org/apt/ubuntu/dists/xenial/mongodb-org/3.2/multiverse/binary-amd64/mongodb-org_3.2.10_amd64.deb
dpkg -i mongodb-org_3.2.10_amd64.deb


systemctl restart mongod.service 

mongo  # wait for a bit if it doesn’t connect at first, can take time
```

documentation: \ref{url:https://www.mongodb.com/docs/v3.2/}

check config: `systemctl show mongod.service`

## add new member to replica set

instructions: \ref{url:https://www.mongodb.com/docs/v3.2/tutorial/expand-replica-set/}

`systemctl stop mongod.service`

Copy `/etc/mongod.conf` from another member: be sure to update bind_ip for the correct tinc address.

If fails, see `/var/log/mongodb/mongo.log`

(I did try copying data from another member but this was a mistake: data changed during copy and created errors.)

restart mongod service

on the primary, in the mongo shell:

```
rs.add({ host: "10.0.0.36:27017" })
```

If it does not work, check firewall (have you `ufw allow from 10.0.0.0/24`?)

wait until the prompt in the mongo shell goes from `STARTUP2` to `SECONDARY`

also use `rs.status()` to check status of replica set

(And `du -h -d0 /var/lib/mongodb/` to see how much has copied over)


## remove member from replica set

instructions: \ref{url:https://www.mongodb.com/docs/v3.2/tutorial/remove-replica-set-member/}

on the primary do `rs.remove("10.0.0.2:27017")`

then on the removed member do: 
```
use admin
db.shutdownServer()
```


## other idea about install—DID NOT WORK!

To install the same version (thank you \ref{url:https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-20-04}):

```
curl -fsSL https://www.mongodb.org/static/pgp/server-3.2.asc | sudo apt-key add -

echo "deb [trusted=yes, arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

apt update
```

NB: have to use `xenial` (16.04) for mongodb v 3.2

This gives an error: `Updating from such a repository can't be done securely, and is therefore disabled by default.`.  

```
apt install mongodb-org
```

## backup

do `crontab -e` and add this line:

```
10 09 * * * /bin/bash /root/backup_mongodb.sh
11 07 * * * /bin/bash /root/backup_mongodb_yyrama.sh
```

where `backup_mongodb.sh` is:

```
#! /bin/bash

MONGO_DATABASE="love-logic"
APP_NAME="logic-test"

MONGO_HOST="127.0.0.1"
MONGO_PORT="27017"
TIMESTAMP=`date +%F-%H%M`
MONGODUMP_PATH="/usr/bin/mongodump"
BACKUPS_DIR="/root/backups/$APP_NAME"
BACKUP_NAME="$APP_NAME-$TIMESTAMP"

# mongo admin --eval "printjson(db.fsyncLock())"
# $MONGODUMP_PATH -h $MONGO_HOST:$MONGO_PORT -d $MONGO_DATABASE
$MONGODUMP_PATH -d $MONGO_DATABASE
# mongo admin --eval "printjson(db.fsyncUnlock())"

mkdir -p $BACKUPS_DIR
mv dump $BACKUP_NAME
tar -zcvf $BACKUPS_DIR/$BACKUP_NAME.tgz $BACKUP_NAME
rm -rf $BACKUP_NAME
```

you should also use the `halve_backups.py` script now and again.


# node

The app uses meteor v1.2. I’m not sure which node versions are compatible but `0.10.40` is installed on logic-a-uk5


# mup

not sure which configuration I used in the end!

the `logic-vu-uk1` and `logic-vu-uk3` servers have docker running

guess: I probably used this \ref{url:https://github.com/zodern/meteor-up}


# meteor cluster

I use \ref{url:https://github.com/meteorhacks/cluster}

According to the instructions:

> ‘Now start as many servers as you like and DDP traffic will be sent to each of the instances randomly. You can also remove instances anytime without affecting the cluster or your app.’
