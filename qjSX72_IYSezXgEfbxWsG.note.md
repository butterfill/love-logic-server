---
title: "backing up servers (before killing them)"
created: 2023-01-29
tags:
  - programming
projects:
  - lp83px3XHTSxSfSwbOYkn
  - jYyH0O7cyyLOeFBCkorQT
---



Backup files are all in `lucinova:/misc/vps-bacups`

Both of the following methods seemed to cause eleven to hang,
the second hangs on extracting the files: solution—do them on lucinova directly.

Best method seems to be the zipping.


## method 1

```
rclone copy logic-a-uk:/ . 
```


## method 2

Thank you \ref{url:https://askubuntu.com/questions/7809/how-to-back-up-my-entire-system}

```bash
sudo tar czf /logic-a-uk6.tar.gz \
    --exclude=/logic-a-uk6.tar.gz \
    --exclude=/dev \
    --exclude=/mnt \
    --exclude=/proc \
    --exclude=/sys \
    --exclude=/tmp \
    --exclude=/media \
    --exclude=/lost+found \
    /
```
