#!/bin/sh

package=boardgame       # name of package as defined in .cabal file
# see .cabal file for defined test suites.

stack test ${package}:spec
stack test ${package}:spec1
