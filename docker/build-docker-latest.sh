#!/bin/sh

# TODO. Parameterize the build by git sha so that different invokations will not 
# use cache when they get to pulling the latest.

docker build --force-rm=true -t azadbolour/boardgame-latest latest
