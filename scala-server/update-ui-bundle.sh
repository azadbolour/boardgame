#!/bin/sh -x 

bundledir="${WORKSPACE}/web-ui/dist/static"
dest="${WORKSPACE}/scala-server/public/javascripts"
mkdir -p ${dest}
cp ${bundledir}/* $dest
