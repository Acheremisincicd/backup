# Configuring NFS 
- Firstly

Create a disk partition to make backup folder size fixed.
In my case that was. 
```
parted /dev/sdb
mkpart primary ext4 0 8MB
mkfs.ext4 /dev/sdb1
mkdir -p /mnt/backups
mount -t auto /dev/sdb1 /mnt/backups
```
string in fstab 
```
UUID=bf84443b-2246-4cf1-b0f1-51ec162d9c02 /mnt/backups auto    rw,user,auto    0    0
```
- NFS

remove restrictive permissions of the backups folder
```
chown nobody:nogroup /mnt/backups
```
string in /etc/exports
```
/mnt/backups clientIP(rw,sync,no_subtree_check)
```
Then run ```exportfs -a``` and restart the nfs-server.service

# records in cron 
- daily 

```0 1 * * * root backup.sh -o "daily" -e "some mail to recieve msg" -z "pass for backups -p "database password" -l "data base login" -d "data base name" "Salt key for decrypting mail credentials stored in file"```

- weekly 

``` 0 2 * * 6 root test $((10#$(date +\%W)\%2)) -eq 1 && backup.sh -o "weekly" -e "some mail to recieve msg" -z "pass for backups -p "database password" -l "data base login" -d "data base name" "Salt key for decrypting mail credentials stored in file"```

There isn't some simple solution to run a cron every two weeks. Expresion determinates that current week ODD or even and returns 1 or 0 respectively. Current week is 19-th so cron job will do.

# Script workflow
- VARS

```
BACKUP_FOLDER - folder which is used by NFS 
EMAIL_FILE_LOGIN - file with login for mail in aes-256 (Be sure that the salt key used for encryprtion is the same in cron expression"
EMAIL_FILE_PASSWORD - file with password for mail in aes-256 (Be sure that the salt key used for encryprtion is the same in cron expression"
FOLDER_TO_BACKUP - some folder with files needed to be beckuped
PATTERN - PATTERN FOR FILES WHICH ARE SHOULD BE KEEPED FOREVER ON DEVICE
MAX_SIZE - MAX FOLDER SIZE (IN PERCENTS)
```
- Clean up 

```find ${BACKUP_FOLDER}/daily -mtime +14 -type f ! -iname "*${PATTERN}*" -exec rm -rf {} \;```

is looking for files older than 2 weeks in daily backups(exclude files with pattern)

```find ${BACKUP_FOLDER}/weekly -mtime +90  -type f ! -iname "*${PATTERN}*" -exec rm -rf {} \;```

is looking for files older than 3 months in weekly backups(exclude files with pattern)

- STATEMENTS

First ```IF``` checks $BACKUP_FOLDER size and if it is more than you specified in $MAX_SIZE var script will fail and call email_sender function to send a message about error.
IF $BACKUP_FOLDER size is OK - script checks current day and compare it with last day in month. if it is - some $PATTERN will be added to backups. if it isn't backups will be stored with default names.

In purpose to store data script calls backuping fucntion and send vars: $opertaion=(daily/weekly) and $PATTERN(optional).

And function based on these vars can determine where the data should be stored in $BACKUP_FOLDER/daily or $BACKUP_FOLDER/weekly.

# Results
- Sample paths of weekly/daily backups
```
/mnt/backups/weekly/16_05_2020.zip
/mnt/backups/weekly/SQL_16_05_2020.zip
```
- Sample path of files which have to be untouchable
```
/mnt/backups/weekly/untouchable_31_05_2020.zip
```






