#!/bin/sh

testregex=$1

if [ -z $testregex ]; then 
  testregex="*"
fi

export API_TYPE="client"
npm test -t src/__integration.tests__/$testregex
