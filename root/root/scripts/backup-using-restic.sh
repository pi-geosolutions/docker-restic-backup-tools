#!/bin/bash
# Author jean.pommier@pi-geosolutions.fr
#
# Runs a restic backup on all folders mounted under $MNT_PATH (defaults to/mnt)
# restic needs to be pre-configured. You can use environment variables for this, see restic documentation:
# Best way is to define all this in .restirc file, which will be sourced in this script.
# You can use an entrypoint script to generate the .resticrc file. By default, one is created
# by /docker-entrypoint.d/040-configure-restic
#
# https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html or create an alias. This image does
# both for SFTP backend configuration
#
# Parameters:
#   -p               specifies the folder to scan for backup (defaults to /mnt)
#   -n | --noinit    tell the the script to stop if the repo is not initialized. (Useful for avoiding concurrent inits, which might break the repo)
#   -c | --clean     tell the the script to clean old backups


MNT_PATH="/mnt"
NOINIT="false"
CLEAN="false"

# We use "$@" instead of $* to preserve argument-boundary information
ARGS=$(getopt -o p:n --long 'path:,noinit' -- "$@") || exit
eval "set -- $ARGS"

while true; do
    case $1 in
      (-p|--path)
            MNT_PATH=$2; shift 2;;
      (-n|--noinit)
            NOINIT="true"; shift;;
      (-c|--clean)
            CLEAN="true"; shift;;
      (--)  shift; break;;
      (*)   exit 1;;           # error
    esac
done

remaining=("$@")

#set -e
shopt -s expand_aliases
source /root/.resticrc

# init repo if necessary
# test if repo is initialized : following command should return exit code 0
# see https://restic.readthedocs.io/en/stable/075_scripting.html
restic snapshots -q --last
# If exit code != 0, we need to initialize the repo
if [ $? -ne 0 ]; then
  if [ "$NOINIT" == "true" ]; then
    echo "Restic repo no initialized yet. Aborting the operation."
    exit 1;
  fi
  echo "Initializing the backup repo for restic"
  restic init
  if [ $? -eq 0 ]; then
    echo "Initialized"
  else
    echo "Failed initialization"
    exit 1;
  fi
fi
echo "`date +%F-%T` Starting backups"
# iterate through all folders in /mnt and run a backup on each of them
for f in $(ls -d ${MNT_PATH}/*); do
  echo "`date +%F-%T` Starting backup for folder $f"
  restic_backup backup $f
  echo "`date +%F-%T` Folder $f backed up"
done

if [ "$CLEAN" == "true" ]; then
  # clean old snapshots
  /root/scripts/house-keeping.sh
fi
