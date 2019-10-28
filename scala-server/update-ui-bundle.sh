#!/bin/sh -x 

# Copy UI resources from the web-ui distribution directory
# to scala-server public directory to make them available as Play assets.

if [ -z "${WORKSPACE}" ]; then
  echo "WORKSPACE not set - aborting - set the environment and try again"
  exit 1
fi

source="${WORKSPACE}/web-ui/dist"
dest="${WORKSPACE}/scala-server/public"

mkdir -p ${dest}/static/

# Remove previous versions of the javascript files.
rm -f ${dest}/static/*

# Remove other files copied from the UI build.
-rm ${dest}/*

# Copy the latest build.
cp -a ${source}/* ${dest}

