#!/bin/sh -x 

# Copy UI resources from the web-ui distribution directory
# to scala-server public directory to make them available as Play assets.

source="${WORKSPACE}/web-ui/dist"
dest="${WORKSPACE}/scala-server/public"

mkdir -p ${dest}/static/

# Copy the bundle.
cp ${source}/static/* ${dest}/static/

# Copy index.html.
cp ${source}/index.html ${dest}
