#!/bin.sh

#
# Do sanity checks and general post-merge/pre-build processing required 
# for the source tree.
#

if [ -z "${WORKSPACE}" ]; then
  echo "WORKSPACE not set - aborting - make sure environment is intilaized and try again"
  exit 1
fi

#
# Unzip the masked words file if necessary.
#
(cd ${WORKSPACE}/dict && ./unzip-masked-words.sh)

