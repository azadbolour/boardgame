#!/bin/sh -x

#
# Sanity check the environment and the source tree.
#
. ../prepare.sh

#
# Update web-ui node js dependencies and bundle the ui code.
#
(cd ${WORKSPACE}/web-ui \
  && npm install \
  && ./bundle-prod.sh)

