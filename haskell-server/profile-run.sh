#!/bin/sh

# See  https://wiki.haskell.org/Debugging.
# ghc Crash.hs -prof -fprof-auto -fprof-cafs && ./Crash +RTS -xc
# But stack only has --profile.

export GAME_SERVER_PORT=6587
# stack exec -- boardgame-server +RTS -p
stack exec -- boardgame-server +RTS -p -xc

