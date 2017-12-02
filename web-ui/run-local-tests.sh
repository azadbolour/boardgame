#!/bin/sh

testregex=$1

if [ -z "$testregex" ]; then 
  testregex="*.test.js"
fi

npm test -t src/__tests__/$testregex
# npm test -t src/__component.tests__/$testregex

