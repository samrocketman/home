#!/bin/bash
#My personal weekly syncrhonization script for drives twice a week
#cron
#0 3 * * 3,6 /home/sam/bin/toucan.sh
export PATH="/usr/local/sbin:/usr/local/bin"
export PATH="${PATH}:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"

backupfolder="/media/raid/.backup"

sendmail sam.mxracer@gmail.com << EOF
Subject: rsync backup started
A recent backup has been run
EOF
#mv "${backupfolder}/My Files.2.bak.tc" "${backupfolder}/My Files.3.bak.tc"
#mv "${backupfolder}/My Files.1.bak.tc" "${backupfolder}/My Files.2.bak.tc"
#mv "${backupfolder}/My Files.tc" "${backupfolder}/My Files.1.bak.tc"
rsync -av --delete-before --exclude=*.bak.tc /media/backup/ "${backupfolder}"
#rsync -rptvog --delete-before /media/raid/ /media/tripleredundancy
sendmail sam.mxracer@gmail.com << EOF
Subject: Re: rsync backup started
Backup has finished running
EOF
# chown -R sam:users /media/backup
# chown -R sam:users /media/raid
# chown -R sam:users /media/tripleredundancy
# chmod -R 777 /media/backup
# chmod -R 777 /media/raid
# chmod -R 777 /media/tripleredundancy
