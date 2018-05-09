#!/bin/sh -x

MASKED_WORDS=moby-english-masked-words.txt

if [ ! -f ${MASKED_WORDS}.zip ]; then
  echo "${MASKED_WORDS}.zip file missing - aborting"
  exit 1
fi

UP_TO_DATE=`find . -newer ${MASKED_WORDS}.zip | grep ${MASKED_WORDS}`

if [ -z "${UP_TO_DATE}" ]; then
  echo "unzipping masked words file"
  rm -f ${MASKED_WORDS}
  unzip ${MASKED_WORDS}.zip
  touch ${MASKED_WORDS}
fi

