#!/bin/sh -x 

bundledir="${WORKSPACE}/web-ui/dist/static"
dest="${WORKSPACE}/haskell-server/static"
cp ${bundledir}/* $dest
