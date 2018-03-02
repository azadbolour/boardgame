#!/bin/sh

wordsFile=$1
outFile=$2
maxBlanks=$3

preprocessor=com.bolour.language.scala.service.MaskedWordsPreprocessor
# wordsFile="../dict/moby-english.txt "

sbt -batch "runMain $preprocessor $wordsFile $outFile $maxBlanks"
