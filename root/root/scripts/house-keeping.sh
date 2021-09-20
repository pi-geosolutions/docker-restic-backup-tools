#!/bin/bash
# Author jean.pommier@pi-geosolutions.fr
# Performs some house-keeping in the backups

#set -e
shopt -s expand_aliases
source /root/.resticrc

# clear old snapshots
KEEP="--keep-daily 7 --keep-weekly 5 --keep-monthly 12"
if [ -z KEEP_POLICY ]; then
    KEEP=$KEEP_POLICY
fi
restic forget --host ${HOST} ${KEEP} --prune
