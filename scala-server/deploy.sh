#!/bin/sh

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

# TODO. Get version from build.sbt.
version=0.9.0
server=scala-server-${version}

echo "deploying board game scala server from ${outDir} to ${deployDir}"
mkdir -p $deployDir
cd $deployDir
rm -rf ${server}/
unzip $outDir/${server}.zip
cd ${server}
mkdir dict
cp ${projectDir}/dict/en-words.txt dict/en-words.txt

echo "deployed"
