#!/bin/sh -x 

# Copy UI resources from the web-ui distribution directory
# to the haskell server's static directory to make them available as Servant assets.

source="${WORKSPACE}/web-ui/dist"
dest="${WORKSPACE}/haskell-server/static"

mkdir -p ${dest}

# Remove previous versions of the bundle.
rm ${dest}/*

# Copy the latest bundle.
cp ${source}/static/* ${dest}/

# Copy index.html.
cp ${source}/index.html ${dest}/
