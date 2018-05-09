#!/bin/sh

#
# Sanity check the environment and the source tree.
#
. ../prepare.sh

#
# Reduce the  .cabal file to include just the library.
#
save=boardgame.cabal.save
endLibraryLine=`grep -n 'START' boardgame.cabal | cut -d : -f 1`
mv boardgame.cabal $save
head "-${endLibraryLine}" $save > boardgame.cabal
stack build
mv $save boardgame.cabal
