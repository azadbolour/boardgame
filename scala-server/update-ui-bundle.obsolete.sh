#!/bin/sh -x 

# IMPORTANT. TODO. This script is no longer needed.
# UI content will be served independently of the backend server.

# Copy UI resources from the web-ui distribution directory
# to scala-server public directory to make them available as Play assets.

if [ -z "${WORKSPACE}" ]; then
  echo "WORKSPACE not set - aborting - set the environment and try again"
  exit 1
fi

source="${WORKSPACE}/web-ui/build"
dest="${WORKSPACE}/scala-server/public"

mkdir -p ${dest}/static/

# Remove previous versions of the javascript files.
rm -f ${dest}/static/*

# Remove index.html and other files copied from the UI build.
for f in ${dest}/* ; do
  if [ -f $f ] ; then rm $f ; fi
done

# Copy the latest build.
cp -a ${source}/* ${dest}

