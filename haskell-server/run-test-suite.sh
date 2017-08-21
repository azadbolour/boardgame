#!/bin/sh

package=boardgame       # name of package as defined in .cabal file
# see .cabal file for defined test suites. 
# One is 'infocus' for tests currently being worked on.

suite=$1
if [ -z "$suite" ]; then
  suite=spec
fi
stack test ${package}:${suite}
