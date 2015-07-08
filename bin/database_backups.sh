#!/bin/bash
#Sam Gleske (github.com/samrocketman)
#Sun Feb 16 13:19:45 EST 2014
#Ubuntu 13.04
#Linux 3.8.0-19-generic x86_64
#GNU bash, version 4.2.45(1)-release (x86_64-pc-linux-gnu)
#DESCRIPTION
#  Back up all MySQL databases individually and account for extremely large
#  size.  Separate each database into a different file.

#exit on first error aborting script
set -e

#User configured env variables
DB_BACKUP_DIR="${DB_BACKUP_DIR:-/srv/backups}"
DBUSER="${DBUSER:-root}"
DBPASS="${DBPASS:-}"
REMOTE="${REMOTE:-localhost}"

if [ ! -d "${DB_BACKUP_DIR}" ];then
  echo '$DB_BACKUP_DIR does not exist!' 1>&2
  echo "DB_BACKUP_DIR = ${DB_BACKUP_DIR}" 1>&2
  exit 1
fi

#get date timestamp for all databases
today="$(date +%Y-%m-%d-%s)"

#grab a list of database names
if [ -z "${DBPASS}" ];then
  databases="$(mysql -h ${REMOTE} -u ${DBUSER} -Bse 'show databases' | grep -v performance_schema)"
else
  databases="$(mysql -h ${REMOTE} -u ${DBUSER} -p${DBPASS} -Bse 'show databases' | grep -v performance_schema)"
fi

STATUS=0
#export and compress databases
for db in ${databases};do
  if [ -z "${DBPASS}" ];then
    mysqldump -h ${REMOTE} -u ${DBUSER} --single-transaction --skip-extended-insert --create-options --databases ${db} | gzip -9 > "${DB_BACKUP_DIR}/${db}_${today}.mysql.gz"
  else
    mysqldump -h ${REMOTE} -u ${DBUSER} -p${DBPASS} --single-transaction --skip-extended-insert --create-options --databases ${db} | gzip -9 > "${DB_BACKUP_DIR}/${db}_${today}.mysql.gz"
  fi
  if [ ! "$?" = "0" ];then
    echo "Problem backing up ${db} ${today}." 1>&2
    STATUS=1
  fi
done

#remove old copies only if there's more than 7 days worth
for db in ${databases};do
  if [ "$(ls -1 "${DB_BACKUP_DIR}/${db}_"[0-9]* | wc -l)" -gt "7" ];then
    find "${DB_BACKUP_DIR}" -type f -name "${db}_[0-9]*.mysql.gz" -mtime +7 -exec rm -f {} \;
  fi
done

exit "${STATUS}"
