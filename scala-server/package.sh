#!/bin/sh -x

#
# Package a play application and copy it and the scripts used to install
# and run it to a well-known 'package' directory. The name of the package 
# directory is provided by the variable DEFAULT_PACKAGE_DIR defined in 
# 'defaults.sh'.
#
# The contents of the package directory then constitute the distribution package 
# for the Scala boardgame application.
#
# This script can be run in a docker container for packaging the application.
# In that case, the well-known directory should be volume-mapped to the host
# file system so that it can be used or distributed from the host.
#
# This script is run from the scala-server directory.

#
# import DEFAULT_PACKAGE_DIR
#
. ./defaults.sh

#
# Build the ui bundle and make sure resources are available in their required forms.
#
../pre-build.sh

#
# Copy over the ui bundle to the so it can be packaged with the play application.
# 
./update-ui-bundle.sh

#
# Build and package the play application.
#
sbt <<EOF
project scalautil
clean 
compile 
test 
project plane
clean 
compile 
test 
project boardgamecommon
clean 
compile 
test 
project scala-server
clean 
compile 
test 
dist
exit
EOF

#
# Copy the bundle to the default package directory.
#
# When building in a docker container, this well-known would be mapped to 
# the host file system so it can be accessed from the host and distributed 
# and used from there.
#
PACKAGE_DIR=$DEFAULT_PACKAGE_DIR
sudo mkdir -p $PACKAGE_DIR
sudo chmod 777 $PACKAGE_DIR
cp -a target/universal/*.zip $PACKAGE_DIR

# 
# Copy the installation and startup scripts to the default package directory.
#
SCRIPT_DIR=$PACKAGE_DIR/script
mkdir -p $SCRIPT_DIR
cp -a install.sh run-server.sh get-dynamic-params.sh defaults.sh $SCRIPT_DIR

sudo chmod -R 777 $PACKAGE_DIR

