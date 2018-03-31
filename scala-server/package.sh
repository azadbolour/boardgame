#!/bin/sh

#
# Package the play application.
#
# The package will be placed in target/universal/scala-server-<version>.zip
# Where 'version' is defined in build.sbt.
#

#
# Update web-ui node js dependencies and bundle the ui code.
#
(cd ../web-ui \
  && npm install \
  && ./bundle-prod.sh)

#
# Copy over the ui bundle to the so it can be packaged with the play application.
# 
./update-ui-bundle.sh 

#
# Make sure resources are available in their required forms.
#
./pre-build.sh

#
# Build and package the play application.
#
sbt clean compile "test" dist

