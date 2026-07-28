---
title: 'Love Logic / Zoxiy Rescue Guide'
created: '2026-07-28'
tags:
  - ''
projects:
  - lp83px3XHTSxSfSwbOYkn
---

Source: https://chatgpt.com/c/6a68604f-715c-83eb-b095-db35b36a9b81

A concise recovery guide for the old Meteor application, its Docker containers, the Tinc VPN, and the MongoDB 3.2 replica set.

> This is a rescue guide, not a deployment guide. Prefer restoring the existing services and configuration over rebuilding or reconfiguring them.

## Contents

* [Quick guide](#quick-guide)
* [System overview](#system-overview)
* [Application checks](#application-checks)
* [Tinc network checks](#tinc-network-checks)
* [MongoDB checks and recovery](#mongodb-checks-and-recovery)
* [Full recovery sequence](#full-recovery-sequence)
* [After recovery](#after-recovery)
* [Commands to avoid during rescue](#commands-to-avoid-during-rescue)

---

## Quick guide

| Problem                                    | First checks                                                                | Likely action                                                                                      |
| ------------------------------------------ | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Website is down                            | `docker ps -a`; `docker logs --tail 100 love-logic`                         | If the container is stopped, start it. If it says `No primary found in set`, repair MongoDB first. |
| Container repeatedly restarts              | `docker inspect love-logic --format 'exit={{.State.ExitCode}}'`; check logs | Exit code `8` with `No primary found in set` means MongoDB has no primary.                         |
| MongoDB has no primary                     | `rs.status()` on any running MongoDB node                                   | Restore Tinc, then start enough `mongod` services to provide at least 3 of 5 votes.                |
| A MongoDB member says `Connection refused` | Ping its `10.0.0.x` address, then check port 27017                          | If ping works but 27017 is closed, start `mongod` on that server.                                  |
| A private IP is unreachable                | Check `tinc@zoxiy1`, `tun1`, routes, and ping                               | Restart or repair Tinc before touching MongoDB.                                                    |
| Services failed after a reboot             | `systemctl status tinc@zoxiy1`; `systemctl status mongod`                   | Tinc should start first; then start MongoDB; the app should recover afterwards.                    |

### Fast health check

Run on an application server:

```bash
docker ps -a
docker logs --tail 100 love-logic
```

Run on a MongoDB server:

```bash
systemctl status tinc@zoxiy1 --no-pager -l
systemctl status mongod --no-pager -l
mongo --quiet --eval 'rs.status()'
```

---

## System overview

### Application

* Application name: `love-logic`
* Public application name: Zoxiy / Love Logic
* Meteor version: `1.2.1`
* Node generation: approximately Node `0.10`
* Runtime: Docker
* Docker image: `meteorhacks/meteord:base`
* Container name: `love-logic`
* Host port: `3000`
* Container port: `80`
* Application directory: `/opt/love-logic`
* Current bundle: `/opt/love-logic/current`
* Environment file: `/opt/love-logic/config/env.list`
* Generated start script: `/opt/love-logic/config/start.sh`

The container is normally created with Docker's `--restart=always` policy.

### Application servers

| Host           |     Tinc IP | Role               |
| -------------- | ----------: | ------------------ |
| `logic-vu-uk1` | `10.0.0.31` | Meteor application |
| `logic-vu-uk3` | `10.0.0.33` | Meteor application |

### MongoDB replica set

* Replica-set name: `aDb`
* MongoDB version: `3.2.x`
* Voting members: 5
* Votes required for a primary: 3

| Host           |     Tinc IP | Role                                 |
| -------------- | ----------: | ------------------------------------ |
| `logic-vu-de1` | `10.0.0.21` | MongoDB                              |
| `logic-vu-uk2` | `10.0.0.32` | MongoDB                              |
| `logic-vu-uk4` | `10.0.0.34` | MongoDB; old yyrama/PM2 installation |
| `logic-vu-uk5` | `10.0.0.35` | MongoDB and backups                  |
| `logic-vu-uk6` | `10.0.0.36` | MongoDB and key Tinc node            |

The old `.1`, `.2`, and `.3` private addresses are historical and are not members of the current replica-set configuration.

### Tinc VPN

* Network name: `zoxiy1`
* Interface: usually `tun1`
* Private subnet: `10.0.0.0/24`
* Main systemd unit: `tinc@zoxiy1.service`
* uk6 is especially important to the old Tinc arrangement.

---

## Application checks

### Inspect the container

```bash
docker ps -a
```

Useful states:

* `Up ...`: the container is running.
* `Exited (...)`: the application stopped.
* `Restarting (...)`: Docker is repeatedly restarting a failing application.

### Read the application logs

```bash
docker logs --tail 200 --timestamps love-logic
```

The most important known failure is:

```text
Error: No primary found in set
```

That is a MongoDB replica-set problem, not a Node or Docker startup problem.

### Inspect the exit state

```bash
docker inspect love-logic \
  --format 'exit={{.State.ExitCode}} error={{.State.Error}} oom={{.State.OOMKilled}}'
```

### Start an existing stopped container

```bash
docker start love-logic
```

### Recreate the container from the existing deployed bundle

Use this only when the existing container needs to be recreated:

```bash
cd /opt/love-logic/config
bash start.sh
```

`start.sh` removes the existing container before recreating it. Do not use it merely to inspect a failing service.

### Temporarily stop a restart loop

```bash
docker update --restart=no love-logic
docker stop love-logic
```

Restore the normal policy afterwards:

```bash
docker update --restart=always love-logic
docker start love-logic
```

---

## Tinc network checks

### Check the service

```bash
systemctl status tinc@zoxiy1 --no-pager -l
ps -ef | grep '[t]incd'
```

A healthy node should show a running process similar to:

```text
/usr/sbin/tincd -n zoxiy1 -D
```

### Check the interface and route

```bash
ip -br address 2>/dev/null || ip -4 address
ip route
```

Each host should have its expected `10.0.0.x` address on `tun1`, plus a route for:

```text
10.0.0.0/24 dev tun1
```

### Ping all current hosts

```bash
for h in \
  10.0.0.21 \
  10.0.0.31 \
  10.0.0.32 \
  10.0.0.33 \
  10.0.0.34 \
  10.0.0.35 \
  10.0.0.36
do
  printf '%-12s ' "$h"
  if ping -c 1 -W 2 "$h" >/dev/null 2>&1; then
    echo 'PING OK'
  else
    echo 'PING FAILED'
  fi
done
```

### Inspect Tinc configuration

```bash
grep -H -E '^[[:space:]]*(Name|ConnectTo|Interface|Device|Mode)[[:space:]]*=' \
  /etc/tinc/*/tinc.conf 2>/dev/null
```

### View recent Tinc logs

```bash
journalctl -b -u tinc@zoxiy1 --no-pager -n 150
```

Occasional unsolicited `Bogus data received from <unknown>` messages are internet noise. Focus on persistent connection failures involving named Tinc peers.

### Restart Tinc

```bash
systemctl restart tinc@zoxiy1
```

After restarting, confirm that the correct private address and route have returned before restarting MongoDB.

---

## MongoDB checks and recovery

### Check whether MongoDB is running

```bash
ps -ef | grep '[m]ongod'
systemctl status mongod --no-pager -l
ss -lntp 2>/dev/null | grep ':27017' || \
netstat -lntp 2>/dev/null | grep ':27017'
```

If Tinc ping works but port 27017 reports `Connection refused`, the network is probably fine and `mongod` is not running.

### Start MongoDB

```bash
systemctl start mongod
```

Then verify:

```bash
systemctl status mongod --no-pager -l
ss -lntp | grep ':27017'
```

### Read MongoDB logs

```bash
journalctl -u mongod --since '-10 minutes' --no-pager

tail -n 150 /var/log/mongodb/mongod.log 2>/dev/null || \
tail -n 150 /var/log/mongodb/mongo.log
```

### Check replica-set status

```bash
mongo --quiet --eval '
s=rs.status();
print("set=" + s.set);
s.members.forEach(function(m) {
  print(
    m.name,
    m.stateStr,
    "health=" + m.health,
    "optime=" + m.optimeDate,
    m.infoMessage || ""
  );
});
'
```

Expected healthy states:

* exactly one `PRIMARY`;
* the other healthy members normally `SECONDARY`;
* a newly returning member may briefly show `STARTUP2` or `RECOVERING`.

### Test MongoDB ports from another host

```bash
for h in 10.0.0.21 10.0.0.32 10.0.0.34 10.0.0.35 10.0.0.36; do
  printf '%-12s ' "$h"
  timeout 3 bash -c "</dev/tcp/$h/27017" 2>/dev/null \
    && echo OPEN \
    || echo CLOSED
done
```

Interpretation:

* Ping fails: investigate Tinc first.
* Ping succeeds, port closed: start or repair `mongod` on that server.
* Port open, member unhealthy: inspect MongoDB logs and `rs.status()`.

### Restore a primary safely

The set has five voting members, so restore at least three communicating members. A typical recovery order is:

1. Keep the known running member, usually `10.0.0.32`.
2. Start `mongod` on uk6, `10.0.0.36`.
3. Start `mongod` on one more member, preferably `10.0.0.21`.
4. Watch `rs.status()` until a normal election produces a `PRIMARY`.

Do not force a reconfiguration merely because services failed to start after a reboot.

### If MongoDB will not start

Check:

```bash
grep -nEi 'bind|port|repl|dbpath|logpath|storage|systemLog|net:' \
  /etc/mongod.conf

df -h
df -i
ls -ld /var/lib/mongodb
```

Common causes:

* Tinc address did not exist when MongoDB tried to bind.
* Disk or inode exhaustion.
* Incorrect data-directory or log-directory permissions.
* Port 27017 already in use.
* Storage-engine or data corruption errors.

If logs suggest corruption, preserve the logs and data directory before attempting repair.

---

## Full recovery sequence

Use this order after a reboot or outage.

### 1. Stop application restart noise if necessary

```bash
docker update --restart=no love-logic
docker stop love-logic
```

### 2. Confirm Tinc on uk6

```bash
systemctl status tinc@zoxiy1 --no-pager -l
ip -br address
ip route
```

Confirm `10.0.0.36/24` exists on `tun1`.

### 3. Confirm private connectivity

Run the all-host ping loop from uk6 and at least one application server.

### 4. Start MongoDB on enough members

On each selected database server:

```bash
systemctl start mongod
systemctl status mongod --no-pager -l
```

Bring back at least three voting members.

### 5. Wait for a normal election

On any running MongoDB member:

```bash
mongo --quiet --eval 'rs.status()'
```

Continue only after one member reports `PRIMARY`.

### 6. Restore the application container

```bash
docker update --restart=always love-logic
docker start love-logic
docker logs --tail 100 -f love-logic
```

### 7. Verify the local application port

```bash
curl -I http://127.0.0.1:3000
```

Repeat the application checks on both application servers.

---

## After recovery

### Enable MongoDB at boot

After confirming a MongoDB member starts correctly:

```bash
systemctl enable mongod
```

Apply this to each current MongoDB server.

### Make MongoDB wait for Tinc

On each MongoDB server:

```bash
systemctl edit mongod
```

Add:

```ini
[Unit]
Requires=tinc@zoxiy1.service
After=network-online.target tinc@zoxiy1.service
```

Then:

```bash
systemctl daemon-reload
systemctl enable mongod
```

Apply the override without unnecessarily restarting a healthy primary. Test it during planned maintenance.

### uk4 caution

`logic-vu-uk4` has an old yyrama/PM2 installation which previously behaved badly after reboot. Before using uk4 during a rescue, check for excessive PM2 or Node processes:

```bash
ps -ef | grep -E '[p]m2|[n]ode'
top -b -n 1 | head -n 30
```

Do not start yyrama merely to recover the MongoDB replica set.

---

## Commands to avoid during rescue

Do not use these unless you have deliberately decided to alter the replica-set topology or perform data recovery:

```text
rs.initiate()
rs.reconfig(..., {force:true})
rs.add(...)
rs.remove(...)
mongod --repair
```

Also avoid deleting MongoDB lock files or copying a live MongoDB data directory between servers without a proper backup-and-restore procedure.

The normal rescue strategy is:

1. Restore Tinc.
2. Start the existing `mongod` services.
3. Regain three votes.
4. Allow a normal primary election.
5. Restart the Meteor containers.
