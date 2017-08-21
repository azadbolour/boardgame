#!/bin/sh

testregex=$1

if [ -z $testregex ]; then 
  testregex="*"
fi

npm test -t src/__component.tests__/$testregex
