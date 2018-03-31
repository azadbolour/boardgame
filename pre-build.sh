#!/bin/sh -x

MAIN_DICT=${WORKSPACE}/dict
MASKED_WORDS_SOURCE=moby-english-masked-words.txt

cd $MAIN_DICT
if [ ! -e ${MASKED_WORDS_SOURCE} ]; then 
  echo "unzipping masked words file"
  unzip ${MASKED_WORDS_SOURCE}.zip
fi


