#!/bin/sh

testregex=$1

if [ -z "$testregex" ]; then 
  testregex="[a-z]*"
fi

npm test -t src/__tests__/$testregex

