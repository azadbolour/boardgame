#!/bin/sh

#
# Compute masked words list - for each word replace up to maxBlanks of its letters
# by blanks. The higher the maxBlanks value the more unplayable squares can
# be detected by the main program. 3 is a reasonable compromise between 
# speed of preprocessing and unplayable square detection in the development
# process. 4 would be better for a production deployment.
#
# Ideally maximum blanks should be a deployment time configuration parameter.
# But computing masked words is a very time consuming and slows down development
# turnaround. Therefore we compute the default (max = 3) masked words whenever
# the dictionary changes and check in its zipped version. It is too big by
# itself for github.
#

wordsFile=$1
maskedWordsFile=$2
maxBlanks=$3

tmpDir=/tmp/$USER/boardgame
mkdir -p $tmpDir
tmpFile=$tmpDir/maskedWords

stack exec masked-words-preprocessor ${wordsFile} ${tmpFile} ${maxBlanks}
sort $tmpFile | uniq > $maskedWordsFile
zip ${maskedWordsFile}.zip ${maskedWordsFile} 

