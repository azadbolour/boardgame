#!/bin/sh

# Generate docs.

# location="`pwd`/.stack-work/dist/x86_64-osx/Cabal-1.22.5.0/doc"

stack haddock # -v for verbose

haddockdest="${WORKSPACE}/haskell-server/.stack-work/install/x86_64-osx/lts-6.25/7.10.3/doc"
hdocs=${WORKSPACE}/haskell-server/docs/hdocs

rm -rf {$hdocs}
cp -a "${haddockdest}/boardgame-0.0.0" ${hdocs}
