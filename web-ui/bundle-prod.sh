#!/bin/sh

#
# Build a bundle independent of server.
#
# webpack --config webpack-client.config.js

mkdir -p dist/
npm run bundle-prod


