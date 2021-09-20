#!/bin/bash
# Author jean.pommier@pi-geosolutions.fr
# Runs a restic backup on the georchestra LDAP db
# need you to set the following ENV vars in the container:
# LDAP_HOST
# LDAP_PORT
# LDAP_ADMIN : LDAP admin user
# LDAP_PASSWORD or ideally LDAP_PASSWORD_FILE in a secret
#
# Backed up files can be restored running
# `ldapdelete -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} "ou=orgs,dc=georchestra,dc=org"`
# `ldapdelete -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD}"ou=roles,dc=georchestra,dc=org"`
# `ldapdelete -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} "ou=users,dc=georchestra,dc=org"`
#
# `ldapadd -H ldap://LDAP${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -f users.ldif`
# `ldapadd -H ldap://LDAP${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -f roles.ldif`
# `ldapadd -H ldap://LDAP${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -f orgs.ldif`
#

# get password from FILE if possible
source /root/scripts/utils.sh
file_env 'LDAP_PASSWORD'

echo "`date +%F-%T` Backing up the ${LDAP_HOST}:${LDAP_PORT} LDAP"
#echo "${LDAP_ADMIN} / ${LDAP_PASSWORD}"
mkdir -p /dbs/ldap_${LDAP_HOST}_${LDAP_PORT}/
ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -b "ou=orgs,dc=georchestra,dc=org" > /dbs/ldap_${LDAP_HOST}_${LDAP_PORT}/orgs.ldif
if [ $? -ne 0 ]; then
  echo "Failure running ldapsearch"
  exit 1;
fi
ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -b "ou=roles,dc=georchestra,dc=org" > /dbs/ldap_${LDAP_HOST}_${LDAP_PORT}/roles.ldif
if [ $? -ne 0 ]; then
  echo "Failure running ldapsearch"
  exit 1;
fi
ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -b "ou=users,dc=georchestra,dc=org" > /dbs/ldap_${LDAP_HOST}_${LDAP_PORT}/users.ldif
if [ $? -ne 0 ]; then
  echo "Failure running ldapsearch"
  exit 1;
fi
# ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -b "ou=orgs,dc=georchestra,dc=org"
# ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -b "ou=roles,dc=georchestra,dc=org"
# ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT}/ -x -D "${LDAP_ADMIN}" -w ${LDAP_PASSWORD} -b "ou=users,dc=georchestra,dc=org"
echo "`date +%F-%T` LDAP dump successful"
# list files
ls -dn1 $PWD/*

if [[ "$DUMP_ONLY" =~ ^(yes|true|y|1)$ ]]; then
  echo "Stopping there (DUMP_ONLY set to yes)"
else
  echo "Pushing the backup with restic:"
  /root/scripts/backup-using-restic.sh -p /dbs --noinit
fi
