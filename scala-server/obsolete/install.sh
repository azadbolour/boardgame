#!/bin/sh -x

#
# Install the play executable to the dist directory.
#
# For simplicity, the location of the packaged application is hard-coded to target/universal, 
# where sbt dist puts the package.
#
#

#
# Get default values. Specifically DEFAULT_VERSION, DEFAULT_PID_FILE, INSTALL_DIR, BOARDGAME_SERVER.
#
. defaults.sh

# For simplicity use defaults.
PID_FILE=$DEFAULT_PID_FILE
VERSION=$DEFAULT_VERSION
# The generic (constant) root directory of the installed application.
# It is symbolically linked to the versioned installation of the application.
SERVER=$BOARDGAME_SERVER
VERSIONED_SERVER="scala-server-${VERSION}"
INSTALL_DIR=$DEFAULT_INSTALL_DIR

# The package is installed in ${INSTALL_DIR}/${SERVER}-${VERSION}, where VERSION is
# the version of the application as defined in build.sbt.

mkdir -p $INSTALL_DIR
test -d $INSTALL_DIR || (echo "could not create INSTALL_DIR $INSTALL_DIR"; exit 1)

#
# Create the directory for the play pid file.
#
pidDir=`dirname $PID_FILE`
sudo mkdir -p $pidDir
sudo chown $USER $pidDir
test -d $pidDir || (echo "unable to create play pid file directory $pidDir"; exit 1)

projectDir=`pwd`
packageDir=${projectDir}/target/universal

#
# The real copies the dictionary files are in the "dict" directory of the 
# boardgame project. (That is in "../dict" relative to the scala-server directory
# where we are.) The real copies are shared by different server projects
# by using symbolic links. Thus, in the "scala-server/dict" directory, there
# are symbolic links to the real copies of teh dictionary files.
#
# Unzip the real copy of the masked words dictionary file in the top-level
# dict directory.
#
cd ${projectDir}/../dict
maskedWordsFile=moby-english-masked-words.txt
if [ ! -e ${maskedWordsFile} ]; then 
  echo "unzipping masked words file"
  unzip ${maskedWordsFile}.zip
fi

cd ${projectDir}


echo "installing board game from ${packageDir} to ${INSTALL_DIR}"
cd $INSTALL_DIR
rm -rf ${VERSIONED_SERVER}/
rm -f ${SERVER}
unzip $packageDir/${VERSIONED_SERVER}.zip

# 
# Set up a well-known link so scripts become independent of the version.
#
ln -s ${VERSIONED_SERVER} ${SERVER} 

cd ${SERVER}

#
# Copy the dictionary file links from the project to the installation area.
#
mkdir dict
cp ${projectDir}/dict/en-words.txt dict
cp ${projectDir}/dict/en-masked-words.txt dict

echo "installation completed"

