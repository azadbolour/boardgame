#!/bin/sh

#
# Compute masked words list - for each word replace up to maxBlanks of its letters
# by blanks. The higher the maxBlanks value the more unplayable squares can
# be detected by the main program. 3 is a reasonable compromise between 
# speed of preprocessing and unplayable square detection in the development
# process. 4 would be better for a production deployment.
#

wordsFile=$1
maskedWordsFile=$2
maxBlanks=$3

stack exec masked-words-preprocessor ${wordsFile} ${maskedWordsFile} ${maxBlanks}
zip ${maskedWordsFile}.zip ${maskedWordsFile} 

