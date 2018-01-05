#!/bin/sh

# For stack traces, see  https://wiki.haskell.org/Debugging.
# ghc Crash.hs -prof -fprof-auto -fprof-cafs && ./Crash +RTS -xc
# But stack only has --profile.

# stack clean
stack build --profile 
# stack build --profile 2>&1 >/dev/null | head -30

