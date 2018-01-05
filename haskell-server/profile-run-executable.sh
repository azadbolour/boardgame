#!/bin/sh

# See  https://wiki.haskell.org/Debugging.
# ghc Crash.hs -prof -fprof-auto -fprof-cafs && ./Crash +RTS -xc
# But stack only has --profile.

executable=$1
stack exec -- ${executable} +RTS -p -xc

