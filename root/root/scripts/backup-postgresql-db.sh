#!/bin/bash
# Author jean.pommier@pi-geosolutions.fr
# Runs a restic backup on a postgresql db
# need you to set the following ENV vars in the container:
# POSTGRES_HOST
# POSTGRES_PORT
# POSTGRES_USER : Postgresql privileged user
# POSTGRES_PASSWORD or ideally POSTGRES_PASSWORD_FILE in a secret
#
# Backed up files can be restored running
# 1) change the domain name if necessary, in the backup :
# ```
# cat /tmp/var/lib/postgresql/data/backups/all.sql  |grep go.sk.pigeosolutions.fr
# sed -i "s|go.sk.pigeosolutions.fr|geoporegion.pigeosolutions.fr|g" /tmp/var/lib/postgresql/data/backups/all.sql
# ```
# 2) comment the lines deleting/creating the role georchestra, as we need it to run the script:
# ```
# sed -i "s|DROP ROLE georchestra|---DROP ROLE georchestra|g" /tmp/var/lib/postgresql/data/backups/all.sql
# sed -i "s|CREATE ROLE georchestra|---CREATE ROLE georchestra|g" /tmp/var/lib/postgresql/data/backups/all.sql
# sed -i "s|ALTER ROLE georchestra|---ALTER ROLE georchestra|g" /tmp/var/lib/postgresql/data/backups/all.sql
# ```
# 3) run from this container
# ```
# psql -h database.georchestra -U georchestra -f restore/all.sql template1
# ```
set -e

export PGHOST=$POSTGRES_HOST
export PGUSER=$POSTGRES_USER
export PGPORT=$POSTGRES_PORT

# get password from FILE if possible
source /root/scripts/utils.sh
file_env 'POSTGRES_PASSWORD'
#PGPASSWORD=$POSTGRES_PASSWORD
export PGPASSWORD=$POSTGRES_PASSWORD

if [ -z PGPASSWORD ]; then
  echo "Environment variables not set, this script won't work. You probably need to export the env vars from within your .bashrc file to get them"
  exit 1
fi

echo "`date +%F-%T` Backing up the postgresql DB  on ${PGHOST}:${PGPORT}"
# echo "${PGUSER} / ${PGPASSWORD}"
mkdir -p /dbs/postgresql_${PGHOST}_${PGPORT}/
pg_dumpall --clean | gzip -9 > /dbs/postgresql_${PGHOST}_${PGPORT}/pg_dump_all.sql.gz
if [ $? -ne 0 ]; then
  echo "Failure running mysqldump"
  exit 1;
fi
# pg_dumpall --clean
echo "`date +%F-%T` Postgresql dump successful"
# list files
ls -dn1 $PWD/*

if [[ "$DUMP_ONLY" =~ ^(yes|true|y|1)$ ]]; then
  echo "Stopping there (DUMP_ONLY set to yes)"
else
  echo "Pushing the backup with restic:"
  /root/scripts/backup-using-restic.sh -p /dbs --noinit
fi
