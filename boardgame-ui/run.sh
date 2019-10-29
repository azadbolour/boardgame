#!/bin/sh

# Run the production build from the local build folder by using node server.

NPM_DIR=`npm config get prefix`
${NPM_DIR}/bin/serve -s build

