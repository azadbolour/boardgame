#!/bin/sh -x

#
# Locally deploy the play executable to the dist directory.
#
# Prerequisites. Distribution package built in target/universal folder. See package.sh.
#
# The distribution is deployed to dist/scala-server-1.0
#

#
# Get default values; we are only interested in DEFAULT_VERSION, and DEFAULT_PID_FILE.
#
. defaults.sh

# For now just use defaults for deploy.
PID_FILE=$DEFAULT_PID_FILE
VERSION=$DEFAULT_VERSION

# TODO. Input parameter for deployDir.
deployDir=dist
mkdir -p $deployDir
test -d $deployDir || (echo "could not create deployDir $deployDir"; exit 1)

#
# Create the directory for the play pid file.
#
pidDir=`dirname $PID_FILE`
sudo mkdir -p $pidDir
sudo chown $USER $pidDir
test -d $pidDir || (echo "unable to create play pid file directory $pidDir"; exit 1)

projectDir=`pwd`
outDir=${projectDir}/target/universal

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

server="scala-server-${VERSION}"

echo "deploying board game scala server from ${outDir} to ${deployDir}"
cd $deployDir
rm -rf ${server}/
unzip $outDir/${server}.zip

cd ${server}

#
# Copy the dictionary file links from the project to the deployment area.
#
mkdir dict
cp ${projectDir}/dict/en-words.txt dict
cp ${projectDir}/dict/en-masked-words.txt dict

echo "deployed"
echo "server dictionary directory"
ls -lt ${projectDir}/${deployDir}/${server}/dict

