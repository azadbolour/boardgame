#!/bin/sh -x

# IMPORTANT. TODO.  UI content will be dealt with independently of servers.
# Hence no need to build here. TODO. Replace calls to this script by calls to
# prepare.sh.
#
# Sanity check the environment and the source tree.
#
. ../prepare.sh

#
# Update web-ui node js dependencies and bundle the ui code.
#
(cd ${WORKSPACE}/web-ui \
  && npm install \
  && ./build.sh)

