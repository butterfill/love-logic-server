---
title: "zoxiy (love-logic) and yyrama server vps configuration at vultr and aruba cloud information and plan"
created: 2023-01-28
tags:
  -
projects:
  - lp83px3XHTSxSfSwbOYkn
  - jYyH0O7cyyLOeFBCkorQT
---

*These notes are just about which server does what.
There are other notes on how to configure them*

# todo

1. [ ] check meteor apps can still find the mongodb database without 10.0.0.1 etc
       * I think this will probably be ok because some of the mup config specifies `10.0.0.21,10.0.0.32` in the mongo url.
       * did reboot one and it seemed ok (system stopped for a bit, but it worked eventually)

1. [ ] check I can deploy zoxiy to a fresh server
   * might follow the yyrama guide rather than getting mup working?
   * actually mup looks alive and well \ref{url:https://meteor-up.com/getting-started.html} and \ref{url:https://github.com/zodern/meteor-up}
   * the meteor guide will also help (\ref{url:https://guide.meteor.com/deployment.html})
     * nb use `meteor node -v` to check node version
     * the latest meteor tool will work with all meteor versions

1. [ ] consider re-doing logic-vu-uk4 which has constant errors with `tinc@zoxiy1.service`
   * may be that I borked the tinc install on this machine
   * cpu is running 100% its’s very slow
   * remember that you have to `pm2 kill` things when it reboots
   * currently configured not to start yyrama on boot (because pm2 forks 100s of processes and server hangs)
   * but it runs yyrama so I probably do not want to simply wipe it

1. [ ] when reboot `logic-vu-uk4`, a fucked up `pm2` tries to run gazillion yyrama instances killing the server

1. [x] get backups working again

1. [x] check I can deploy yyrama to a fresh server
   * deployed to `logic-vu-uk4`

1. [x] remove yyrama servers logic-a-uk4 and logic-a-uk6

1. [x] Make sure you can still access yyrama exercises!
    * have installed yyrama on `logic-vu-uk4`

1. [x] last aruba zoxiy server is `logic-a-uk5`. Can I just remove this?
   * yes, apparently (done)

1. [x] delete all arubacloud VPS


# log

## 2023-01-28

* created logic-vu-uk4 = 78.141.224.145

* backed up to `lucinova:/misc/vps-bacups`
  * logic-a-uk (rclone)
  * logic-a-uk4 (tar+scp)
  * the other aruba backups were done later
  * all backups are in this directory (`lucinova:/misc/vps-bacups`)


## 2023-01-29

* tinc vpn extended to logic-vu-uk4
  * for the method, see \ref{note:Zrh0Bmi184hZ6kjT7VJ2x}
  * added logic-vu-uk4 to the network as 10.0.0.34

* installed yyrama following \ref{note:yyrama_deploy_notes-l7-dBMW75FzAnzYzjBbO3}

* set `yyrama.butterfill.com` DNS `logic-vu-uk4=78.141.224.145` to (was `logic-a-uk4=185.58.225.240`)

* created logic-vu-uk5 = 192.248.166.158
  * installed mongodb 3.2 (see \ref{note:MRw-zw0NGqmpeErI1blGt})
  * added to the replica set

* created logic-vu-uk6 
  * initially with ubuntu 22.10 (not LTS)
  * then re-installed to ubuntu 20.04 LTS
  * this is to check whether this version’s tinc will work with the older versions’!
  * weirdly the whole tinc network just worked after this therefore I will not change this server (see \ref{note:Zrh0Bmi184hZ6kjT7VJ2x})
  * do not reimage this server, it works!

* turned off logic-a-uk5
  * the note on the cluster says it should be fine to add and remove nodes (\ref{url:https://github.com/meteorhacks/cluster})
  * zoxiy still seems fine without it

* turned off `logic-a-uk3` after removing from mongodb replica set

* turned off `logic-a-uk1` after removing from mongodb replica set

* added `logic-vu-uk4` to the mongodb cluster

* remove `logic-a-uk2` from mongodb cluster and swicthed off

* set `logic-vu-uk5` to run the backups

* stopped arubacloud auto top up
  * did not delete because still have some time left
  * should think about keeping one server alive to use up remaining credit? (Cannot but 2.79 euro servers any more)?
  * renewal dates:
    1. 2023-02-17 = logic-a-uk6
    1. 2023-02-24 = logic-a-uk
    1. 2023-02-24 = logic-a-uk2
    1. 2023-02-24 = logic-a-uk3
    1. 2023-02-24 = logic-a-uk4
    1. 2023-02-24 = logic-a-uk5


# all vps


## vultr

| | name        | ip | tinc ip | description | 
|-| -------------|-----------------|---------|-- | 
| | logic-vu-de1 | 45.32.157.98    | 10.0.0.21 | mongodb | 
| | logic-vu-uk1 | 45.32.180.114   | 10.0.0.31 | zoxiy | 
| | logic-vu-uk2 | 45.32.181.24    | 10.0.0.32 | mongodb | 
| | logic-vu-uk3 | 108.61.196.248  | 10.0.0.33 | zoxiy | 
| | logic-vu-uk4 | 78.141.224.145  | 10.0.0.34 | mongodb and yyrama (yyrama  is not being used, just for my reference; start yyrama with `su yyrama;pm2 etc` if rebooting, see  \ref{note:yyrama_deploy_notes-l7-dBMW75FzAnzYzjBbO3}) |
| | logic-vu-uk5 | 192.248.166.158 | 10.0.0.35 | mongodb and backups (yyrama not backed up (not in use), only zoxiy) |
| | logic-vu-uk6 | 45.76.129.106  | 10.0.0.36  | mongodb (also 20.04 LTS lynchpin of tinc network) |

## aruba

* [removed!] logic-a-uk1 — mongodb
* [removed!] logic-a-uk2 — mongodb
* [removed!] logic-a-uk3 — mongodb
* [stopped!] logic-a-uk4 — yyrama
* [stopped!] logic-a-uk5 — zoxiy
* [stopped!] logic-a-uk6 — yyrama-test


# mongodb servers

* 10.0.0.1 — logic-a-uk
* 10.0.0.2 — logic-a-uk2
* 10.0.0.3 — logic-a-uk3
* 10.0.0.21 — logic-vu-de1
* 10.0.0.32 — logic-vu-uk2

# web servers

## zoxiy

* logic-vu-uk1
* logic-vu-uk3 (108.61.196.248)
* logic-a-uk5

## found in `network` tab of browser console (from cluster balancer):
  * logic-ex-vu-uk3.zoxiy.xyz = 108.61.196.248 = logic-vu-uk3 = 10.0.0.33
  * logic-ex-v-uk1.butterfill.com = 45.32.180.114 = logic-vu-uk1 = 10.0.0.31
  * logic-ex-a-uk5.butterfill.com = 185.58.225.8 = logic-a-uk5 = 10.0.0.5


## yyrama

  yyrama.butter...: logic-a-uk4
  yyrama-test.butter: logic-a-uk6



## cloudflare says

### zoxiy.xyz

  * `ex` A record 108.61.196.248 — logic-vu-uk3
  * updated on 2023—01-28: removed 185.58.225.8 — logic-a-uk5
    * before this there were two A records for `ex`, now just one
  * there is also an A record for `zoxiy.xyz` not sure if this is a mistake

### butterfill.com
  * `ex` 108.61.196.248 — logic-vu-uk3
    * updated on 2023-01-28; previously was 185.58.225.8 — logic-a-uk5
  * `yyrama` two A records
    * 185.58.225.240 = logic-a-uk4
    * 185.58.227.224 = logic-a-uk6
  * `test` A record — 185.58.227.224 = logic-a-uk6
  * `logic-ex-vu-uk3` 108.61.196.248 — logic-vu-uk3
  * `zz` twoo A records
    * 45.32.180.114 — logic-vu-uk1
    * 185.58.225.8 — logic-a-uk5



## monitoring

Is done via \ref{url:https://uptimerobot.com} (user is stephen@butterfill.com)