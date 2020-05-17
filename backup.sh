#!/bin/bash

BACKUP_FOLDER=/mnt/backups

EMAIL_FILE_LOGIN=/root/login.txt

EMAIL_FILE_PASSWORD=/root/password.txt

## PATTERN FOR FILES WHICH ARE SHOULD BE KEEPED FOREVER ON DEVICE
PATTERN=untouchable_

FOLDER_TO_BACKUP=/opt/web-app

PATH_TO_MAIL_SENDER_SCRIPT=/usr/share/mail_sender.sh

## MAX FOLDER SIZE (IN PERCENTS)
MAX_SIZE="90"

# GETTING MAIL CREDENTIALS AND CONVERTING THEM INTO BASE64 FOR OPENSSL
LOGIN=$(cat ${EMAIL_FILE_LOGIN} | openssl aes-256-ecb -a -salt -d -k ${SALT_KEY} | base64)
PASS=$(cat ${EMAIL_FILE_PASSWORD} | openssl aes-256-ecb -a -salt -d -k ${SALT_KEY} | base64)

FROM=$(cat ${EMAIL_FILE_LOGIN} | openssl aes-256-ecb -a -salt -d -k ${SALT_KEY})

while getopts o:e:z:p:l:d:k: option; do
    case "${option}" in
    o) operation=${OPTARG} ;;
    e) EMAIL_RECIVER=${OPTARG} ;;
    z) ZIP_PASSWORD=${OPTARG} ;;
    p) DB_PASS=${OPTARG} ;;
    l) DB_LOGIN=${OPTARG} ;;
    d) DATABASE=${OPTARG} ;;
    k) SALT_KEY=${OPTARG} ;;
    esac
done
function_backuping () {

    #BACKUPING SOME FILES INTO ZIP
    7z a -p${ZIP_PASSWORD} ${BACKUP_FOLDER}/$1/$2$(date '+%d_%m_%Y').zip $FOLDER_TO_BACKUP

    #MYSQL BACKUP
    mysqldump -u ${DB_LOGIN} -p${DB_PASS} --databases ${DATABASE} | 7z a -p${ZIP_PASSWORD} ${BACKUP_FOLDER}/$1/$2SQL_$(date '+%d_%m_%Y').zip

    ##DEFINING VARS FOR MAIL

    SUCCESS_BODY="$1 backups were successfully stored in ${BACKUP_FOLDER}/$1 date:$(date)"
    SUCCESS_SUBJECT="$1 BACKUP PROCESS SUCCESS ON $(hostname)"
    function_email_sender $LOGIN $PASS $FROM $EMAIL_RECIVER $SUCCESS_SUBJECT $SUCCES_BODY
}
function_email_sender () {
    ## user pass from reciever subject body 
    .${PATH_TO_MAIL_SENDER_SCRIPT} $1 $2 $3 $4 $5 $6
}

## DELETING OLD BACKUPS
find ${BACKUP_FOLDER}/daily -mtime +14 -type f ! -iname "*${PATTERN}*" -exec rm -rf {} \;
find ${BACKUP_FOLDER}/weekly -mtime +90  -type f ! -iname "*${PATTERN}*" -exec rm -rf {} \;

if [[$(df -k $BACKUP_FOLDER | awk '{print $5}' | grep -Eo '[0-9]') -ge "${MAX_SIZE}"   ]]
then
    FAILURE_BODY="FOLDER FOR BACKUPS IS ALMOST FULL. USAGE IS HIGHER THAN ${MAX_SIZE}%"
    FAILURE_SUBJECT="${operation} BACKUP PROCESS FAILED ON $(hostname)"
    function_email_sender $LOGIN $PASS $FROM $EMAIL_RECIVER $SUBJECT $SUCCES_BODY
    exit 0
else 
## CHECKING IS IT A LAST DAY IN A CURRENT MONTH
    if [[ $(date -d "-$(date +%d) days +1 month" +%d_%m_%Y) = $(date -d '+%d_%m_%Y') ]]
    then 
        function_backuping $operation $PATTERN
    else  
        function_backuping $operation
    fi
fi


