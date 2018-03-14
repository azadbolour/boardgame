#!/bin/sh -x

#
# Locally deploy the play executable to the dist directory.
#
# Prerequisites. Distribution package built in target/universal folder. See package.sh.
#
# The distribution is deployed to dist/scala-server-1.0
#

# TODO. Input parameter for deployDir.
deployDir=dist
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

# TODO. Get version from build.sbt.
version=0.9.1
server=scala-server-${version}

echo "deploying board game scala server from ${outDir} to ${deployDir}"
mkdir -p $deployDir
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

