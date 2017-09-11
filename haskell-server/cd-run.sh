#!/bin/sh

haskellDevDir=$1
confPath=$2

if [ -z "$haskellDevDir" ]; then
  echo "usage: $0 haskellDevDir confPath"
fi

cd $haskellDevDir

exec "./run.sh" "$confPath" 
